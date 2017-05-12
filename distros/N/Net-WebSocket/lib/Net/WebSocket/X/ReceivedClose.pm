package Net::WebSocket::X::ReceivedClose;

use strict;
use warnings;

use parent qw( Net::WebSocket::X::Base );

use Net::WebSocket::Constants ();

sub _new {
    my ($class, $frame) = @_;

    my $txt;
    if ( my @code_reason = $frame->get_code_and_reason() ) {
        my $status_name = Net::WebSocket::Constants::status_code_to_name($code_reason[0]);
        if ($status_name) {
            $code_reason[0] .= "/$status_name";
        }

        pop @code_reason if !length $code_reason[1];

        $txt = "Received close frame: [@code_reason]";
    }
    else {
        $txt = "Received close frame (empty)";
    }

    return $class->SUPER::_new( $txt, frame => $frame );
}

1;
