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

=item * a code, and no reason

=item * a code, and a reason that cannot exceed 123 bytes

=back

The code (i.e., C<$code>) is subject to
L<the limitations that RFC 6445 describes|https://tools.ietf.org/html/rfc6455#section-7.4>.
You can also, in lieu of a numeric constant, use the following string
constants that L<Microsoft defines|https://msdn.microsoft.com/en-us/library/windows/desktop/hh449350(v=vs.85).aspx>:

=over

=item * C<SUCCESS> (1000)

=item * C<ENDPOINT_UNAVAILABLE> (1001)

=item * C<PROTOCOL_ERROR> (1002)

=item * C<INVALID_DATA_TYPE> (1003)

=item * C<INVALID_PAYLOAD> (1007)

=item * C<POLICY_VIOLATION> (1008)

=item * C<MESSAGE_TOO_BIG> (1009)

=item * C<UNSUPPORTED_EXTENSIONS> (1010)

=item * C<SERVER_ERROR> (1011)

NOTE: As per L<erratum|https://www.rfc-editor.org/errata_search.php?rfc=6455>
3227, this status is meant to encompass client errors as well. Since these
constants are meant to match Microsoft’s (in default of such in the actual
WebSocket standard), however, Net::WebSocket only recognizes C<SERVER_ERROR>
as an alias of 1011. Hopefully a future update to the WebSocket standard will
include useful string aliases for the status codes.

Also note that L<the official list of status codes|http://www.iana.org/assignments/websocket/websocket.xhtml#close-code-number> contains some that
don’t have string constants.

=back

=cut

use strict;
use warnings;

use parent qw(
    Net::WebSocket::Base::ControlFrame
);

use Call::Context ();

use Net::WebSocket::Constants ();

use constant get_opcode => 8;

sub new {
    my ($class, %opts) = @_;

    if (!$opts{'payload_sr'}) {
        my $payload;

        if ($opts{'code'}) {
            my $num = Net::WebSocket::Constants::status_name_to_code($opts{'code'});
            if (!$num) {
                $num = $opts{'code'};

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

            if (defined $opts{'reason'}) {
                if (length $opts{'reason'} > 123) {
                    die Net::WebSocket::X->create('BadArg', 'reason', $opts{'reason'}, 'Reason cannot exceed 123 bytes!');
                }

                $payload .= $opts{'reason'};
            }
        }
        else {
            $payload = q<>;
        }

        $opts{'payload_sr'} = \$payload;
    }

    return $class->SUPER::new( %opts, type => 'close' );
}

sub get_code_and_reason {
    my ($self) = @_;

    Call::Context::must_be_list();

    #This shouldn’t happen … maybe leftover from previous architecture?
    if ($self->get_type() ne 'close') {
        my $type = $self->get_type();
        die "Frame type is “$type”, not “close” as expected!";
    }

    return if !length ${ $self->[$self->PAYLOAD] };

    return unpack 'na*', $self->get_payload();
}

1;
