#  File: Stem/Socket.pm

#  This file is part of Stem.
#  Copyright (C) 1999, 2000, 2001 Stem Systems, Inc.

#  Stem is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.

#  Stem is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with Stem; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#  For a license to use the Stem under conditions other than those
#  described here, to purchase support for this software, or to purchase a
#  commercial warranty contract, please contact Stem Systems at:

#       Stem Systems, Inc.		781-643-7504
#  	79 Everett St.			info@stemsystems.com
#  	Arlington, MA 02474
#  	USA

#######################################################

#print "LOADED\n" ;

package Stem::Socket ;

use strict ;

use IO::Socket ;
use Symbol ;
use Errno qw( EINPROGRESS ) ;

use Stem::Class ;

my $attr_spec = [

	{
		'name'		=> 'object',
		'required'	=> 1,
		'type'		=> 'object',
		'help'		=> <<HELP,
This is the owner object which has the methods that get called when Stem::Socket
has either connected, timed out or accepted a socket connection
HELP
	},
	{
		'name'		=> 'server',
		'type'		=> 'boolean',
		'help'		=> <<HELP,
If set, then this is a server socket.
HELP
	},
	{
		'name'		=> 'sync',
		'type'		=> 'boolean',
		'default'	=> 0,
		'help'		=> <<HELP,
Mark this as a synchronously connecting socket. Default is asyncronous
connections. In both cases the same method callbacks are used.
HELP
	},
	{
		'name'		=> 'port',
		'required'	=> 1,
		'help'		=> <<HELP,
This is the TCP port number for listening or connecting.
HELP
	},
	{
		'name'		=> 'host',
		'default'	=> 'localhost',
		'help'		=> <<HELP,
Host to connect to or listen on. If a listen socket host is explicitly
set to '', then the host will be INADDR_ANY which allows a server to
listen on all host interfaces.
HELP
	},
	{
		'name'		=> 'method',
		'default'	=> 'connected',
		'help'		=> <<HELP,
This method is called in the owner object when when a socket
connection or accept happens.
HELP
	},
	{
		'name'		=> 'timeout_method',
		'default'	=> 'connect_timeout',
		'help'		=> <<HELP,
This method is called in the owner object when when a socket
connection times out.
HELP
	},
	{
		'name'		=> 'timeout',
		'default'	=> 10,
		'help'		=> <<HELP,
How long to wait (in seconds) before a connection times out.
HELP
	},
	{
		'name'		=> 'max_retries',
		'default'	=> 0,
		'help'		=> <<HELP,
The maximum number of connection retries before an error is returned.
HELP
	},
	{
		'name'		=> 'listen',
		'default'	=> '5',
		'help'		=> <<HELP,
This sets how many socket connections can be queued by a server socket.
HELP
	},
	{
		'name'		=> 'ssl_args',
		'type'		=> 'list',
		'help'		=> <<HELP,
This makes the socket use the IO::Socket::SSL module for secure sockets. The 
arguments are passed to the new() method of that module.
HELP
	},
	{
		'name'		=> 'id',
		'help'		=> <<HELP,
The id is passed to the callback method as its only argument. Use it to
identify different instances of this object.
HELP

	},
] ;

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

	if ( $self->{ 'server' } ) {

		$self->{'type'} = 'server' ;
		my $listen_err = $self->listen_to() ;

#print "ERR [$listen_err]\n" ;
		return $listen_err if $listen_err ;
	}
	else {

		$self->{'type'} = 'client' ;
		my $connect_err = $self->connect_to() ;
		return $connect_err if $connect_err ;
	}

	return( $self ) ;
}

use Carp 'cluck' ;

sub shut_down {

	my( $self ) = @_ ;

#cluck "SOCKET SHUT" ;

	if ( $self->{'type'} eq 'server' ) {

#print "SOCKET SHUT server" ;

		if ( my $read_event = delete $self->{'read_event'} ) {

			$read_event->cancel() ;
		}

		my $listen_sock = delete $self->{'listen_sock'} ;
		$listen_sock->close() ;

		return ;
	}

#print "SOCKET SHUT client" ;

	$self->_write_cancel() ;

	return ;
}

sub type {
	$_[0]->{'type'} ;
}

sub connect_to {

	my( $self ) = @_ ;

	my $connect_sock = Stem::Socket::get_connected_sock(
		$self->{'host'},
		$self->{'port'},
		$self->{'sync'},
	) ;

	return $connect_sock unless ref $connect_sock ;

	$self->{'connected_sock'} = $connect_sock ;

	if( $self->{'sync'} ) {

		$self->connect_writeable() ;
		return ;
	}

# create and save the write event watcher

	my $write_event = Stem::Event::Write->new(
			'object'	=>	$self,
			'fh'		=>	$connect_sock,
			'timeout'	=>	$self->{'timeout'},
			'method'	=>	'connect_writeable',
			'timeout_method' =>	'connect_timeout',
	) ;

	return $write_event unless ref $write_event ;
	$self->{'write_event'} = $write_event ;
	$write_event->start() ;

	return ;
}

# callback when a socket is connected (the socket is writeable)

sub connect_writeable {

	my( $self ) = @_ ;

# get the connected socket

	my $connected_sock = $self->{'connected_sock'} ;

	if ( my $ssl_args = $self->{'ssl_args'} ) {

		require IO::Socket::SSL ;
		IO::Socket::SSL->VERSION(0.96);

		my $err = IO::Socket::SSL->start_SSL(
			$connected_sock,
			@{$ssl_args}
		) ;

		$err || die
			"bad ssl connect socket: " . IO::Socket::SSL::errstr() ;
	}

# the i/o for sockets is always non-blocking in stem.

	$connected_sock->blocking( 0 ) ;

# callback the owner object with the connected socket as the argument

	my $method = $self->{'method'} ;
	$self->{'object'}->$method( $connected_sock, $self->{'id'} );

	$self->_write_cancel() ;

	return ;
}

sub connect_timeout {

	my( $self ) = @_ ;

	$self->_write_cancel() ;

	$self->{'connected_sock'}->close() ;
	delete $self->{'connected_sock'} ;

	if ( $self->{'max_retries'} && --$self->{'retry_count'} > 0 ) {

		my $method = $self->{'timeout_method'} ;
		$self->{'object'}->$method( $self->{'id'} );
		return ;
	}

	$self->connect_to() ;

	return ;
}

sub _write_cancel {

	my( $self ) = @_ ;

#	my $sock = delete $self->{'connected_sock'} ;
#	$sock->close() ;

	my $event = delete $self->{'write_event'} ;
	return unless $event ;
	$event->cancel() ;
}

sub get_connected_sock {

	my( $host, $port, $sync ) = @_ ;

	unless( $port ) {

		my $err = "get_connected_sock Missing port" ;
		return $err ;
	}

# get the host name or IP and convert it to an inet address

	my $inet_addr = inet_aton( $host ) ;

	unless( $inet_addr ) {

		my $err = "get_connected_sock Unknown host [$host]" ;
		return $err ;
	}

# check if it is a get the service name or numeric port and convert it
# to a port number

	if ( $port =~ /\D/ and not $port = getservbyname( $port, 'tcp' ) ) {

		my $err = "get_connected_sock: unknown port [$port]" ;
		return $err ;
	}

# prepare the socket address

	my $sock_addr = pack_sockaddr_in( $port, $inet_addr ) ;

	my $connect_sock = IO::Socket::INET->new( Domain => AF_INET) ;

#print "connect $connect_sock [", $connect_sock->fileno(), "]\n" ;

# set the sync (connect blocking) mode

	$connect_sock->blocking( $sync ) ;

	unless ( connect( $connect_sock, $sock_addr ) ) {

# handle linux false error of EINPROGRESS

		return <<ERR unless $! == EINPROGRESS ;
get_connected_sock: connect to '$host:$port' error $!
ERR
	}

	return $connect_sock ;
}

sub listen_to {

	my( $self ) = @_ ;

	my $listen_sock = get_listen_sock(
		$self->{'host'},
		$self->{'port'},
		$self->{'listen'},
	) ;

	return $listen_sock unless ref $listen_sock ;

	$self->{'listen_sock'} = $listen_sock ;

# create and save the read event watcher

	my $read_event = Stem::Event::Read->new(
				'object'	=> $self,
				'fh'		=> $listen_sock,
				'method'	=> 'listen_readable',
	) ;
					
	$self->{'read_event'} = $read_event ;

	return ;
}

# callback when a socket can be accepted (the listen socket is readable)

sub listen_readable {

	my( $self ) = @_ ;

# get the accepted socket

	my $accepted_sock = $self->{'listen_sock'}->accept() ;

# $accepted_sock || die "bad accept socket: ";
my $fileno = fileno $accepted_sock ;
#print "ACCEPT [$accepted_sock] ($fileno)\n" ;

	if ( my $ssl_args = $self->{'ssl_args'} ) {

		require IO::Socket::SSL ;
		IO::Socket::SSL->VERSION(0.96);

		my $err = IO::Socket::SSL->start_SSL(
			$accepted_sock,
			SSL_server	=> 1,
			@{$ssl_args}
		) ;

		$err || die
			"bad ssl accept socket: " . IO::Socket::SSL::errstr() ;
	}

# the i/o for sockets is always non-blocking in stem.

	$accepted_sock->blocking( 0 ) ;

# callback the object/method with the accepted socket as the argument

	my $method = $self->{'method'} ;
	$self->{'object'}->$method( $accepted_sock, $self->{'id'} );
	return ;
}

sub stop_listening {

	my( $self ) = @_ ;

	my $read_event = $self->{'read_event'} ;
	return unless $read_event ;
	$read_event->stop() ;
}

sub start_listening {

	my( $self ) = @_ ;

	my $read_event = $self->{'read_event'} ;
	return unless $read_event ;
	$read_event->start() ;
}

sub get_listen_sock {

	my( $host, $port, $listen ) = @_ ;

	return "get_listen_sock Missing port" unless $port ;

# get the host name or IP and convert it to an inet address
# an empty host ('') will force INADDR_ANY

	my $inet_addr = length( $host ) ? inet_aton( $host ) : INADDR_ANY ;

#print "HOST [$host]\n" ;
#print inet_ntoa( $inet_addr ), "\n" ;

	return "get_listen_sock Unknown host [$host]" unless $inet_addr ;

# check if it is a get the service name or numeric port and convert it
# to a port number

	if ( $port =~ /\D/ and not $port = getservbyname( $port, 'tcp' ) ) {

		return "get_listen_sock: unknown port [$port]" ;
	}

# prepare the socket address

	my $sock_addr = pack_sockaddr_in( $port, $inet_addr ) ;

	my $listen_sock = IO::Socket::INET->new( 

		Proto     => 'tcp',
		LocalAddr => $host,
		LocalPort => $port,
		Listen    => $listen,
		Reuse     => 1,
	) ;

	return( "get_listen_sock: $host:$port $!" ) unless $listen_sock ;
	return $listen_sock ;
}

1 ;
