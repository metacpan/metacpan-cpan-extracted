package Sub::Spy::Result;
use strict;
use warnings;

use List::MoreUtils qw/any/;


sub new {
    my ($class, $param) = @_;
    return bless $param, $class;
}

sub get_call {
    my ($self, $n) = @_;
    $self->{calls}->[$n];
}


# count

sub call_count {
    return scalar @{shift->{calls}};
}

sub called {
    return (shift->call_count > 0) ? 1 : 0;
}

sub called_times {
    my ($self, $times) = @_;
    return ($self->call_count == $times) ? 1 : 0;
}

sub called_once {
    return shift->called_times(1);
}

sub called_twice {
    return shift->called_times(2);
}

sub called_thrice {
    return shift->called_times(3);
}


# args

sub args {
    my $self = shift;
    return [map { $_->args } @{$self->{calls}}];
}

sub get_args {
    my ($self, $n) = @_;
    die "try to get arguments of not-yet-called call." if $n >= scalar @{$self->{calls}};
    return $self->args->[$n];
}


# exception

sub exceptions {
    my $self = shift;
    return [map { $_->exception } @{$self->{calls}}];
}

sub get_exception {
    my ($self, $n) = @_;
    die "try to get exception of not-yet-called call." if $n >= scalar @{$self->{calls}};
    return $self->exceptions->[$n];
}

sub threw {
    my $self = shift;
    return ( any { defined($_) } @{$self->exceptions} ) ? 1 : 0;
}


# return

sub return_values {
    my $self = shift;
    return [map { $_->return_value } @{$self->{calls}}];
}

sub get_return_value {
    my ($self, $n) = @_;
    die "try to get return value of not-yet-called call." if $n >= scalar @{$self->{calls}};
    return $self->return_values->[$n];
}


1;
