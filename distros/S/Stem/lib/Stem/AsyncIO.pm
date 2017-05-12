#  File: Stem/AsyncIO.pm

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

package Stem::AsyncIO ;

use strict ;
use Data::Dumper ;

use Stem::Vars ;


my $attr_spec = [

	{
		'name'		=> 'object',
		'required'	=> 1,
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'read_method',
		'default'	=> 'async_read_data',
		'help'		=> <<HELP,
Method called with the data read from the read handle. It is only called if the	
data_addr attribute is not set.
HELP
	},

	{
		'name'		=> 'stderr_method',
		'default'	=> 'async_stderr_data',
		'help'		=> <<HELP,
Method called with the data read from the stderr handle. It is only
called if the stderr_addr attribute is not set.
HELP
	},

	{
		'name'		=> 'closed_method',
		'default'	=> 'async_closed',
		'help'		=> <<HELP,
Method used when this object is closed.
HELP
	},
	{
		'name'		=> 'fh',
		'help'		=> <<HELP,
File handle used for reading and writing.
HELP
	},
	{
		'name'		=> 'read_fh',
		'help'		=> <<HELP,
File Handle used for reading.
HELP
	},
	{
		'name'		=> 'write_fh',
		'help'		=> <<HELP,
File handle used for standard output.
HELP
	},
	{
		'name'		=> 'stderr_fh',
		'help'		=> <<HELP,
File handle used for Standard Error.
HELP
	},
	{
		'name'		=> 'data_addr',
		'type'		=> 'address',
		'help'		=> <<HELP,
The address of the Cell where the data is sent.
HELP
	},
	{
		'name'		=> 'stderr_addr',
		'type'		=> 'address',
		'help'		=> <<HELP,
The address of the Cell where the stderr is sent.
HELP
	},
	{
		'name'		=> 'data_msg_type',
		'default'	=> 'data',
		'help'		=> <<HELP,
This sets the type of the data message.
HELP
	},
	{
		'name'		=> 'codec',
		'help'		=> <<HELP,
Use this codec to encode/decode the I/O data. Each write is encoded to
one packet out. Each packet read in will be decoded and either send a
data message or generate a callback.
HELP
	},
	{
		'name'		=> 'stderr_msg_type',
		'default'	=> 'stderr_data',
		'help'		=> <<HELP,
This sets the type of the stderr data message.
HELP
	},
	{
		'name'		=> 'from_addr',
		'type'		=> 'address',
		'help'		=> <<HELP,
The address used in the 'from' field of data and stderr messages.
HELP
	},
	{
		'name'		=> 'send_data_on_close',
		'type'		=> 'boolean',
		'help'		=> <<HELP,
Buffer all read data and send it when the read handle is closed.
HELP
	},
	{
		'name'		=> 'id',
		'help'		=> <<HELP,
The id is passed to the callback method as its only argument. Use it to
identify different instances of this object.
HELP

	},

################
## add support to log all AIO
################

	{
		'name'		=> 'log_label',
		'default'	=> 'AIO',
		'help'		=> <<HELP,
HELP
	},
	{
		'name'		=> 'log_level',
		'default'	=> 5,
		'help'		=> <<HELP,
HELP
	},
	{
		'name'		=> 'read_log',
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'stderr_log',
		'help'		=> <<HELP,
HELP
	},

	{
		'name'		=> 'write_log',
		'help'		=> <<HELP,
HELP
	},


] ;

use Carp 'cluck' ;

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

#cluck "NEW $self" ;

	if ( $self->{'data_addr'} && ! $self->{'from_addr'} ) {

		return "Using 'data_addr in AsyncIO requires a 'from_addr'" ;
	}

	if ( my $codec = $self->{'codec'} ) {

		require Stem::Packet ;
		my $packet = Stem::Packet->new( 'codec' => $codec ) ;
		return $packet unless ref $packet ;

		$self->{'packet'} = $packet ;
	}

	$self->{'stderr_addr'} ||= $self->{'data_addr'} ;

	$self->{'buffer'} = '' if $self->{'send_data_on_close'} ;

	$self->{ 'read_fh' } ||= $self->{ 'fh' } ;
	$self->{ 'write_fh' } ||= $self->{ 'fh' } ;

	if ( my $read_fh = $self->{'read_fh'} ) {

		my $read_event = Stem::Event::Read->new(
					'object'	=> $self,
					'fh'		=> $read_fh,
		) ;

		return $read_event unless ref $read_event ;

		$self->{'read_event'} = $read_event ;
	}

	if ( my $stderr_fh = $self->{'stderr_fh'} ) {

		my $stderr_event = Stem::Event::Read->new(
					'object'	=> $self,
					'fh'		=> $stderr_fh,
					'method'	=> 'stderr_readable',
		) ;

		return $stderr_event unless ref $stderr_event ;

		$self->{'stderr_event'} = $stderr_event ;
	}

	if ( my $write_fh = $self->{'write_fh'} ) {

		my $write_event = Stem::Event::Write->new(
					'object'	=> $self,
					'fh'		=> $write_fh,
		) ;

		return $write_event unless ref $write_event ;

		$self->{'write_event'} = $write_event ;

		$self->{'write_buf'} = '' ;
	}

	return $self ;
}

sub shut_down {

	my( $self ) = @_ ;

#cluck "SHUT $self\n" ;


	if ( $self->{'shut_down'} ) {

		return ;
	}

	$self->{'shutting_down'} = 1 ;

	$self->read_shut_down() ;

	$self->write_shut_down() ;

	if ( my $event = delete $self->{'stderr_event'} ) {

		$event->cancel() ;
		close( $self->{'stderr_fh'} ) ;
	}

	$self->{'shut_down'} = 1 ;

#print "DELETE OBJ", caller(), "\n" ;

	delete $self->{'object'} ;
}

sub read_shut_down {

	my( $self ) = @_ ;

	if ( my $event = delete $self->{'read_event'} ) {

		$event->cancel() ;
	}

	shutdown( $self->{'read_fh'}, 0 ) ;
}

sub write_shut_down {

	my( $self ) = @_ ;

	if ( exists( $self->{'write_buf'} ) && 
	     length( $self->{'write_buf'} ) ) {

#print "write handle shut when empty\n" ;
		$self->{'shut_down_when_empty'} = 1 ;

		return ;
	}

	if ( my $event = delete $self->{'write_event'} ) {

		shutdown( $self->{'write_fh'}, 1 ) ;
		$event->cancel() ;
	}
}

sub readable {

	my( $self ) = @_ ;

	my( $read_buf ) ;

	return if $self->{'shut_down'} ;

	my $bytes_read = sysread( $self->{'read_fh'}, $read_buf, 8192 ) ;

#print "READ: $bytes_read [$read_buf]\n" ;

	unless( defined( $bytes_read ) && $bytes_read > 0 ) {

		$self->read_shut_down() ;

		if ( $self->{'send_data_on_close'} &&
		     length( $self->{'buffer'} ) ) {

			$self->send_data() ;

# since we sent the total read buffer, we don't do a closed callback.

			return ;
		}

		$self->_callback( 'closed_method' ) ;

		return ;
	}

# decode the packet if needed

	if ( my $packet = $self->{packet} ) {

		my $buf_ref = \$read_buf ;

		while( my $data_ref = $packet->to_data( $buf_ref ) ) {

			$self->send_data( $data_ref ) ;
			$buf_ref = undef ;
		}

		return ;
	}

	if ( $self->{'send_data_on_close'} ) {

		$self->{'buffer'} .= $read_buf ;
		return ;
	}

	$self->send_data( \$read_buf ) ;
}

sub send_data {

	my( $self, $buffer ) = @_ ;

	my $buf_ref = $buffer || \$self->{'buffer'} ;

	$self->_send_data_msg( 'data_addr', 'data_msg_type', $buf_ref ) ;
	$self->_callback( 'read_method', $buf_ref ) ;

	return ;
}

sub stderr_readable {

	my( $self ) = @_ ;

	my( $read_buf ) ;

	my $bytes_read = sysread( $self->{'stderr_fh'}, $read_buf, 8192 ) ;

# no callback on stderr close. let the read handle close deal with the
# shutdown

	return if $bytes_read == 0 ;

#print "STDERR READ [$read_buf]\n" ;

	$self->_send_data_msg( 'stderr_addr', 'stderr_msg_type', \$read_buf ) ;
	$self->_callback( 'stderr_method', \$read_buf ) ;
}

sub _send_data_msg {

	my( $self, $addr_attr, $type_attr, $data_ref ) = @_ ;

	my $to_addr = $self->{$addr_attr} or return ;

	my $msg = Stem::Msg->new(
			'to'		=> $to_addr,
			'from'		=> $self->{'from_addr'},
			'type'		=> $self->{$type_attr},
			'data'		=> $data_ref,
	) ;

#print $msg->dump( 'SEND DATA' ) ;
	$msg->dispatch() ;
}

sub _callback {

	my ( $self, $method_attr, @data ) = @_ ;

	my $obj = $self->{'object'} or return ;

	my $method = $self->{$method_attr} ;

	my $code = $obj->can( $method ) or return ;

	return $obj->$code( @data, $self->{'id'} ) ;
}

sub write {

	my( $self ) = shift ;

	return unless @_ ;

	return unless exists( $self->{'write_buf'} ) ;

	my $buffer = shift ;

	return if $self->{'shut_down'} ;

# encode the data in a packet if needed

	if ( my $packet = $self->{packet} ) {

		my $buf_ref = $packet->to_packet( $buffer ) ;

		$self->{'write_buf'} .= ${$buf_ref} ;
	}
	else {

		$self->{'write_buf'} .= ref $buffer eq 'SCALAR' ?
			${$buffer} : $buffer ;
	}

	$self->{'write_event'}->start() ;
}

sub final_write {

	my( $self ) = @_ ;

	$self->write( $_[1] ) ;

	$self->write_shut_down() ;
}


sub writeable {

	my( $self ) = @_ ;

	return if $self->{'shut_down'} ;

	my $buf_ref = \$self->{'write_buf'} ;
	my $buf_len = length $$buf_ref ;

#print "BUFLEN [$buf_len]\n" ;

	unless ( $buf_len ) {

#print "AIO W STOPPING\n" ;
		$self->{'write_event'}->stop() ;
		return ;
	}

	my $bytes_written = syswrite( $self->{'write_fh'}, $$buf_ref ) ;

	unless( defined( $bytes_written ) ) {

# do a SHUTDOWN
		return ;
	}

# remove the part of the buffer that was written 

	substr( $$buf_ref, 0, $bytes_written, '' ) ;

	return if length( $$buf_ref ) ;

	$self->write_shut_down() if $self->{'shut_down_when_empty'} ;
}


# DESTROY {

# 	my( $self ) = @_  ;

# print "DESTROY $self\n" ;

# }

1 ;
