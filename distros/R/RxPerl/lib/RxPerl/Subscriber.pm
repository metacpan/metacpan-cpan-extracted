package RxPerl::Subscriber;
use strict;
use warnings;

our $VERSION = "v6.22.1";

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

sub subscription { $_[0]->{_subscription} }

1;
