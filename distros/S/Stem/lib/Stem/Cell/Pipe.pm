#  File: Stem/Cell/Pipe.pm

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

package Stem::Cell ;

use strict ;

sub _cell_pipe {

	my( $self ) = @_ ;

	if ( $self->{'args'}{'pipe_open'} ) {

		$self->{'piped'} = 1 ;

# return the connection handshake

		my $addr_msg = Stem::Msg->new(
			'cmd'		=> 'cell_pipe_addr',
			'to'		=> $self->{'args'}{'data_addr'},
			'from'		=> $self->{'from_addr'},
		) ;

		$addr_msg->dispatch() ;

		return ;
	}

	my $pipe_addr = $self->{'args'}{'pipe_addr'} || $self->{'pipe_addr'} ;

	return unless $pipe_addr ;

	$self->{'piped'} = 1 ;

# start the pipe connection handshake

	my $open_msg = Stem::Msg->new(
			'cmd'		=> 'cell_trigger',
			'to'		=> $pipe_addr,
			'from'		=> $self->{'from_addr'},
			'data'		=> {
				'args'		=> $self->{'pipe_args'},
				'pipe_open'	=> 1,
				'data_addr'	=> $self->{'from_addr'},
			},
	) ;

	$open_msg->dispatch() ;
}

# this command sub sets the data address at the end of a pipe handshake

sub cell_pipe_addr_cmd {

	my( $self, $msg ) = @_ ;

	my $cell_info = $self->_get_cell_info() ;

	$cell_info->{'data_addr'} = $msg->from() ;

	my $err = $cell_info->{'gather'}->gathered( 'data_addr' ) ;
	return $err if $err ;

	return ;
}

sub cell_pipe_close_cmd {

	my( $self, $msg ) = @_ ;

#print $msg->dump( 'PIPE' ) ;

#	TraceStatus "pipe closed cmd" ;

	my $cell_info = $self->_get_cell_info() ;

	$cell_info->{'close_cmd_seen'} = 1 ;

	my $data = $msg->data() ;

# see if we dump the errors to the output handle

	if ( $data && $cell_info->{'errors_to_output'} ) {

		$data = <<ERR ;
Cell::Pipe Error
$data
ERR
		$cell_info->_cell_write_sync( \$data ) ;
	}



	$self->cell_shut_down() ;

	return ;
}

sub _close_pipe {

	my( $self ) = @_ ;

	return if $self->{'close_cmd_seen'} ;

use Carp qw( cluck ) ;
#cluck() ;
#print $self->_dump( 'CLOSE PIPE' ) ;

	return unless $self->{'piped'} ;

#	TraceStatus "pipe closing" ;

	my $to_addr = $self->{'args'}{'data_addr'} ||
			$self->{'data_addr'} ;

	my $close_msg = Stem::Msg->new(
		'cmd'		=> 'cell_pipe_close',
		'to'		=> $to_addr,
		'from'		=> $self->{'from_addr'},
		'data'		=> $self->{'error'},
	) ;

#print $close_msg->dump( '_close PIPE' ) ;

	$close_msg->dispatch() ;
}

1 ;
