package Net::HTTP2::RejectorRegistry;

use strict;
use warnings;

sub new {
    return bless {}, shift;
}

sub add {
    my ($self, $rejector) = @_;

    $self->{$rejector} = $rejector;

    return "$rejector";
}

sub remove {
    my ($self, $rejector_str) = @_;

    return delete $self->{$rejector_str};
}

sub count {
    my ($self) = @_;

    return 0 + keys %$self;
}

sub reject_all {
    my ($self, $err) = @_;

    $_->($err) for values %$self;
    %$self = ();

    return $self;
}

1;
