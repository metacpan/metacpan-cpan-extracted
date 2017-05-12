#  File: Stem/TtySock.pm

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

package Stem::TtySock ;

use strict ;
use Carp ;

use Stem::AsyncIO ;
#use Debug ;

my $attr_spec = [
	{
		'name'		=> 'port',
		'default'	=> 10_000,
		'env'		=> 'tty_port',
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'host',
		'default'	=> 'localhost',
		'env'		=> 'tty_host',
		'help'		=> <<HELP,
HELP
	},

] ;

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

	my $aio = Stem::AsyncIO->new(

			'object'	=> $self,
			'read_fh'	=> \*STDIN,
			'write_fh'	=> \*STDOUT,
			'read_method'	=> 'stdin_read',
			'closed_method'	=> 'stdin_closed',
	) ;

	$self->{'aio'} = $aio ;

	my $sock_obj = Stem::Socket->new( 
				'object'	=> $self,
				'host'		=> $self->{'host'},
				'port'		=> $self->{'port'},
				'server'	=> $self->{'server'},
	) ;

	$self->{'sock_obj'} = $sock_obj ;

#Debug "TTYSock new" ;

	return( $self ) ;
}


sub connected {

	my( $self, $connected_sock ) = @_ ;

	my( $type, $sock_buf ) ;


	$self->{'connected'} = 1 ;
	$self->{'sock'} = $connected_sock ;

	$type = $self->{'sock_obj'}->type() ;

	if ( $type eq 'server' ) {

		$self->{'sock_obj'}->stop_listening() ;
	}

	$sock_buf = Stem::AsyncIO->new(

			'object'	=> $self,
			'fh'		=> $connected_sock,
			'read_method'	=> 'socket_read',
			'closed_method'	=> 'socket_closed',
	) ;

	$self->{'sock_buf'} = $sock_buf ;
}

sub socket_read {

	my( $self, $data_ref ) = @_ ;

	$self->{'aio'}->write( $data_ref ) ;
}

sub socket_closed {

	my( $self ) = @_ ;

	$self->{'connected'} = 0 ;

	$self->{'sock_buf'}->shut_down() ;

	if ( $self->{'sock_obj'}->type() eq 'server' ) {

		$self->{'sock_obj'}->start_listening() ;
	}
	else {

		$self->{'sock_obj'}->connect_to() ;
	}
}

sub stdin_read {

	my( $self, $data_ref ) = @_ ;

	unless ( $self->{'connected'} ) {

		print "TTY::Sock not connected\n" ;
		return ;
	}

	$self->{'sock_buf'}->write( $data_ref ) ;
}

sub stdin_closed {

	my( $self ) = @_ ;


#	print "stdin closed\n" ;

	*STDIN->clearerr() ;
}


1 ;
