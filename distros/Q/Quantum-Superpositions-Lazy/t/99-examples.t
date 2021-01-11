use v5.28;
use warnings;
use Test::More;
use Test::Exception;
use File::Basename;

##############################################################################
# This test runs every example in the examples directory, but does not assert
# anything else than that the example has not died. Examples should provide
# their own test cases.
##############################################################################

my $examples_path = dirname(dirname(__FILE__)) . "/examples";

for my $example (glob "$examples_path/*.pl") {
	subtest "testing $example" => sub {
		lives_and {
			do $example;
		};
	};
}

done_testing;
