package Net::WebSocket::Base::DataFrame;

use strict;
use warnings;

use parent qw(
    Net::WebSocket::Frame
    Net::WebSocket::Base::Typed
);

use constant is_control_frame => 0;

sub _assemble_length {
    my ($class, $payload_sr) = @_;

    my ($byte2, $len_len);

    if (length $$payload_sr < 126) {
        $byte2 = chr(length $$payload_sr);
        $len_len = q<>;
    }
    elsif (length $$payload_sr < 65536) {
        $byte2 = "\x7e";  #126
        $len_len = pack 'n', length $$payload_sr;
    }
    else {
        $byte2 = "\x7f"; #127
        $len_len = pack 'Q>', length $$payload_sr;
    }

    return ($byte2, $len_len);
}

sub set_fin {
    my ($self) = @_;

    $self->_activate_highest_bit( $self->[$self->FIRST2], 0 );

    return $self;
}

1;
