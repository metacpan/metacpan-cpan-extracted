#!/usr/bin/perl
use lib qw( lib );
use Data::Dumper;
use strict;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use IO::Socket::Multicast;
use JSON;
use Carp qw( cluck );

$|++;

#use Padre::Swarm::Transport::Multicast;
#my $mc = Padre::Swarm::Transport::Multicast->new;
#$mc->subscribe_channel( 12000 );
#$mc->start;

my $mcast_out = IO::Socket::Multicast->new(
    PeerAddr => '239.255.255.1',
    PeerPort => 12000,
    ReuseAddr => 1,
    Blocking  => 0,
) or die $!;
my $local_relay = AnyEvent::Handle->new(
    fh => $mcast_out,
);
my $mcast_in = IO::Socket::Multicast->new(
    LocalPort => 12000,
    ReuseAddr => 1,
    Blocking => 0
);

$mcast_in->mcast_add('239.255.255.1');
#$mcast_in->mcast_loopback(0);

my $ae_local = AnyEvent::Handle->new(
    fh => $mcast_in,
    on_read => \&local_read,
    on_error => \&local_error,
  #  timeout  => 1,
) or die $!;


tcp_connect 'swarm.perlide.org' => 12000 ,
    \&join_swarm, 
    , sub { 5 };

our $swarm;

my $runtime = AnyEvent->condvar;
our $swarm_ready = AnyEvent->condvar;
$swarm_ready->recv;
warn "Relay ready";

$runtime->recv;

sub join_swarm {
    my ($fh) = @_;
    die $! unless $fh;
    $swarm = AnyEvent::Handle->new(
        fh => $fh,
        tls => 'connect',
        #on_read => \&swarm_read,
        on_error => \&swarm_error,
#        timeout => 1,
    );
    my $message = {
        #type => 'promote',
        #service => 'relay',
        type => 'session',
        trustme => "relay-$$-".time(),
    };
    
    $swarm->push_write( json => $message );
    $swarm->push_read( json => \&swarm_ready );
    
    
}

sub swarm_ready {
    my ($handle ,$message) = @_;
    $handle->destroy
        unless $message->{token};
    $handle->{token} = $message->{token};
    
    warn "SWARM Authorized " . $message->{token},$/;
    
    $handle->push_write( json => {
        type => 'promote',
        from => $handle->{token},
        service => 'relay',
    } );
    
    $handle->push_write( json => {
        type => 'disco',
        want => 'relay',
        from => $handle->{token},
    } );
    
    $local_relay->push_write( json => {
        type => 'promote',
        from => $handle->{token},
        service => 'relay',
    });
    
    $handle->on_read( \&swarm_read );
    $swarm_ready->send;
    
    
}

sub swarm_read {
    my $handle = shift;
    $handle->push_read( json=>\&swarm_recv );
}

sub swarm_error {
    my ($handle ,$fatal ) = @_;
    warn "Server Error $!";
    $handle->destroy;
    $runtime->croak;
    
}

sub swarm_recv {
    my ($handle,$message) = @_;
    
    if ( $message->{_relay} eq $handle->{token} ) {
        warn "Discarded looping relay to self";
        return;
        
    }
    $message->{_relay} = $handle->{token};
    my $payload = JSON::encode_json($message);
    #$ae_local->fh->mcast_send(
    #    $payload,
    #    '239.255.255.1:12000', 
    #);
    $local_relay->push_write( json => $message );
}

sub local_read {
    my ($handle) = shift;
    $handle->push_read( json => \&local_recv );
}

sub local_error {
    my ($handle,$fatal) = @_;
    warn "Local socket error $!";
    $handle->destroy;
}

sub local_recv {
    my ($handle,$message) = @_;
    
    # Seeing a relayed message locally is bad news
    if ( exists $message->{_relay} ) {
        warn "Saw relay from " , $message->{_relay};
        return;
    }
    
warn ref $swarm , "Send message , " , $message->{type};
    $message->{_relay} = $swarm->{token};
    $swarm->push_write( json => $message )
        if ref  $swarm;
}
