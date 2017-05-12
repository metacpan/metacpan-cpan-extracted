package Repl::Core::CommandRepo;

# Pragma's.
use strict;
use warnings;

# Uses.
use Carp;

sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    # Initialize the token instance.
    my $self = {};
    $self->{REPO} = {};
    return bless($self, $class);
}

sub registerCommand
{
    my ($self, $name, $command) = @_;
    if(!$command || !($command->can("execute")))
    {
        confess "A command needs to have an execute method.";
    }
    $self->{REPO}->{$name} = $command;
}

sub hasCommand
{
    my ($self, $name) = @_;
    return exists $self->{REPO}->{$name};
}

sub getCommand
{
    my ($self, $name) = @_;
    return $self->{REPO}->{$name};
}

1;
