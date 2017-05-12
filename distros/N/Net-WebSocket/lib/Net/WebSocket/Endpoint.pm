package Net::WebSocket::Endpoint;

=encoding utf-8

=head1 NAME

Net::WebSocket::Endpoint

=head1 DESCRIPTION

See L<Net::WebSocket::Endpoint::Server>.

=cut

use strict;
use warnings;

use Call::Context ();

use Net::WebSocket::Frame::close ();
use Net::WebSocket::Frame::ping ();
use Net::WebSocket::Frame::pong ();
use Net::WebSocket::Message ();
use Net::WebSocket::PingStore ();
use Net::WebSocket::X ();

use constant DEFAULT_MAX_PINGS => 3;

sub new {
    my ($class, %opts) = @_;

    my @missing = grep { !length $opts{$_} } qw( out parser );

    die "Missing: [@missing]" if @missing;

    if ( !(ref $opts{'out'})->can('write') ) {
        die "“out” ($opts{'out'}) needs a write() method!";
    }

    my $self = {
        _fragments => [],

        _max_pings => $class->DEFAULT_MAX_PINGS(),

        _ping_store => Net::WebSocket::PingStore->new(),

        (map { defined($opts{$_}) ? ( "_$_" => $opts{$_} ) : () } qw(
            parser
            max_pings

            on_data_frame

            out
        )),
    };

    return bless $self, $class;
}

sub get_next_message {
    my ($self) = @_;

    $self->_verify_not_closed();

    if ( my $frame = $self->{'_parser'}->get_next_frame() ) {
        if ($frame->is_control_frame()) {
            $self->_handle_control_frame($frame);
        }
        else {
            if ($self->{'_on_data_frame'}) {
                $self->{'_on_data_frame'}->($frame);
            }

            #Failure cases:
            #   - continuation without prior fragment
            #   - non-continuation within fragment

            if ( $frame->get_type() eq 'continuation' ) {
                if ( !@{ $self->{'_fragments'} } ) {
                    $self->_got_continuation_during_non_fragment($frame);
                }
            }
            elsif ( @{ $self->{'_fragments'} } ) {
                $self->_got_non_continuation_during_fragment($frame);
            }

            if ($frame->get_fin()) {
                return Net::WebSocket::Message::create_from_frames(
                    splice( @{ $self->{'_fragments'} } ),
                    $frame,
                );
            }
            else {
                push @{ $self->{'_fragments'} }, $frame;
            }
        }
    }

    return undef;
}

sub check_heartbeat {
    my ($self) = @_;

    my $ping_counter = $self->{'_ping_store'}->get_count();

    if ($ping_counter == $self->{'_max_pings'}) {
        my $close = Net::WebSocket::Frame::close->new(
            $self->FRAME_MASK_ARGS(),
            code => 'POLICY_VIOLATION',
        );

        $self->_write_frame($close);

        $self->{'_closed'} = 1;
    }

    my $ping_message = $self->{'_ping_store'}->add();

    my $ping = Net::WebSocket::Frame::ping->new(
        payload_sr => \$ping_message,
        $self->FRAME_MASK_ARGS(),
    );

    $self->_write_frame($ping);

    return;
}

sub shutdown {
    my ($self, %opts) = @_;

    my $close = Net::WebSocket::Frame::close->new(
        $self->FRAME_MASK_ARGS(),
        code => $opts{'code'} || 'ENDPOINT_UNAVAILABLE',
        reason => $opts{'reason'},
    );

    $self->_write_frame($close);

    $self->{'_closed'} = 1;

    return;
}

sub is_closed {
    my ($self) = @_;
    return $self->{'_closed'} ? 1 : 0;
}

#----------------------------------------------------------------------

sub on_ping {
    my ($self, $frame) = @_;

    $self->_write_frame(
        Net::WebSocket::Frame::pong->new(
            payload_sr => \$frame->get_payload(),
            $self->FRAME_MASK_ARGS(),
        ),
    );

    return;
}

sub on_pong {
    my ($self, $frame) = @_;

    $self->{'_ping_store'}->remove( $frame->get_payload() );

    return;
}

#----------------------------------------------------------------------

sub _got_continuation_during_non_fragment {
    my ($self, $frame) = @_;

    my $msg = sprintf('Received continuation outside of fragment!');

    #For now … there may be some multiplexing extension
    #that allows some other behavior down the line,
    #but let’s enforce standard protocol for now.
    my $err_frame = Net::WebSocket::Frame::close->new(
        code => 'PROTOCOL_ERROR',
        reason => $msg,
        $self->FRAME_MASK_ARGS(),
    );

    $self->_write_frame($err_frame);

    die Net::WebSocket::X->create( 'ReceivedBadControlFrame', $msg );
}

sub _got_non_continuation_during_fragment {
    my ($self, $frame) = @_;

    my $msg = sprintf('Received %s; expected continuation!', $frame->get_type());

    #For now … there may be some multiplexing extension
    #that allows some other behavior down the line,
    #but let’s enforce standard protocol for now.
    my $err_frame = Net::WebSocket::Frame::close->new(
        code => 'PROTOCOL_ERROR',
        reason => $msg,
        $self->FRAME_MASK_ARGS(),
    );

    $self->_write_frame($err_frame);

    die Net::WebSocket::X->create( 'ReceivedBadControlFrame', $msg );
}

sub _verify_not_closed {
    my ($self) = @_;

    die "Already closed!" if $self->{'_closed'};

    return;
}

sub _handle_control_frame {
    my ($self, $frame) = @_;

    my ($resp_frame, $error, $ignore_sigpipe);

    my $type = $frame->get_type();

    if ($type eq 'close') {
        $self->{'_received_close'} = 1;
        $self->{'_closed'} = 1;

        my ($code, $reason) = $frame->get_code_and_reason();

        $resp_frame = Net::WebSocket::Frame::close->new(
            code => $code,
            reason => $reason,
            $self->FRAME_MASK_ARGS(),
        );

        $self->_write_frame( $resp_frame );

        die Net::WebSocket::X->create('ReceivedClose', $frame);
    }
    elsif ( my $handler_cr = $self->can("on_$type") ) {
        $handler_cr->( $self, $frame );
    }
    else {
        my $ref = ref $self;
        die Net::WebSocket::X->create(
            'ReceivedBadControlFrame',
            "“$ref” cannot handle a control frame of type “$type”",
        );
    }

    return;
}

sub _write_frame {
    my ($self, $frame, $todo_cr) = @_;

    return $self->{'_out'}->write($frame->to_bytes(), $todo_cr);
}

1;
