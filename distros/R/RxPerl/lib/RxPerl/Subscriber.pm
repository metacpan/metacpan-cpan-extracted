package RxPerl::Subscriber;
use strict;
use warnings FATAL => 'all';

sub next {
    my $self = shift;
    # TODO: should @_ be replaced with splice @_, 0, 1?
    $self->{next}->(@_) if defined $self->{next};
}

sub error {
    my $self = shift;
    # TODO: should @_ be replaced with splice @_, 0, 1?
    $self->{error}->(@_) if defined $self->{error};
}

sub complete {
    my $self = shift;
    $self->{complete}->() if defined $self->{complete};
}

1;
