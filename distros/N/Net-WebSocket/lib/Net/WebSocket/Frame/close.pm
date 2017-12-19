package Net::WebSocket::Frame::close;

=encoding utf-8

=head1 NAME

Net::WebSocket::Frame::close

=head1 SYNOPSIS

    my $frm = Net::WebSocket::Frame::close->new(

        #Optional, can be either empty (default) or four random bytes
        mask => q<>,

        code => 'SUCCESS',      #See below

        reason => 'yeah, baby', #See below
    );

    $frm->get_type();           #"close"

    $frm->is_control_frame();   #1

    my $mask = $frm->get_mask_bytes();

    my ($code, $reason) = $frm->get_code_and_reason();

    #If, for some reason, you need the raw payload:
    my $payload = $frm->get_payload();

    my $serialized = $frm->to_bytes();

Note that, L<as per RFC 6455|https://tools.ietf.org/html/rfc6455#section-5.5>,
close messages can have any of:

=over

=item * no code, and no reason

Returned as undef (for the code) and an empty string. This diverges
from the RFC’s described behavior of returning code 1005.

=item * a code, and no reason

Returned as the code number and an empty string.

=item * a code, and a reason that cannot exceed 123 bytes

=back

The code (i.e., C<$code>) is subject to
L<the limitations that RFC 6445 describes|https://tools.ietf.org/html/rfc6455#section-7.4>.
You can also, in lieu of a numeric constant, use the following string
constants that derive from L<Microsoft’s WebSocket API|https://msdn.microsoft.com/en-us/library/windows/desktop/hh449350(v=vs.85).aspx>:

=over

=item * C<SUCCESS> (1000)

=item * C<ENDPOINT_UNAVAILABLE> (1001)

=item * C<PROTOCOL_ERROR> (1002)

=item * C<INVALID_DATA_TYPE> (1003)

=item * C<INVALID_PAYLOAD> (1007)

=item * C<POLICY_VIOLATION> (1008)

=item * C<MESSAGE_TOO_BIG> (1009)

=item * C<UNSUPPORTED_EXTENSIONS> (1010)

=item * C<INTERNAL_ERROR>, aka C<SERVER_ERROR> (1011)

This appears as C<SERVER_ERROR> in Microsoft’s documentation; however,
L<erratum 3227|https://www.rfc-editor.org/errata_search.php?rfc=6455> updates
the RFC to have this status encompass client errors as well.

Net::WebSocket recognizes either string, but its parsing logic will return
only C<INTERNAL_ERROR>.

=back

The following additional status constants derive from
L<the official registry of status codes|http://www.iana.org/assignments/websocket/websocket.xhtml#close-code-number>
and are newer than either RFC 6455 or Microsoft’s API:

=over

=item * C<SERVICE_RESTART> (1012)

=item * C<TRY_AGAIN_LATER> (1013)

=item * C<BAD_GATEWAY> (1014)

=back

It is hoped that a future update to the WebSocket specification
can include these or similar constant names.

=cut

use strict;
use warnings;

use parent qw(
    Net::WebSocket::Base::ControlFrame
);

use Call::Context ();

use Net::WebSocket::Constants ();
use Net::WebSocket::X ();

use constant get_opcode => 8;

sub new {
    my ($class, %opts) = @_;

    if (!$opts{'payload_sr'} && !defined $opts{'payload'}) {
        my $payload;

        if (my $code = delete $opts{'code'}) {
            my $num = Net::WebSocket::Constants::status_name_to_code($code);
            if (!$num) {
                $num = $code;

                if ($num !~ m<\A[0-9]{4}\z> ) {
                    die Net::WebSocket::X->create('BadArg', 'code', $num, 'Invalid WebSocket status code');
                }

                if ( !Net::WebSocket::Constants::status_code_to_name($num) ) {
                    if ( $num < 4000 || $num > 4999 ) {
                        die Net::WebSocket::X->create('BadArg', 'code', $num, 'Disallowed WebSocket status code');
                    }
                }
            }

            $payload = pack 'n', $num;

            my $reason = delete $opts{'reason'};
            if (defined $reason) {
                if (length $reason > 123) {
                    die Net::WebSocket::X->create('BadArg', 'reason', $reason, 'Reason cannot exceed 123 bytes!');
                }

                $payload .= $reason;
            }
        }
        else {
            $payload = q<>;
        }

        $opts{'payload'} = $payload;
    }

    return $class->SUPER::new( %opts );
}

sub get_code_and_reason {
    my ($self) = @_;

    Call::Context::must_be_list();

    #This shouldn’t happen … maybe leftover from previous architecture?
    if ($self->get_type() ne 'close') {
        my $type = $self->get_type();
        die "Frame type is “$type”, not “close” as expected!";
    }

    if (!length ${ $self->[$self->PAYLOAD] }) {
        return ( undef, q<> );
    }

    return unpack 'na*', $self->get_payload();
}

1;
