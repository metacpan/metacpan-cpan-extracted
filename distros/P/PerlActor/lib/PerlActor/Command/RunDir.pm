package PerlActor::Command::RunDir;
use strict;

use base 'PerlActor::Command';

use PerlActor::Exception;
use File::Find;

#===============================================================================================
# Public Methods
#===============================================================================================

sub execute
{
	my $self = shift;	
	my $dir = $self->getParam(0);
	
	throw PerlActor::Exception("cannot collect test scripts: directory '$dir' does not exist!")
		unless -e $dir;
		
	$self->findAndExecuteScriptsIn($dir);
}

sub findAndExecuteScriptsIn
{	
	my ($self, $dir) = @_;	
	find({ wanted => sub {$self->processFile()}, follow => 1, no_chdir => 1 }, $dir);
}

sub processFile
{	
	my $self = shift;	
	my $file = $File::Find::name;
	return unless $self->fileIsAPerlActorTest($file);
	$self->executeScript($file);
}

sub fileIsAPerlActorTest
{
	my ($self, $file) = @_;
	return $file =~ m/\.pact$/;
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

# Keep Perl happy.
1;
