#!/usr/local/bin/perl -w

# We want to use the development version of T::A::TestScript
use File::Spec::Functions qw( :ALL );
BEGIN {
	if ($0) {
		my ($vol, $dir, $file) = splitpath(rel2abs($0));
		my @parent_dir = splitdir(canonpath($dir));
		pop @parent_dir;
		my $lib_dir = catpath($vol, catdir(@parent_dir,'lib'), '');
		unshift @INC, $lib_dir;
	} else {
		die "Could not find script location\n";
	}
}

use vars qw($opt_b);
use Test::Assertions::TestScript(options => {'b', \$opt_b});

ASSERT($Test::Assertions::TestScript::VERSION, "Compiled version $Test::Assertions::TestScript::VERSION");

TRACE("Sample trace message to test -t option");
ASSERT(1, "Correctly generates test output");
TRACE("Command-line -b option set \$opt_b variable", $opt_b);

sub TRACE{}
