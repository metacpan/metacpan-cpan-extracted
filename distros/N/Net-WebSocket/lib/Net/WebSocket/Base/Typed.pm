package Net::WebSocket::Base::Typed;

use strict;
use warnings;

sub get_type {
    my ($self) = @_;

    my $class = ref($self) || $self;

    my $last_colon = rindex( $class, ':' );
    return substr( $class, 1 + $last_colon );
}

1;
