#  File: Stem/Cell/Sequence.pm

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

sub cell_set_sequence {

	my( $self, @sequence ) = @_ ;

	my $cell_info = $self->_get_cell_info() ;

#print "@sequence\n" ;

	$cell_info->{'sequence'} = [ @sequence ] ;
	$cell_info->{'sequence_left'} = [ @sequence ] ;

	return ;
}


sub cell_reset_sequence {

	my( $self ) = @_ ;

	my $cell_info = $self->_get_cell_info() ;

	$cell_info->{'sequence_left'} = [ @{$cell_info->{'sequence'}} ] ;

	return ;
}

sub cell_replace_next_sequence {

        my( $self, $method ) = @_ ;

	my $cell_info = $self->_get_cell_info() ;

	$cell_info->{'sequence_left'}[0] = $method;

	return ;
}

#
# This method lets you basically set up loops.  For example, method X
# could insert itself as the next next method in the sequence.  Then,
# when it is called again it can decide whether or not to insert
# itself again.
#
# A more complex example might see method X might say "now execute Y,
# Z, M, and X", which allows you to create loops.  Then method Z might
# say "now execute Q and Z".
#
# Obviously, most loops will also need a break condition where method
# X decides _not_ to insert itself into the sequence.
#
sub cell_insert_next_sequence {

        my( $self, @sequence ) = @_ ;

	my $cell_info = $self->_get_cell_info() ;

	unshift @{ $cell_info->{'sequence_left'} }, @sequence;

	return ;
}

sub cell_skip_next_sequence {

        my( $self, $count ) = @_ ;

	$count ||= 1 ;

	my $cell_info = $self->_get_cell_info() ;

	shift @{ $cell_info->{'sequence_left'} } for 1..$count;

	return ;
}

sub cell_skip_until_method {

        my( $self, $method ) = @_ ;

	my $cell_info = $self->_get_cell_info() ;

	my $seq_left = $cell_info->{'sequence_left'} ;

	while( @{$seq_left} ) {

		return if $seq_left->[0] eq $method ;
		shift @{$seq_left} ;
	}

	die "skip sequence method $method is not found" ;
}


sub cell_next_sequence_in {

	my( $self, $msg ) = @_ ;

#print $msg->dump( "NEXT IN" ) if $msg ;

	my $cell_info = $self->_get_cell_info() ;

	$cell_info->cell_next_sequence( $msg ) ;
}

sub cell_next_sequence {

	my( $self, $in_msg ) = @_ ;

#print caller(), "\n" ;

#print $in_msg->dump('SEQ IN') if $in_msg ;

	my $cell_info = $self->_get_cell_info() ;

	my $owner_obj = $cell_info->{'owner_obj'} ;


	while( my $next_sequence = shift @{$cell_info->{'sequence_left'}} ) {

#print "LEFT @{$cell_info->{'sequence_left'}}\n" ;

		die "cannot call sequence method $next_sequence"
			unless $owner_obj->can( $next_sequence ) ;

#print "SEQ: $next_sequence\n" ;

		my $seq_val = $owner_obj->$next_sequence( $in_msg ) ;

# don't pass in the message more than once.

		$in_msg = undef ;

		next unless $seq_val ;

		if ( ref $seq_val eq 'Stem::Msg' ) {


#print caller() ;
#print $seq_val->dump( 'SEQ: MSG' ) ;
			$seq_val->reply_type( 'cell_next_sequence' ) ;

			$seq_val->dispatch() ;

			return ;
		}

		if ( ref $seq_val eq 'HASH' ) {

			my $delay = $seq_val->{'delay'} ;

			if ( defined( $delay ) ) {

				$cell_info->cell_sequence_delay( $delay ) ;
				return ;
			}
		}
	}

	if ( my $seq_done_method = $cell_info->{'sequence_done_method'} ) {

		$owner_obj->$seq_done_method() ;

		return ;
	}

#warn "FELL off end of sequence" ;

	return ;
}

sub cell_sequence_delay {

	my( $self, $delay ) = @_ ;

	my $cell_info = $self->_get_cell_info() ;

#print "SEQ DELAY $delay\n" ;

	$cell_info->{'timer'} = Stem::Event::Timer->new(
				'object'	=> $cell_info,
				'method'	=> 'cell_next_sequence',
				'delay'		=> $delay, 
				'hard'		=> 1,
				'single'	=> 1,
	) ;
}

1 ;
