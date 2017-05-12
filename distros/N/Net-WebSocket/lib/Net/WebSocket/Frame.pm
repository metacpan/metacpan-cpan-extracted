package Net::WebSocket::Frame;

=encoding utf-8

=head1 NAME

Net::WebSocket::Frame

=head1 SYNOPSIS

    #Never instantiate Net::WebSocket::Frame directly;
    #always call new() on a subclass:
    my $frame = Net::WebSocket::Frame::text->new(
        fin => 0,                   #to start a fragmented message
        rsv => 0b11,                #RSV2 and RSV3 are on
        mask => "\x01\x02\x03\x04   #clients MUST include; servers MUST NOT
        payload_sr => \'Woot!',
    );

    $frame->get_fin();
    $frame->get_mask_bytes();
    $frame->get_payload();

    $frame->set_rsv();
    $frame->get_rsv();

    $frame->to_bytes();     #for sending over the wire

=head1 DESCRIPTION

This is the base class for all frame objects. The interface as described
above should be fairly straightforward.

=head1 EXPERIMENTAL: CUSTOM FRAME CLASSES

You can have custom frame classes, e.g., to support WebSocket extensions that
use custom frame opcodes. RFC 6455 allocates opcodes 3-7 for data frames and
11-15 (0xb - 0xf) for control frames.

The best way to do this is to subclass either
L<Net::WebSocket::Base::DataFrame> or L<Net::WebSocket::Base::ControlFrame>,
depending on what kind of frame you’re dealing with.

An example of such a class is below:

    package My::Custom::Frame::booya;

    use strict;
    use warnings;

    use parent qw( Net::WebSocket::Base::DataFrame );

    use constant get_opcode => 3;

    use constant get_type => 'booya';

Note that L<Net::WebSocket::Parser> still won’t know how to handle such a
custom frame, so if you intend to receive custom frames as part of messages,
you’ll also need to create a custom base class of this class, then also
subclass L<Net::WebSocket::Parser>. You may additionally want to subclass
L<Net::WebSocket::Streamer::Server> (or -C<::Client>) if you do streaming.

B<NOTE: THIS IS LARGELY UNTESTED.> I’m not familiar with any application that
actually requires this feature. The C<permessage-deflate> extension seems to
be the only one that has much widespread web browser support.

=cut

use strict;
use warnings;

use Net::WebSocket::Constants ();
use Net::WebSocket::Mask ();
use Net::WebSocket::X ();

use constant {
    FIRST2 => 0,
    LEN_LEN => 1,
    MASK => 2,
    PAYLOAD => 3,
};

#fin, rsv, mask, payload_sr
#rsv is a bitmask of the three values, with RSV1 as MOST significant bit.
#So, represent RSV1 and RSV2 being on via 0b110 (= 4 + 2 = 6)
sub new {
    my ($class, %opts) = @_;

    my ( $fin, $rsv, $mask, $payload_sr ) = @opts{ qw( fin rsv mask payload_sr ) };

    my $type = $class->get_type();

    my $opcode = $class->get_opcode($type);

    if (!defined $fin) {
        $fin = 1;
    }

    $payload_sr ||= \do { my $v = q<> };

    if (defined $mask) {
        _validate_mask($mask);

        if (length $mask) {
            Net::WebSocket::Mask::apply($payload_sr, $mask);
        }
    }
    else {
        $mask = q<>;
    }

    my $first2 = chr $opcode;
    $first2 |= "\x80" if $fin;

    if ($rsv) {
        die "RSV must be < 0-7!" if $rsv > 7;
        $first2 |= chr( $rsv << 4 );
    }

    my ($byte2, $len_len) = $class->_assemble_length($payload_sr);

    $byte2 |= "\x80" if $mask;

    substr( $first2, 1, 0, $byte2 );

    return bless [ \$first2, \$len_len, \$mask, $payload_sr ], $class;
}

# All string refs: first2, length octets, mask octets, payload
sub create_from_parse {
    return bless \@_, shift;
}

sub get_mask_bytes {
    my ($self) = @_;

    return ${ $self->[MASK] };
}

#To collect the goods
sub get_payload {
    my ($self) = @_;

    my $pl = "" . ${ $self->[PAYLOAD] };

    if (my $mask = $self->get_mask_bytes()) {
        Net::WebSocket::Mask::apply( \$pl, $mask );
    }

    return $pl;
}

#For sending over the wire
sub to_bytes {
    my ($self) = @_;

    return join( q<>, map { $$_ } @$self );
}

sub get_rsv {
    my ($self) = @_;

    #0b01110000 = 0x70
    return( ord( substr( ${ $self->[FIRST2] }, 0, 1 ) & "\x70" ) >> 4 );
}

sub set_rsv {
    my ($self, $rsv) = @_;

    ${ $self->[FIRST2] } |= chr( $rsv << 4 );

    return $self;
}

#----------------------------------------------------------------------
#Redundancies with methods in DataFrame.pm and ControlFrame.pm.
#These are here so that we don’t have to re-bless in order to get this
#information.

sub is_control_frame {
    my ($self) = @_;

    #8 == 0b1000 == 010
    return( ($self->_extract_opcode() & 8) ? 1 : 0 );
}

sub get_fin {
    my ($self) = @_;

    return( ord ("\x80" & ${$self->[$self->FIRST2]}) && 1 );
}

#----------------------------------------------------------------------

#sub get_opcode {
#    my ($class) = @_;
#
#    die "$class (type “$type”) must define a custom get_opcode() method!";
#}

#----------------------------------------------------------------------

#Unneeded?
#sub set_mask_bytes {
#    my ($self, $bytes) = @_;
#
#    if (!defined $bytes) {
#        die "Set either a 4-byte mask, or empty string!";
#    }
#
#    if (length $bytes) {
#        _validate_mask($bytes);
#
#        $self->_activate_highest_bit( $self->[FIRST2], 1 );
#    }
#    else {
#        $self->_deactivate_highest_bit( $self->[FIRST2], 1 );
#    }
#
#    if (${ $self->[MASK] }) {
#        Net::WebSocket::Mask::apply( $self->[PAYLOAD], ${ $self->[MASK] } );
#    }
#
#    $self->[MASK] = \$bytes;
#
#    if ($bytes) {
#        Net::WebSocket::Mask::apply( $self->[PAYLOAD], $bytes );
#    }
#
#    return $self;
#}

#----------------------------------------------------------------------

sub opcode_to_type {
    my ($class, $opcode) = @_;
    return Net::WebSocket::Constants::opcode_to_type($opcode);
}

our $AUTOLOAD;
sub AUTOLOAD {
    my ($self) = shift;

    return if substr( $AUTOLOAD, -8 ) eq ':DESTROY';

    my $last_colon_idx = rindex( $AUTOLOAD, ':' );
    my $method = substr( $AUTOLOAD, 1 + $last_colon_idx );

    #Figure out what type this is, and re-bless.
    if (ref($self) eq __PACKAGE__) {
        my $opcode = $self->_extract_opcode();
        my $type = $self->opcode_to_type($opcode);

        my $class = __PACKAGE__ . "::$type";
        if (!$class->can('new')) {
            Module::Load::load($class);
        }

        bless $self, $class;

        if ($self->can($method)) {
            return $self->$method(@_);
        }
    }

    my $class = (ref $self) || $self;

    die( "$class has no method “$method”!" );
}

#----------------------------------------------------------------------

sub _extract_opcode {
    my ($self) = @_;

    return 0xf & ord substr( ${ $self->[FIRST2] }, 0, 1 );
}

sub _validate_mask {
    my ($bytes) = @_;

    if (length $bytes) {
        if (4 != length $bytes) {
            my $len = length $bytes;
            die "Mask must be 4 bytes long, not $len ($bytes)!";
        }
    }

    return;
}

sub _activate_highest_bit {
    my ($self, $sr, $offset) = @_;

    substr( $$sr, $offset, 1 ) = chr( 0x80 | ord substr( $$sr, $offset, 1 ) );

    return;
}

sub _deactivate_highest_bit {
    my ($sr, $offset) = @_;

    substr( $$sr, $offset, 1 ) = chr( 0x7f & ord substr( $$sr, $offset, 1 ) );

    return;
}

1;
