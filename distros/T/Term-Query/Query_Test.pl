# Query_Test.pl
# $Id$
# Author: Alan K. Stebbens <aks@sgi.com>

use Term::Query qw( query );
use Tester;

# General a test on query with input, and check against the expected
# response.
#
# This is used in the class tests.

sub query_test {
    my $class = shift;
    my $test = shift;
    my $inputstring = shift;
    my $qargs = shift;
    my $condition = shift;
    local $_;

    Tester::run_test_with_input $class, $test, $inputstring,
	sub {
	    $_ = query @_;
	    exit if /^\s*(exit|quit|abort)\s*$/;
	    printf "Answer = \"%s\"\n",(length($_) ? $_ : 
				defined($_) ? 'NULL' : 'undef');
	    }, 
	$qargs, $condition;
}

1;
