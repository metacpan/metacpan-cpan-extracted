
# $Id: test_unit_testcase.t,v 1.1.1.1 2004/11/22 19:16:02 owensc Exp $


use strict;
use Test;
$ENV{MYCO_ROOT} = '.';

BEGIN { plan tests => 1 };

print STDERR
    "Run 'legacy' tests (okay... so, at the moment, that's all of them)\n\n";
open(TESTRUN,"bin/testrun |");
my ($ln, $tot, $fail, $err);
while ( defined(my $tout = <TESTRUN>) ) {
    if ( !$ln ) {
	{
	    local $_ = $tout;
	    ($tot, $fail, $err) =
		/^Run: (\d+) Failures: (\d+) Errors: (\d+)/ and last;
	    ($tot) = /^OK \((\d+) tests\)/ and last;
	}
	$ln = $tout if $tot;
    }
}
close TESTRUN;

ok($tot && !defined $fail, 1, "Test::Unit::TestCase unit test results -- $ln");


