#  File: Stem/Test/PacketIO.pm

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

package Stem::Test::PacketIO ;

use Test::More ;

use Stem::Route qw( register_cell unregister_cell ) ;
use Stem::SockMsg ;

use base 'Stem::Cell' ;

my $attr_spec = [

	{
		'name'		=> 'reg_name',
		'help'		=> <<HELP,
This is the name under which this Cell was registered.
HELP
	},

	{
		'name'		=> 'port',
		'default'	=> 8889,
		'help'		=> <<HELP,
The port to use for the SockMsg cells.
HELP
	},
	{
		'name'		=> 'write_addr',
		'help'		=> <<HELP,
The Cell address of a sending port
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


my @msg_data = (
	"Packet scalar",
	\"Packet ref",
	{ foo => 2 },
	[ qw( a b c ) ],
	bless( { abc => 1 }, 'PIO_class' ),
	{ bar => 'xyz', qwert => 3 },
	{
		list => [ 1 .. 4 ],
		hash => { qwert => 3 },
	}
) ;

my @codecs = qw( YAML Storable Data::Dumper SimpleHash ) ;
#my @codecs = qw( SimpleHash ) ;
@codecs = grep { eval "require Stem::Codec::$_" } @codecs ;

plan tests => @msg_data * @codecs ;

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

	my $flow_text = <<FLOW ;

		WHILE codecs_left {

			create_sock_msg_pair ;
			DELAY 1 ;
			send_msg ;
			STOP ;
		}
		STOP ;
FLOW

	$self->cell_flow_init( 'test', $flow_text ) ;

	$self->cell_flow_go_in() ;

	return $self ;
}

sub send_msg {

	my( $self ) = @_ ;

	my $codec = $self->{'codec'} ;

# we send to the client hence to the server, on to echo, back to the
# server and through the client all the way to here

	foreach my $data ( @msg_data ) {

		if ( $codec eq 'SimpleHash' ) {

			if ( ref $data ne 'HASH' ) {

				ok( 1,
		    'skip SimpleHash only allows hash refs for data') ;
				next ;
			}

			if ( grep ref $_, values %{$data} ) {

				ok( 1,
	    'skip SimpleHash only allows single level hashes for data') ;
				next ;
			}
		}

		my $msg = Stem::Msg->new(
			'to'	=> "client_$codec",
			'from'	=> $self->{'reg_name'},
			'type'	=> 'data',
			'data'	=> $data,
		) ;

#print $msg->dump("MSG OUT") ;
		$msg->dispatch() ;

		push( @{$self->{'sent_data'}}, $data ) ;
	}

	return ;
}

sub data_in {

	my( $self, $msg ) = @_ ;

#print $msg->dump( 'PACKET IN' ) ;

	my $recv_data = $msg->data() ;

	my $sent_data = shift @{$self->{'sent_data'}} ;

#print "SENT [$sent_data]\nGOT[$recv_data]\n" ;

	my $data_type = ref $sent_data || 'scalar' ;

	is_deeply( $recv_data, $sent_data, "$self->{'codec'} - $data_type " ) ;

	unless ( @{$self->{'sent_data'}} ) {

		$self->destroy_sock_msg_pair() ;
		$self->cell_flow_go_in() ;
	}
}

sub test_done {

	return 'FLOW_STOP' ;
}

sub codecs_left {

	my( $self ) = @_ ;

exit unless @codecs ;

#die "CODECS END" 

	return( $self->{codec} = shift @codecs ) ;
}

sub create_sock_msg_pair {

	my( $self ) = @_ ;

	my $codec = $self->{'codec'} ;

#print "CREATE [$codec]\n" ;

	my $server_name = "server_$codec" ;

	my $server_sock = Stem::SockMsg->new( 
		reg_name	=> $server_name,
		port		=> ++$self->{port},
		server		=> 1,
		cell_attr	=> [
			'data_addr'	=> 'echo',
			'codec'		=> $codec,
		],
	) ;

#print "SERVER [$server_sock]\n" ;
	die $server_sock unless ref $server_sock ;
	my $err = register_cell( $server_sock, $server_name ) ;
	$err and die "register error: $err" ;

	$self->{server_cell} = $server_sock ;
	$self->{server_name} = $server_name ;

	my $client_name = "client_$codec" ;

	my $client_sock = Stem::SockMsg->new( 
		reg_name	=> $client_name,
		port		=> $self->{port},
		connect_now	=> 1,
		sync		=> 1,
		cell_attr	=> [
			'data_addr'	=> 'packet_io',
			'codec'		=> $codec,
		],
	) ;
#print "CLIENT [$client_sock]\n" ;

	die $client_sock unless ref $client_sock ;
	register_cell( $client_sock, $client_name ) ;
	$self->{client_cell} = $client_sock ;
	$self->{client_name} = $client_name ;

	return ;
}

sub destroy_sock_msg_pair {

	my( $self ) = @_ ;

	my $codec = $self->{'codec'} ;

#print "DESTROY [$codec]\n" ;

	foreach my $type ( qw( server client ) ) {

		my $sock_msg = delete $self->{"${type}_cell"} ;
#		my $sock_msg = delete $self->{"${type}_$codec"} ;
		unregister_cell( $sock_msg ) ;
		$sock_msg->shut_down() ;
	}
}

1 ;
