use strict;
use warnings;

use Test::More;
require Test::CheckChanges;

$Test::CheckChanges::test = bless {}, 'Dummy';
our $x = $Test::CheckChanges::test;

our @q = (
  qr/No way to determine version/,
);

our $count = 0;


eval 'use Module::Build;';
if ($@) {
    plan skip_all => 'Module Build needed for this test.';
}

open(IN, '>t/bad/test1b/_build/build_params');
close(IN);
chmod(0, 't/bad/test1b/_build/build_params');

{
    package Dummy;
    sub done_testing {
	print "1.." . (@q + 1) . "\n";
    };
    sub ok {
	shift;
	if (my $x = shift) {
	    print "not ok 1 @_\n";
	} else {
	    print "ok 1 @_\n";
	}
    }; 
    sub diag {
	shift;
	my $x = shift;
	if ($x =~ $q[$count]) {
	    print sprintf("ok %s - $x\n", ++$count+1);;
        } else {
	    print sprintf("not ok %s - $x\n", ++$count+1);;
	}
    }; 
    sub has_plan { undef; };
}

use File::Basename;

our $name = basename($0, qw(.t));
Test::CheckChanges::ok_changes(
    base => File::Spec->catdir('t', 'bad', $name),
);

while ($count < @q) {
    print sprintf("not ok %s\n", ++$count+1);;
}

__END__

This test check tests the code when the _build data exists, but is not readable.

