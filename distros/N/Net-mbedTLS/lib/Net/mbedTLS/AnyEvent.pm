package Net::mbedTLS::AnyEvent;

use strict;
use warnings;

use AnyEvent;

use parent 'Net::mbedTLS::Async';

sub _set_event_listener {
    my ($self, $is_write, $sub_cb) = @_;

    my $w;

    my $cb = sub {
        undef $w;
        &$sub_cb;
    };

    $w = AE::io( $self->_TLS()->fh(), $is_write, $cb );
}

1;
