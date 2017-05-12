package PerlActor::test::AllTests;
use base 'Test::Unit::TestSuite';

use strict;
use File::Find;

my @TESTS; # Global Collector for Tests to Run.

#===============================================================================================
# Public Methods
#===============================================================================================

sub getTestBaseDir { 't/tlib' }
sub getTestPrefix  { 'PerlActor::test' }

sub suite
{
	my $self = shift;
	
	$self->buildTestList();

	my $suite = $self->empty_new("PerlActor Tests");
	foreach my $test (@TESTS)
	{
		$suite->add_test(Test::Unit::TestSuite->new($test));
	}
		
	return $suite;
}

sub buildTestList
{	
	my $self = shift;	
	find({ wanted => sub {$self->processFile}, follow => 1 }, $self->getBaseDirForFind());
}

sub processFile
{	
	my $self = shift;	
	my $file = $File::Find::name;

	return unless $self->fileIsAPerlModule($file);

	my $test = $self->extractTestNameFromPath($file);

	return unless $self->validTest($test);
	
	push @TESTS, $test;
	
}

sub getBaseDirForFind
{
	my $self = shift;	
	my $testDir = $self->getTestPrefix();
	$testDir =~ s/::/\//g;
	return $self->getTestBaseDir() . "/$testDir";	
}

sub fileIsAPerlModule
{
	my $self = shift;	
	my $file = shift;
	return $file =~ m/\.pm$/;	
}

sub extractTestNameFromPath
{
	my $self = shift;	
	my $path = shift;
	my $test = $path;
	my $basedir = $self->getTestBaseDir();
	
	$test =~ s/^$basedir\///; # Remove leading dir.
	$test =~ s/\.pm$//;       # Remove extension.
	$test =~ s/\//::/g;       # Convert path separator to package separator.

	return $test;
}

sub validTest
{
	my $self = shift;	
	my $test = shift;
	return 0 if $test =~ /::TestCase$/;
	return 0 if $test =~ /::All/;
	return 0 if $test =~ /Abstract/;
	
	return 1;	
}

# Keep Perl happy.

1;
