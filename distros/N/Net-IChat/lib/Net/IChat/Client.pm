package Net::IChat::Client;

use strict;
use warnings;

use EO;
use IO::Socket;
use Sys::Hostname;
use Net::Rendezvous::Publish;
use Class::Accessor::Chained;
use Net::IChat::Conversation;
use base qw( EO Class::Accessor::Chained );

our $VERSION = '0.01';

$SIG{CHLD} = "IGNORE";

exception Net::IChat::Client::CouldNotCreateSocket;

Net::IChat::Client->mk_accessors(
				 qw(
				    vc
				    name
				    port
				    version
				    first
				    last
				    email
				    txtvers
				    status
				    msg
				    pid
				    queuesize
				    server_socket
				    address
				   )
				);

sub init {
  my $self = shift;
  if ( $self->SUPER::init( @_ ) ) {
    $self->vc( '!' );
    $self->port( 5300 );
    $self->status( 'avail' );
    $self->version( '1' );
    $self->txtvers( '1' );
    $self->queuesize( 5 );
    $self->first('Net');
    $self->last('IChat client');
    $self->address( hostname() );
    $self->setup_name;

    return 1;
  }
  return 0;
}

sub setup_name {
  my $self = shift;
  my $hostname = hostname();
  $self->name( 'netichat' . $self->name_at_string );
}

sub name_at_string {
  my $self = shift;
  my $host = hostname;
  return '@' . substr( $host, 0, index( $host, '.' ) );
}

sub converse {
  my $self = shift;
  $self->setup_socket;
}

sub mdns_entry {
  my $self = shift;
  my $entry = shift;
  $self->vc( $entry->attribute('vc') );
  $self->msg( $entry->attribute('msg') );
  $self->first( $entry->attribute( '1st' ) );
  $self->last( $entry->attribute( 'last' ) );
  $self->port( $entry->attribute('port.p2pj') );
  $self->email( $entry->attribute('email') );
  $self->name( $entry->name );
  $self->address( $entry->address );
  $self;
}

sub publish_keys {
  my $self = shift;
  return qw( vc txtvers status port.p2pj version last email 1st phsh msg );
}

sub publish_alternate_vals {
  my $self = shift;
  return {
	  '1st' => 'first',
	  phsh  => 'oid',
	  'port.p2pj' => 'port'
	 };
}

sub publish_keyvals {
  my $self = shift;
  map {
    my $meth = $self->publish_alternate_vals->{ $_ } || $_;
    my $result = sprintf("%s=%s", $_, $self->$meth || '');
    $result;
  } $self->publish_keys;
}

sub publish_attrs {
  my $self = shift;
  join("\001", $self->publish_keyvals);
}

sub mdns_service_type {
  my $self = shift;
  return '_presence._tcp';
}

sub announce {
  my $self = shift;
  my $rp   = Net::Rendezvous::Publish->new;
  my $srv  = $rp->publish(
			  name => $self->name,
			  type => $self->mdns_service_type,
			  port => $self->port,
			  txt  => $self->publish_attrs
			 );
  if (my $pid = fork()) {
    $self->setup_server;
    $self->pid( $pid );
    return 1;
  } else {
    while(1) {
      $rp->step( 0.01 );
    }
  }
}

sub setup_socket {
  my $self = shift;
  my $sock = IO::Socket::INET->new(
				   PeerPort => $self->port,
				   PeerAddr => $self->address,
				   Reuse    => 1
				  );
  if (!$sock) {
    my $host = $self->address;
    my $port = $self->port;
    throw Net::IChat::Client::CouldNotCreateSocket
      text => "could not connect to $host on port $port ($!)";
  }
  Net::IChat::Conversation->new()->socket( $sock, $self->address );
}

sub setup_server {
  my $self = shift;
  my $io   = IO::Socket::INET->new(
				   LocalPort => $self->port,
				   Listen    => $self->queuesize,
				   Reuse     => 1,
				  );
  if (!$io) {
    my $port = $self->port;
    throw Net::IChat::Client::CouldNotCreateSocket
      text => "could not create socket on port $port: $!";
  } else {
    $self->server_socket( $io );
    return 1;
  }
}

sub conversation {
  my $self   = shift;
  local $| = 10;
  my $client = $self->server_socket->accept;
  return Net::IChat::Conversation->new->socket( $client );
}

sub DESTROY {
  my $self = shift;
  if ($self->pid()) {
    kill $self->pid;
  }
  if ($self->server_socket) {
    $self->server_socket->close();
  }
}

1;
