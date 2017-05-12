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
close messages can either have:

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

=item * SUCCESS (1000)

=item * ENDPOINT_UNAVAILABLE (1001)

=item * PROTOCOL_ERROR (1002)

=item * INVALID_DATA_TYPE (1003)

=item * INVALID_PAYLOAD (1007)

=item * POLICY_VIOLATION (1008)

=item * MESSAGE_TOO_BIG (1009)

=item * UNSUPPORTED_EXTENSIONS (1010)

=item * SERVER_ERROR (1011)

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
                    die "Invalid WebSocket status code: [$num]";
                }

                if ( !Net::WebSocket::Constants::status_code_to_name($num) ) {
                    if ( $num < 4000 || $num > 4999 ) {
                        die "Disallowed WebSocket status code: [$num]";
                    }
                }
            }

            $payload = pack 'n', $num;

            if (defined $opts{'reason'}) {
                if (length $opts{'reason'} > 123) {
                    die "“reason” ($opts{'reason'}) cannot exceed 123 bytes!";
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

    if ($self->get_type() ne 'close') {
        my $type = $self->get_type();
        die "Frame type is “$type”, not “close” as expected!";
    }

    return if !length ${ $self->[$self->PAYLOAD] };

    return unpack 'na*', $self->get_payload();
}

1;
