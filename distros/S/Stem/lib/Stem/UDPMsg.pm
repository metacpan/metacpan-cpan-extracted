#  File: Stem/UDPMsg.pm

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

package Stem::UDPMsg ;

use strict ;

use Data::Dumper ;
use IO::Socket ;

my $attr_spec = [

	{
		'name'		=> 'reg_name',
		'help'		=> <<HELP,
The registration name for this Cell
HELP
	},

	{
		'name'		=> 'bind_host',
		'help'		=> <<HELP,
The UDP socket is bound to this host for receiving or sending packets
HELP
	},

	{
		'name'		=> 'bind_port',
		'help'		=> <<HELP,
The UDP socket is bound to this port for receiving or sending packets
HELP
	},
	{
		'name'		=> 'send_host',
		'help'		=> <<HELP,
The UDP packet is sent to this host if the send message has no host
HELP
	},
	{
		'name'		=> 'send_port',
		'help'		=> <<HELP,
The UDP packet is sent to this port if the send message has no port
HELP
	},
	{
		'name'		=> 'bind_port',
		'help'		=> <<HELP,
The UDP socket is bound to this port for receiving or sending packets
HELP
	},
	{
		'name'		=> 'server',
		'type'		=> 'boolean',
		'help'		=> <<HELP,
Marks this socket as a server and it expect to receive UDP packets
HELP
	},
	{
		'name'		=> 'max_recv_size',
		'default'	=> 4096,
		'help'		=> <<HELP,
Maximum size of received UDP packets.

HELP
	},
	{
		'name'		=> 'data_addr',
		'help'		=> <<HELP,
Send received UDP packets as 'udp_data' type messages to this address
HELP
	},
	{
		'name'		=> 'error_addr',
		'help'		=> <<HELP,
Send received UDP errors as 'udp_error' type messages to this address
HELP
	},
	{
		'name'		=> 'timeout_addr',
		'help'		=> <<HELP,
Send UDP timeouts as 'udp_timeout' type messages to this address
HELP
	},
	{
		'name'		=> 'object',
		'help'		=> <<HELP,
This object will get the callbacks
HELP
	},
	{
		'name'		=> 'timeout',
		'help'		=> <<HELP,
This sets the timeout period to wait for UDP data. If no data has been
received since the timer started, a timeout message or callback will
be triggered.
HELP
	},
	{
		'name'		=> 'recv_method',
		'default'	=> 'udp_received',
		'help'		=> <<HELP,
This method will be called in the object when a UDP packet has been received 
HELP
	},
	{
		'name'		=> 'error_method',
		'default'	=> 'udp_error',
		'help'		=> <<HELP,
This method will be called in the object when a UDP had been detected
HELP
	},
	{
		'name'		=> 'timeout_method',
		'default'	=> 'udp_timeout',
		'help'		=> <<HELP,
This method will be called in the object when no UDP data has been received
after the timeout period.
HELP
	},
	{
		'name'		=> 'log_name',
		'help'		=> <<HELP,
Log to send store sent and received messages
HELP
	},
] ;


sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

	my $info_text = '' ;

	my $socket = IO::Socket::INET->new( 'Proto' => 'udp' ) ;
	$self->{'socket'} = $socket ;

	if ( my $bind_port = $self->{'bind_port'} ) {

		$info_text .= "Port:      $bind_port\n" ;

		my $bind_ip ;
		my $bind_host = $self->{'bind_host'} ;

		if ( length $bind_host ) {

			$bind_ip = inet_aton( $bind_host ) ;
			$info_text .= "Host:       $bind_host\n" ;
		}
		else {

			$bind_ip = INADDR_ANY ;
			$info_text .= "Host:      INADDR_ANY\n" ;
		}

		$socket->bind( $bind_port, $bind_ip ) ;
	}

	my @timeout_args = ( $self->{'timeout'} ) ?
				( 'timeout' => $self->{'timeout'} ) : () ;


	if ( $self->{'server'} ) {

		$self->{'read_event'} = Stem::Event::Read->new(
					'object'	=> $self,
					'fh'		=> $socket,
					@timeout_args,
		) ;
	}

	my $reg_name = $self->{'reg_name'} || 'NONE' ;
	my $sock_host = $socket->sockhost ;
	my $sock_port = $socket->sockport ;

	$self->{'info'} = <<INFO ;
---------------------
UDPMsg

Cell name: $reg_name
Port:      $sock_port
---
$info_text
---------------------

INFO

	return $self ;
}

sub status_cmd {

	my ( $self ) = @_ ;

	return 	$self->{'info'} ;
}


sub readable {

	my( $self ) = @_ ;

#print "UDP readable\n" ;

	my $udp_data ;

	my $udp_addr = $self->{'socket'}->recv( $udp_data,
						 $self->{'max_recv_size'} ) ;

#print "UDP READ [$udp_data]\n" ;

# handle errors

	unless( defined( $udp_addr ) ) {

		if ( my $error_addr = $self->{'error_addr'} ) {

			my $msg = Stem::Msg->new(
				'to'		=> $error_addr,
				'from'		=> $self->{'from_addr'},
				'type'		=> 'udp_error',
				'data'		=> \"$!",
			) ;

#print $msg->dump( 'UDP error' ) ;
			$msg->dispatch() ;
			return ;
		}

# send the data via a callback

		if ( my $obj = $self->{'object'} ) {

			my $method = $self->{'error_method'} ;
			$obj->$method( \"$!" ) ;
		}

		return ;
	}

	my( $from_port, $from_host ) = unpack_sockaddr_in( $udp_addr ) ;

	$from_host = inet_ntoa( $from_host ) ;

# send out the data as a stem message

#print "ADDR [$self->{'data_addr'}]\n" ;

	if ( my $data_addr = $self->{'data_addr'} ) {

		my $msg = Stem::Msg->new(
			'to'		=> $data_addr,
			'from'		=> $self->{'reg_name'},
			'type'		=> 'udp_data',
			'data'		=> {
				'data'		=> \$udp_data,
				'from_port'	=> $from_port,
				'from_host'	=> $from_host,
			},
		) ;

#print $msg->dump( 'UDP recv' ) ;
		$msg->dispatch() ;
		return ;
	}

# send the data via a callback

	if ( my $obj = $self->{'object'} ) {

		my $method = $self->{'recv_method'} ;
		$obj->$method( \$udp_data, $from_port, $from_host ) ;
	}

	return ;
}

sub read_timeout {

	my( $self ) = @_ ;

#print "UDP timeout\n" ;

# send out the timeout as a stem message

	if ( my $timeout_addr = $self->{'timeout_addr'} ) {

		my $msg = Stem::Msg->new(
			'to'		=> $timeout_addr,
			'from'		=> $self->{'reg_name'},
			'type'		=> 'udp_timeout',
		) ;

#print $msg->dump( 'UDP timeout' ) ;
		$msg->dispatch() ;
		return ;
	}

# send the timeout via a callback

	if ( my $obj = $self->{'object'} ) {

		my $method = $self->{'timeout_method'} ;
		$obj->$method() ;
	}

	return ;
}


sub send_cmd {

	my ( $self, $msg ) = @_ ;

#print $msg->dump( 'UDP send' ) ;
	my $msg_data = $msg->data() ;

	my $send_port = $msg_data->{'send_port'} || $self->{'send_port'} ;
	my $send_host = $msg_data->{'send_host'} || $self->{'send_host'} ;

	my $udp_data = $msg_data->{'data'} ;

	return $self->_send( $udp_data, $send_port, $send_host ) ;
}

sub send {

	my ( $self, $data, %args ) = @_ ;

	my $send_port = $args{'send_port'} || $self->{'send_port'} ;
	my $send_host = $args{'send_host'} || $self->{'send_host'} ;

	return $self->_send( $data, $send_port, $send_host ) ;
}

sub _send {

	my( $self, $data, $port, $host ) = @_ ;

	$host or return "Missing send_host for UDP send" ;
	$port or return "Missing send_port for UDP send" ;

#print "P $port H $host\n" ;

	my $host_ip = inet_aton( $host ) ;
	$host_ip or return "Bad host '$host'" ;

	my $send_addr = pack_sockaddr_in( $port, $host_ip ) ;

	$data = $$data if ref $data ;

	my $byte_cnt = $self->{'socket'}->send( $data, 0, $send_addr ) ;

#print "BYTES [$byte_cnt]\n" ;

	return "send error: $!" unless defined $byte_cnt ;
	return ;
}


sub shut_down_cmd {

	my ( $self, $msg ) = @_ ;

#print $msg->dump( 'SHUT' ) ;

	$self->shut_down() ;

	return ;
}

sub shut_down {

	my ( $self ) = @_ ;

	if ( my $read_event = delete $self->{'read_event'} ) {

		$read_event->cancel() ;
	}

	delete $self->{'object'} ;

	my $socket = delete $self->{'socket'} ;

	close $socket ;
}

1 ;
