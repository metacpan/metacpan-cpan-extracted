package Repl::Core::CompositeContext;

use strict;
use warnings;

sub new
{
    my ($invocant, $main, $backing) = @_;
    my $class = ref($invocant) || $invocant;
    
    # Initialize the token instance.
    my $self = {};
    $self->{MAIN} = $main;
    $self->{BACKING} = $backing;
    return bless($self, $class);
}

sub getBinding
{
    my ($self, $name) = @_;    
    return $self->{MAIN}->getBinding($name) if($self->{MAIN}->isBound($name));
    return $self->{BACKING}->getBinding($name);
}

sub setBinding
{
    my ($self, $name, $value) = @_;
    my $main = $self->{MAIN};
    my $backing = $self->{BACKING};
    
    if($main->isBound($name))
    {
        $main->setBinding($name, $value);
    }
    elsif($backing->isBound($name))
    {
        $backing->setBinding($name, $value);
    }
    else
    {
        die sprintf("ERROR: There is no binding for '%s' in the context.", $name);
    }    
}

sub defBinding
{
    my ($self, $name, $value) = @_;
    my $main = $self->{MAIN};    
    $main->defBinding($name, $value);
}

sub isBound
{
    my ($self, $name) = @_;
    return $self->{MAIN}->isBound($name) || $self->{BACKING}->isBound($name);  
}

sub removeBinding
{
    my ($self, $name) = @_;
    $self->{MAIN}->removeBinding($name) if($self->{MAIN}->isBound($name));
}

sub getRootContext
{
    my $self = shift;
    return $self->{BACKING}->getRootContext();    
}

1;
