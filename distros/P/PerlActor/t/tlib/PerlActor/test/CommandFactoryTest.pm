package PerlActor::test::CommandFactoryTest;

use base 'PerlActor::test::TestCase';
use fields qw( factory );
use strict;
use Error qw( :try );
use PerlActor::CommandFactory;

#===============================================================================================
# Public Methods
#===============================================================================================

sub set_up
{
	my $self = shift;
	$self->{factory} = new PerlActor::CommandFactory();
}

sub test_create_with_no_arguments_returns_null_command
{
	my $self = shift;
	my $command = $self->{factory}->create();
	$self->assert(ref $command eq 'PerlActor::Command::Null');
}

sub test_create_with_non_existent_command_name_returns_unknown_command
{
	my $self = shift;
	my $command = $self->{factory}->create('ThisCommandDoesNotExist');
	$self->assert(ref $command eq 'PerlActor::Command::Unknown');
}

sub test_create_with_existing_command_name_returns_correct_command
{
	my $self = shift;
	my $command = $self->{factory}->create('Dummy');
	$self->assert(ref $command eq 'PerlActor::Command::Dummy');
}

sub test_create_command_with_params
{
	my $self = shift;
	my $command = $self->{factory}->create('Dummy',1,2,3,'four');
	$self->assert(ref $command eq 'PerlActor::Command::Dummy');
	$self->assert_equals(1, $command->getParam(0));
	$self->assert_equals(2, $command->getParam(1));
	$self->assert_equals(3, $command->getParam(2));
	$self->assert_str_equals('four', $command->getParam(3));
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

# Keep Perl happy.
1;
