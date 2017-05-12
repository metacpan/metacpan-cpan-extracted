use strict;
use lib qw( lib t/tlib );
use Test::Unit::TestRunner;

my @tests;

if (@ARGV)
{
	@tests = @ARGV;
}
else
{
	@tests = ('PerlActor::test::AllTests');
}

print "\nRunning Tests\n";
print "==============\n";
my $testrunner = Test::Unit::TestRunner->new();

while (my $test = shift @tests)
{
	# Turn possible path into package name
	#$test =~ s/^.*test\///;
	$test =~ s/\.pm$//g;
	$test =~ s/\//::/g;

	$testrunner->start($test);
}
