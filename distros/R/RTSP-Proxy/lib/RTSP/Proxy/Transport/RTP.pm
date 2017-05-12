package RTSP::Proxy::Transport::RTP;

use Moose;
with qw/RTSP::Proxy::Transport/;
extends 'Net::Server::Single';

use RTSP::Proxy::StreamBuffer;
use IO::Socket::INET;
use Carp qw/croak/;
use Net::RTP::Packet;

has stream_buffer => (
    is => 'rw',
    isa => 'RTSP::Proxy::StreamBuffer',
    lazy => 1,
    builder => 'build_stream_buffer',
    handles => [qw/add_packet get_packet clear_packets/],
);

has client_socket => (
    is => 'rw',
    isa => 'IO::Socket::INET',
    handles => [qw/write/],
);

# how many packets to buffer
has stream_buffer_size => (
    is => 'rw',
    isa => 'Int',
    default => 128,
    lazy => 1,
);


sub options {
    my $self     = shift;
    my $prop     = $self->{'server'};
    my $template = shift;

    ### setup options in the parent classes
    $self->SUPER::options($template);
    
    my $decode_rtp = $prop->{decode_rtp} || 0;    
    $prop->{decode_rtp} = $decode_rtp;
    $template->{decode_rtp} = \ $prop->{decode_rtp};
    
    my $output_raw = $prop->{output_raw} || 0;    
    $prop->{output_raw} = $output_raw;
    $template->{output_raw} = \ $prop->{output_raw};
}


# config defaults
sub default_values {
    return {
        proto        => 'udp',
        listen       => 1,
        port         => 6970,
        udp_recv_len => 4096,
        no_client_stdout => 1,
    }
}

sub DEMOLISH {
    my $self = shift;
    
    my $client_sock = $self->client_socket;
    return unless $client_sock;
    $client_sock->shutdown(2);
}

sub generate_session_id {
    my $self = shift;
    my $ug = new Data::UUID;
    $self->session_id($ug->create_str);
    return $self->session_id;
}

sub build_client_socket {
    my $self = shift;
    
    my $peer_port = $self->session->client_port_start;
    my $peer_address = $self->session->client_address;
    
    if (! $peer_port || ! $peer_address) {
        $self->log(3, "calling build_client_socket() with unknown client information");
        return;
    }
    
    $self->log(4, "buildling client socket to $peer_address:$peer_port");
    
    my $sock = IO::Socket::INET->new(
        PeerPort  => $peer_port,
        PeerAddr  => $peer_address,
        Proto     => 'udp',    
    ) or die "Can't bind: $@\n";
    
    return $sock;
}

sub build_stream_buffer {
    my $self = shift;

    my $sb = RTSP::Proxy::StreamBuffer->new(
        stream_buffer_size => $self->stream_buffer_size,
    );
    
    return $sb;
}

sub process_request {
    my $self = shift;
    
    my $packet_data = $self->{server}->{udp_data};
    $self->log(4, "got data of length " . (length $packet_data));
    
    $self->handle_packet($packet_data);
}

sub handle_packet {
    my ($self, $packet) = @_;
        
    # add packet to stream buffer
    $self->add_packet($packet);

    my $session = $self->session;
    if (! $session || ! $session->client_address || ! $session->client_port_start) {
        # no connection associated with this transport... not totally unexpected since UDP is stateless
        $self->log(3, "no valid session found for RTP transport in handle_packet()");
        return;
    }
    
    # forward packet to client
    my $client_addr = $session->client_address;
    $self->log(4, "forwarding packet to $client_addr");
    my $p = $self->get_packet or return;
    
    $self->decode_packet(\$p) if $self->{server}{decode_rtp};
    
    my $client_sock = $self->client_socket;
    if (! $client_sock) {
        $client_sock = $self->client_socket($self->build_client_socket);
    }
    return unless $client_sock;
    
    $self->log(3, "writing " . (length $p) . " bytes to $client_addr");
    $client_sock->write($p);
}

sub decode_packet {
    my ($self, $p) = @_;

    my $rtp = new Net::RTP::Packet($$p);
    return unless $rtp && $self->{server}{output_raw};
    
    $self->{buf} ||= '';
    $self->{buf} .= $rtp->payload if $rtp->payload_size;
        
    if ($rtp->marker) {
        local $|=1;
        print $self->{buf};
        $self->{buf} = '';
    }
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
