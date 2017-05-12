#  File: Stem/SockMsg.pm

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

package Stem::SockMsg ;

use strict ;

use Data::Dumper ;

use Stem::Socket ;
use Stem::Trace 'log' => 'stem_status', 'sub' => 'TraceStatus' ;
use Stem::Trace 'log' => 'stem_error' , 'sub' => 'TraceError' ;
use Stem::Route qw( :cell ) ;
use base 'Stem::Cell' ;

use Stem::Debug qw( dump_data dump_socket ) ;


my $attr_spec = [

	{
		'name'		=> 'reg_name',
		'help'		=> <<HELP,
The registration name for this Cell
HELP
	},

	{
		'name'		=> 'host',
		'env'		=> 'host',
		'help'		=> <<HELP,
Host address to listen on or connect to
HELP
	},

	{
		'name'		=> 'port',
		'env'		=> 'port',
		'required'	=> 1,
		'help'		=> <<HELP,
Port address to listen on or connect to
HELP
	},

	{
		'name'		=> 'server',
		'type'		=> 'boolean',
		'help'		=> <<HELP,
Mark this Cell as a server (listens for connections)
HELP
	},

	{
		'name'		=> 'connect_now',
		'type'		=> 'boolean',
		'help'		=> <<HELP,
Connect upon Cell creation
HELP
	},

	{
		'name'		=> 'status_addr',
		'type'		=> 'address',
		'help'		=> <<HELP,
Send status (connect/disconnect) messages to this address.
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
		'name'		=> 'log_name',
		'help'		=> <<HELP,
Log to send connection status to
HELP
	},

	{
		'name'		=> 'cell_attr',
		'class'		=> 'Stem::Cell',
		'help'		=> <<HELP,
Argument list passed to Stem::Cell for this Cell
HELP
	},

] ;

#my $listener ;


sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

	if ( $self->{'server'} ) {
		my $listen_obj = Stem::Socket->new( 
				'object'	=> $self,
				'host'		=> $self->{'host'},
				'port'		=> $self->{'port'},
				'server'	=> 1,
		) ;

		return $listen_obj unless ref $listen_obj ;

		my $host_text = $self->{'host'} ;

		$host_text = 'localhost' unless defined $host_text ;

		my $info = <<INFO ;
SockMsg
Type:	server
Local:	$host_text:$self->{'port'}
INFO

		$self->cell_info( $info ) ;

		$self->{'listen_obj'} = $listen_obj ;

#print "LISTEN $listen_obj\n" ;
#$listener = $listen_obj ;

		$self->cell_activate() ;
	}
	elsif ( $self->{'connect_now'} ) {

		$self->connect() ;
	}

	$self->cell_set_args(
			'host'		=> $self->{'host'},
			'port'		=> $self->{'port'},
			'server'	=> $self->{'server'},
	) ;

#print  "Sock\n", Dumper( $self ) ;

	return( $self ) ;
}

sub connect {

	my( $self ) = @_ ;

#print "MODE [$self->{connecting}]\n" ;

#	return if $self->{connecting}++ ;

	my $host = $self->cell_get_args( 'host' ) || $self->{'host'} ;
	my $port = $self->cell_get_args( 'port' ) || $self->{'port'} ;
	my $sync = $self->cell_get_args( 'sync' ) || $self->{'sync'} ;

########################
########################
## handle connect timeouts
########################
########################

#TraceStatus "Connecting to $host:$port" ;

	my $sock_obj = Stem::Socket->new( 
			'object'	=> $self,
			'host'		=> $host,
			'port'		=> $port,
			'sync'		=> $sync,
	) ;

	return $sock_obj unless ref $sock_obj ;

	$self->{'sock_obj'} = $sock_obj ;

	return ;
}

sub connected {

	my( $self, $connected_sock ) = @_ ;

#print "CONNECTED\n" ;

	$self->{connected} = 1 ;

	$self->send_status_msg( 'connected' ) ;

	my $type = $self->{'sock_obj'} ?
			$self->{'sock_obj'}->type() :
			'sync connected' ;

	my $info = sprintf( <<INFO,
SockMsg connected
Type:	$type
Local:	%s:%d
Remote:	%s:%d
INFO
				$connected_sock->sockhost(),
				$connected_sock->sockport(),
				$connected_sock->peerhost(),
				$connected_sock->peerport(),
	) ;

	TraceStatus "\n$info" ;

	if ( my $log_name = $self->{ 'log_name' } ) {

#print "MSG LOG\n" ;

		Stem::Log::Entry->new(
				'logs'	=> $log_name,
				'text'	=> "Connected\n$info",
		) ;
	}

	$self->cell_set_args(
			'fh'		=> $connected_sock,
			'aio_args'	=>
				[ 'fh'	=> $connected_sock ],
			'info'		=> $info,
	) ;

	my $err = $self->cell_trigger() ;
#	print "TRIGGER ERR [$err]\n" unless ref $err ;
}

# this method is called after the cell is triggered. this cell can be
# the original cell or a cloned one.

sub triggered_cell {

	my( $self ) = @_ ;

#print "SockMsg triggered\n" ;
	return if $self->{'server'} ;

#	return "SockMsg: can't connect a server socket" if $self->{'server'} ;

	return $self->connect() ;
}

# we handle the socket close method directly here so we can reconnect
# if needed. the other async method callbacks are in Cell.pm

sub async_closed {

	my( $self ) = @_ ;

# reconnect stuff. should be in Socket.pm

#	my $sock = $self->cell_get_args( 'fh' ) ;
#	$sock->close() ;
#print "Sock MSG: closed name $self->{'reg_name'}\n" ;
#	$self->{'sock_obj'}->connect_to() ;

	$self->send_status_msg( 'disconnected' ) ;

	if ( my $log_name = $self->{ 'log_name' } ) {

		Stem::Log::Entry->new(
				'logs'	=> $log_name,
				'text'	=> "Closed\n$self->{'info'}",
		)
	}

#	TraceStatus "Disconnected" ;

	$self->cell_set_args( 'info' => 'SockMsg disconnected' ) ;

######################
######################
# add support for reconnect.
# it has a flag, delay, retry count.
######################
######################

	$self->shut_down() ;
}

sub shut_down {

	my( $self ) = @_ ;

#print "SOCKMSG SHUT $self\n", caller(), "\n", dump_data $self ;

	$self->cell_shut_down() ;

	unless ( $self->{'connected'} ) {

use Carp 'cluck' ;
#cluck "SOCKMSG SHUT SERVER $self\n" ;

		my $sock_obj = $self->{'sock_obj'} ;

		$sock_obj->shut_down() ;
	}
}

sub send_status_msg {

	my( $self, $status ) = @_ ;

	my $status_addr = $self->{status_addr} or return ;

	my $status_msg = Stem::Msg->new(
		to	=> $status_addr,
		from	=> $self->cell_from_addr(),
		type	=> 'status',
		data	=> {
			status	=> $status,
		},
	) ;

	$status_msg->dispatch() ;
}



sub DESTROY {
 	my ( $self ) = @_ ;

# print "SOCKMSG DESTROY", caller(), "\n" ;

#print $self->_dump( "DESTROY") ;
}


# sub IO::Socket::INET::DESTROY {
#  	my ( $self ) = @_ ;

# #	print "IO::DESTROY\n", dump_socket( $self ) ;

# #warn "L $listener - S $self\n" if $listener == $self ;

# # print "SOCKMSG DESTROY", caller(), "\n" ;
# #cluck "IO::DESTROY $self\n" ;
# }

1 ;
