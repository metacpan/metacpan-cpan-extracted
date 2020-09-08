package RxPerl::Subscriber;
use strict;
use warnings;

sub next {
    my $self = shift;

    $self->{next}->(splice @_, 0, 1) if defined $self->{next};
}

sub error {
    my $self = shift;

    $self->{error}->(splice @_, 0, 1) if defined $self->{error};
}

sub complete {
    my $self = shift;

    $self->{complete}->() if defined $self->{complete};
}

1;
