package Repl::Core::BasicContext;

use strict;
use warnings;

sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    # Initialize the token instance.
    my $self = {};
    $self->{CTX} = {};
    return bless($self, $class);
}

sub getBinding
{
    my ($self, $name) = @_;
    return $self->{CTX}->{$name};
}

sub setBinding
{
    my ($self, $name, $value) = @_;
    if(exists $self->{CTX}->{$name})
    {
        $self->{CTX}->{$name} = $value
    }
    else
    {
        die sprintf("ERROR: There is no binding for '%s' in the context.", $name);
    }
}

sub defBinding
{
    my ($self, $name, $value) = @_;
    $self->{CTX}->{$name} = $value;    
}

sub isBound
{
    my ($self, $name) = @_;
    return exists $self->{CTX}->{$name};    
}

sub removeBinding
{
    my ($self, $name) = @_;
    delete $self->{CTX}->{$name}; 
}

sub getRootContext
{
    my $self = shift;
    return $self;    
}

1;
