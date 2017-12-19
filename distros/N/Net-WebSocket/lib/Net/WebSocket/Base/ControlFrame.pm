package Net::WebSocket::Base::ControlFrame;

use strict;
use warnings;

use parent qw(
    Net::WebSocket::Frame
);

use Net::WebSocket::X ();

use constant get_fin => 1;
use constant is_control_frame => 1;

sub _assemble_length {
    my ($class, $payload_sr) = @_;

    if (length $$payload_sr > 125) {
        my $type = $class->get_type();

        die Net::WebSocket::X->create('ControlPayloadTooLong', $type, $$payload_sr);
    }

    return( chr(length $$payload_sr), q<> );
}

sub new {
    my ($class, @opts) = @_;

    return $class->SUPER::new(
        @opts,
        fin => 1,
    );
}

1;
