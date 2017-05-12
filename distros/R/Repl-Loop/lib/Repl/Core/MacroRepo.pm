package Repl::Core::MacroRepo;

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

sub registerMacro
{
    my ($self, $name, $command) = @_;
    if(!$command || !($command->can("transform")))
    {
        confess "A macro needs to have an transform method.";
    }
    $self->{REPO}->{$name=>$command};
}

sub hasMacro
{
    my ($self, $name) = @_;
    return exists $self->{REPO}->{$name};
}

sub getMacro
{
    my ($self, $name) = @_;
    return $self->{REPO}->{$name};
}

1;
