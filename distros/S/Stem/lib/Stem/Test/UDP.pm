#  File: Stem/Test/UDP.pm

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

package Stem::Test::UDP ;

use Test::More tests => 7 ;

my $attr_spec = [

	{
		'name'		=> 'reg_name',
		'help'		=> <<HELP,
This is the name under which this Cell was registered.
HELP
	},

	{
		'name'		=> 'send_addr',
		'help'		=> <<HELP,
The Cell address of a sending port
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
		
] ;

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;


	$self->{'udp_send_obj'} = Stem::UDPMsg->new() ;

#print $self->{'udp_send_obj'}->status_cmd() ;

# create a private udp server object and save it.

	$self->{'udp_recv_obj'} = Stem::UDPMsg->new(
			object	=> $self,
			bind_port	=> 9998,
			bind_host	=> '',
			server		=> 1,
			timeout		=> 1,
	) ;

#print $self->{'udp_recv_obj'}->status_cmd() ;

	my $err = $self->{'udp_send_obj'}->send( "LOCAL send",
				        send_host => 'local_host',
				        send_port => 9998,
	) ;

	ok( $err, 'bad host lookup' ) ;

	$err = $self->{'udp_send_obj'}->send( \"LOCAL send",
				        send_host => 'localhost',
				        send_port => 9998,
	) ;

	ok( !$err, 'good host lookup' ) ;

	return $self ;
}

sub udp_received {

	my( $self, $udp_data, $from_port, $from_host ) = @_ ;

	my $ok = ${$udp_data} =~ /LOCAL send/ ;

	ok( $ok, 'udp received') ;

#print "UDP [${$udp_data}]\n" ;

# now send out a bad and a good message to the udp send cell

	my $udp_msg = Stem::Msg->new(
			'to'	=> $self->{'send_addr'},
			'from'	=> $self->{'reg_name'},
			'cmd'	=> 'send',
			'data'	=> {
				'data'	=> \"foo",
				'send_port' => $self->{'send_port'},
			}
	) ;

	$udp_msg->dispatch() ;

	$udp_msg = Stem::Msg->new(
			'to'	=> $self->{'send_addr'},
			'from'	=> $self->{'reg_name'},
			'cmd'	=> 'send',
			'data'	=> {
				'data'	=> \"REMOTE foo",
				'send_port' => $self->{'send_port'},
				'send_host' => 'localhost',
			}
	) ;

#print $udp_msg->dump( 'UDP msg' ) ;

	$udp_msg->dispatch() ;
}

sub udp_timeout {

	my( $self ) = @_ ;

	ok(1, 'udp timeout') ;

# kill the receiver object so we can exit eventually

	$self->{'udp_recv_obj'}->shut_down() ;
	delete $self->{'udp_recv_obj'} ;

	return ;
}

sub udp_data_in {

	my( $self, $msg ) = @_ ;

	ok(1, 'udp data in called') ;

	my $udp_data = $msg->data()->{data} ;

	my $ok = ${$udp_data} =~ /REMOTE/ ;

#print $msg->dump( 'UDP IN' ) ;

	ok( $ok, 'udp data in') ;

# send a shutdown message to the udp receiver cell. with no more
# events it will cause the event loop to fall through and exit the
# test script.

	my $udp_msg = Stem::Msg->new(
			'to'	=> $msg->from(),
			'from'	=> $self->{'reg_name'},
			'cmd'	=> 'shut_down',
	) ;

	$udp_msg->dispatch() ;
}

sub udp_timeout_in {

	my( $self, $msg ) = @_ ;

	ok(1, 'udp timeout in') ;

#print $msg->dump( 'UDP timeout IN' ) ;

	return ;
}

sub response_in {

	my( $self, $msg ) = @_ ;

#print $msg->dump( 'UDP DATA' ) ;

	my $data = $msg->data() ;

	my $ok = ${$data} =~ /Missing send_host/ ;

	ok($ok, 'udp error response') ;
}

1 ;
