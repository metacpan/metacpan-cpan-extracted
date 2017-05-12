# Full test:
# - compile t/t.c into an object file into t.o
# - test Parse::nm->run() against t.o

use strict;
use warnings;
use Config;
use File::Spec;
use Test::More;
use Test::NoWarnings;

use Parse::nm;

BEGIN {
    eval {
	require ExtUtils::CBuilder;
    };
    if ($@) {
	plan skip_all => 'ExtUtils::CBuilder not installed';
    } else {
	import ExtUtils::CBuilder;
    }
}

my $src = File::Spec->catfile('t', 't.c');
my $obj = eval {
    ExtUtils::CBuilder->new(quiet => 1)->compile(source => $src);
};
plan skip_all => "Compile '$src' failed" if $@ || !defined $obj || !-f $obj;

END {
    if (defined $obj && -f $obj) {
        diag "Remove '$obj'";
        unlink $obj;
    }
}

my $count = 2;

plan tests => 1+4*$count;

Parse::nm->run(
    files => $obj,
    filters => [
    {
	# MacOS X exports with an '_'
	name => qr/_?TestFunc/,
	type => qr/T/,
	action => sub {
	    pass "action1 called";
	    is $count--, 2;
	    like $_[0], qr/^_?TestFunc$/, "arg0: $_[0]";
	    is $_[1], 'T', 'arg1';
	}
    },
    {
	# MacOS X exports with an '_'
	name => qr/_?TestVar/,
	#type => qr/[A-Z]/,
	action => sub {
	    pass "action2 called";
	    is $count--, 1;
	    like $_[0], qr/^_?TestVar$/, "arg0: $_[0]";
	    # Linux/Alpha  : G
	    # Others       : D
	    like $_[1], qr/^[GD]$/, 'arg1';
	}
    }
]);

fail "Missing output" for 1..(4*$count);
