package Padre::Plugin::Swarm::Transport::Local::Multicast;
use strict;
use warnings;
use Wx qw( :socket );
use Padre::Wx ();
use Padre::Logger;
use base qw( Padre::Plugin::Swarm::Transport  Padre::Role::Task );
use Padre::Plugin::Swarm::Transport::Local::Multicast::Service;

our $VERSION = '0.11';

use Class::XSAccessor
    accessors => {
        socket => 'socket',
        service => 'service',
        config => 'config',
        token  => 'token',
        mcast_address => 'mcast_addr',
        marshal => 'marshal',
    };
    

*enable = \&connect;

*disable = \&disconnect;

sub connect { 
    my $self = shift;
    # build the transmitting socket
    my $mcast_address = Wx::IPV4address->new;
    $mcast_address->SetHostname('239.255.255.1');
    $mcast_address->SetService(12000);
    $self->mcast_address($mcast_address);
    # Local address 
    my $local_address = Wx::IPV4address->new;
    $local_address->SetAnyAddress;
    $local_address->SetService( 0 ); # 0 == random source port
    my $transmitter = Wx::DatagramSocket->new( $local_address );

    $self->socket( $transmitter );

    # start the service thread listener
    my $service = $self->task_request(
        task => 'Padre::Plugin::Swarm::Transport::Local::Multicast::Service'
    );
    
    $self->service($service);
    
}

sub disconnect {
    my $self = shift;
    $self->socket->Destroy;
    #$self->service->hangup;
    
    # teardown the transmitting socket
    # hangup the service thread
    
}

sub on_service_recv {
    my ($self,$data) = @_;
    TRACE( "On service recv with @_") if DEBUG;
    
    ## TODO - fix Padre::Service to have an event for started/stopped
    if ( $data eq 'ALIVE' ) {
        $self->on_connect->() if $self->on_connect;
        return;
    } elsif ( $data eq 'DEAD' ) {
        $self->on_disconnect->() if $self->on_disconnect;
        return;
    }
    
    my @messages = eval { $self->marshal->decode($data) };
    if ( $@ ) {
        TRACE( "Failed to decode data '$data' , $@" ) if DEBUG;
    }
    foreach my $m ( @messages ) {
    
        $self->on_recv->( $m ) if $self->on_recv;
    }
}

# Send a Padre::Swarm::Message
sub NOTsend {
    my $self = shift;
    my $message = shift;
    $message->{token} ||= $self->{token};
    
    my $data = eval { $self->marshal->encode( $message ) };
    if ($@) { 
        TRACE( "Failed to encode $message - $@" ) if DEBUG;
        return;
    }
    
    $self->write($data);
    
}

# Write encoded data to socket
sub write {
    my $self = shift;
    my $data = shift;
    $self->socket->SendTo( $self->mcast_address, $data, length($data) );
    
}

1;
