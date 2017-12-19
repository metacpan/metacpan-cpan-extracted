package Net::WebSocket::Base::DataFrame;

use strict;
use warnings;

use parent qw(
    Net::WebSocket::Frame
);

use constant {
    is_control_frame => 0,
    _MAX_32_BIT_LENGTH => 0xffffffff,
};

my $can_pack_Q;
BEGIN {
    $can_pack_Q = eval { pack 'Q', 0 };
}

my $length;

sub _assemble_length {
    my ($class, $payload_sr) = @_;

    my ($byte2, $len_len);

    $length = length $$payload_sr;

    if ($length < 126) {
        $byte2 = chr(length $$payload_sr);
        $len_len = q<>;
    }
    elsif ($length < 65536) {
        $byte2 = "\x7e";  #126
        $len_len = pack 'n', $length;
    }
    else {
        $byte2 = "\x7f"; #127

        #Even without 64-bit support, we can still support
        #anything up to a 32-bit length
        if ($can_pack_Q) {
            $len_len = pack 'Q>', $length;
        }
        elsif ($length <= _MAX_32_BIT_LENGTH) {
            $len_len = (pack 'N', $length) . "\0\0\0\0";
        }
        else {
            die sprintf( "This Perl version (%s) doesn’t support 64-bit integers, which means WebSocket frames must be no larger than %d bytes. You tried to create a %d-byte frame.", $^V, _MAX_32_BIT_LENGTH, $length);
        }
    }

    return ($byte2, $len_len);
}

sub set_fin {
    my ($self) = @_;

    $self->_activate_highest_bit( $self->[$self->FIRST2], 0 );

    return $self;
}

1;
