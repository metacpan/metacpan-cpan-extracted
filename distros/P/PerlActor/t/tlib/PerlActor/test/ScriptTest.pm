package PerlActor::test::ScriptTest;

use base 'PerlActor::test::TestCase';
use strict;
use PerlActor::Script;
#===============================================================================================
# Public Methods
#===============================================================================================

sub set_up
{
	my $self = shift;
	
	$self->{context} = {};

	$self->_resetFlags();
	$self->_resetCounters();
		
	$self->{script} = new PerlActor::Script('test_script');
	$self->{script}->setListener($self);
	$self->{script}->setContext($self->{context});	
}

sub test_parse
{
	my $self = shift;
	$self->{script}->setLines('Dummy 1', 'Dummy 2', 'Wibble');
	
	my @commands = $self->{script}->parse();
	
	$self->assert_equals(3, scalar @commands);

	$self->assert(ref $commands[0] eq 'PerlActor::Command::Dummy');
	$self->assert_equals(1, $commands[0]->getParam(0));

	$self->assert(ref $commands[1] eq 'PerlActor::Command::Dummy');
	$self->assert_equals(2, $commands[1]->getParam(0));

	$self->assert(ref $commands[2] eq 'PerlActor::Command::Unknown');
}

sub test_execute_empty_script
{
	my $self = shift;
	$self->assert_str_equals('test_script', $self->{script}->getName());
		
	$self->{script}->execute();
	$self->assert($self->{scriptStartedCalled});
	$self->assert($self->{scriptEndedCalled});
	$self->assert_equals(0, $self->{commandsStarted});
	$self->assert_equals(0, $self->{commandsEnded});
	$self->assert_equals(0, $self->{commandsAborted});
}

sub test_execute_script_with_single_simple_command
{
	my $self = shift;
	
	$self->{script}->setLines('Dummy');
	
	$self->{script}->execute();
	$self->assert_equals(1, $self->{commandsStarted});
	$self->assert_equals(1, $self->{commandsEnded});
	$self->assert_equals(0, $self->{commandsAborted});
	$self->assert(exists $self->{context}->{dummy_was_here});
	
}

sub test_execute_script_with_broken_command
{
	my $self = shift;
	
	$self->{script}->setLines("Broken");
	
	$self->{script}->execute();
	$self->assert_equals(1, $self->{commandsStarted});
	$self->assert_equals(0, $self->{commandsEnded});
	$self->assert_equals(1, $self->{commandsAborted});
}

sub test_execute_multi_line_script
{
	my $self = shift;
	
	$self->{script}->setLines('Dummy','Dummy','Dummy');
	
	$self->{script}->execute();
	$self->assert($self->{scriptPassedCalled});
	$self->assert_equals(3, $self->{commandsStarted});
	$self->assert_equals(3, $self->{commandsEnded});
	$self->assert_equals(3, $self->{commandsPassed});
	$self->assert_equals(0, $self->{commandsAborted});
	$self->assert(exists $self->{context}->{dummy_was_here});
	
}

sub test_execute_script_with_broken_command_aborts_script
{
	my $self = shift;
	
	$self->{script}->setLines('Dummy','Broken','Dummy');
	
	$self->{script}->execute();
	$self->assert($self->{scriptStartedCalled});
	$self->assert(! $self->{scriptEndedCalled});
	$self->assert($self->{scriptAbortedCalled});
	$self->assert(! $self->{scriptPassedCalled});
	$self->assert_equals(2, $self->{commandsStarted});
	$self->assert_equals(1, $self->{commandsEnded});
	$self->assert_equals(1, $self->{commandsPassed});
	$self->assert_equals(0, $self->{commandsFailed});
	$self->assert_equals(1, $self->{commandsAborted});
	$self->assert(exists $self->{context}->{dummy_was_here});
	
}

sub test_execute_script_with_failed_command_fails_script
{
	my $self = shift;
	
	$self->{script}->setLines('Dummy','BornToFail','Dummy');
	
	$self->{script}->execute();
	$self->assert($self->{scriptStartedCalled});
	$self->assert($self->{scriptEndedCalled});
	$self->assert($self->{scriptFailedCalled});
	$self->assert(! $self->{scriptAbortedCalled});
	$self->assert_equals(2, $self->{commandsStarted});
	$self->assert_equals(2, $self->{commandsEnded});
	$self->assert_equals(1, $self->{commandsFailed});
	$self->assert_equals(1, $self->{commandsPassed});
	$self->assert_equals(0, $self->{commandsAborted});
	$self->assert(exists $self->{context}->{dummy_was_here});
	
}

#===============================================================================================
# Self Shunt Methods
#===============================================================================================

sub scriptStarted
{
	my $self = shift;
	$self->{scriptStartedCalled} = 1;
}

sub scriptEnded
{
	my $self = shift;
	$self->{scriptEndedCalled} = 1;
}

sub scriptAborted
{
	my $self = shift;
	$self->{scriptAbortedCalled} = 1;
}

sub scriptPassed
{
	my $self = shift;
	$self->{scriptPassedCalled} = 1;
}

sub scriptFailed
{
	my $self = shift;
	$self->{scriptFailedCalled} = 1;
}

sub commandStarted
{
	my $self = shift;
	$self->{commandsStarted}++;
}

sub commandEnded
{
	my $self = shift;
	$self->{commandsEnded}++;
}

sub commandAborted
{
	my $self = shift;
	$self->{commandsAborted}++;
}

sub commandPassed
{
	my $self = shift;
	$self->{commandsPassed}++;
}

sub commandFailed
{
	my $self = shift;
	$self->{commandsFailed}++;
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

sub _resetFlags
{
	my $self = shift;
	$self->{scriptStartedCalled} = undef;
	$self->{scriptEndedCalled}   = undef;
	$self->{scriptAbortedCalled} = undef;
	$self->{scriptPassedCalled}  = undef;
	$self->{scriptFailedCalled}  = undef;	
}

sub _resetCounters
{
	my $self = shift;
	$self->{commandsStarted} = 0;
	$self->{commandsEnded}   = 0;
	$self->{commandsPassed}  = 0;
	$self->{commandsFailed}  = 0;
	$self->{commandsAborted} = 0;
}

# Keep Perl happy.
1;
