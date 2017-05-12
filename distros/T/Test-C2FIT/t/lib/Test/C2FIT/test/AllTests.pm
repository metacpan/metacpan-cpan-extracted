package Test::C2FIT::test::AllTests;
use base 'Test::Unit::TestSuite';

use strict;

my @TESTS =qw(
	ParseTest
	FixtureTest
	TypeAdapterTest
);

#===============================================================================================
# Public Methods
#===============================================================================================

sub suite
{
	my $self = shift;
	my $suite = $self->empty_new("FIT Unit Tests");
	foreach my $test (@TESTS)
	{
		$suite->add_test(Test::Unit::TestSuite->new("Test::C2FIT::test::$test"));
	}
	return $suite;
}

# Keep Perl happy.
1;
