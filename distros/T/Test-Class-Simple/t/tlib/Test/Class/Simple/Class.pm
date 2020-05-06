package Test::Class::Simple::Class;
use strict;
use warnings;

sub new {
    my $class = shift;

    $class = ref($class) || $class;
    my $self = { _counter => 0 };
    bless $self, $class;
    return $self;
}

sub increase_counter {
    my $self = shift;

    $self->{_counter}++;
    return $self->{_counter};
}

sub check_reference {
    my $value = shift;

    return ( ref $value ) ? 1 : 0;
}

1;
