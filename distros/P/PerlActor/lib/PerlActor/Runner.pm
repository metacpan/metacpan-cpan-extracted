package PerlActor::Runner;
use strict;
use base 'PerlActor::Object';

use PerlActor::Script;

#===============================================================================================
# Public Methods
#===============================================================================================

sub run
{
	my $self = shift;
	my $test = shift;
	
	$self->start();
	
	open SCRIPT, "$test"
		or die "cannot open test script file $test: $!\n";
		
	my @lines = <SCRIPT>;
	my $script = new PerlActor::Script("$test");
	$script->setListener($self);
	$script->setLines(@lines);
	$script->execute();			
	close SCRIPT;
	
	$self->end();
	
}

sub start { }

sub end { }

sub scriptStarted { }

sub scriptEnded { }

sub scriptAborted { }

sub scriptPassed { }

sub scriptFailed { }

sub commandStarted { }

sub commandEnded { }

sub commandAborted { }

sub commandFailed { }

sub commandPassed { }

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

# Keep Perl happy.
1;
