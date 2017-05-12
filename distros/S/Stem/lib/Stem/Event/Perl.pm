#  File: Stem/Event/Perl.pm

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

=head1 Stem::Event::Perl

This module is a pure Perl event loop. It requires Perl 5.8 (or
better) which has safe signal handling.  It provides the common event
API for the standard classes:

=cut

package Stem::Event::Perl ;

use strict ;
use Stem::Event::Signal ;

@Stem::Event::Perl::ISA = qw( Stem::Event ) ;

BEGIN {

	unless ( eval { require Time::HiRes } ) {

		Time::HiRes->import( qw( time ) ) ;
	}
}

# get the hashes for each of the event types

my ( $signal_events, $timer_events, $read_events, $write_events ) =
	map scalar( Stem::Event::_get_events( $_ )), qw( signal timer
	read write ) ;

sub _start_loop {

#print "PERL START\n" ;

	while( keys %{$timer_events}  ||
	       keys %{$signal_events} ||
	       keys %{$read_events}   ||
	       keys %{$write_events} ) {

		my $timeout = find_min_delay() ;

#print "TIMEOUT [$timeout]\n" ;

		my $time = time() ;

		_one_time_loop( $timeout ) ;

		my $delta_time = time() - $time ;
		trigger_timer_events( $delta_time ) ;
	}
}

sub _one_time_loop {

	my( $timeout ) = @_ ;

# force a no wait select call if no timeout was passed in

	$timeout ||= 0 ;

#print "ONE TIME $timeout\n" ;
# use Carp qw( cluck ) ;
# cluck ;

# print "\n\n********EVENT LOOP\n\n" ;
# print "READ EVENTS\n", map $_->dump(), values %{$read_events} ;
# print "WRITE EVENTS\n", map $_->dump(), values %{$write_events} ;

	my $read_vec = make_select_vec( $read_events ) ;
	my $write_vec = make_select_vec( $write_events ) ;

#print "R BEFORE ", unpack( 'b*', $read_vec), "\n" ;
#print "W BEFORE ", unpack( 'b*', $write_vec), "\n" ;


	my $cnt = select( $read_vec, $write_vec, undef, $timeout ) ;

#print "SEL CNT [$cnt]\n" ;
#print "R AFTER ", unpack( 'b*', $read_vec), "\n" ;
#print "W AFTER ", unpack( 'b*', $write_vec), "\n" ;

	trigger_select_vec( 'read',  $read_events, $read_vec ) ;
	trigger_select_vec( 'write', $write_events, $write_vec,  ) ;

#print "\n\n********END EVENT LOOP\n\n" ;

}

sub _stop_loop {

	$_->cancel() for values %{$signal_events},
			 values %{$timer_events},
			 values %{$read_events},
			 values %{$write_events} ;
}

sub find_min_delay {

	my $min_delay = 0 ;

	while( my( undef, $event ) = each %{$timer_events} ) {

		if ( $event->{'time_left'} < $min_delay || $min_delay == 0 ) {

			$min_delay = $event->{'time_left'} ;

#print "MIN [$min_delay]\n" ;
		}
	}

	return unless $min_delay ;

	return $min_delay ;
}

sub trigger_timer_events {

	my( $delta ) = @_ ;

#print "TIMER DELTA $delta\n" ;

	while( my( undef, $event ) = each %{$timer_events} ) {

#print $event->dump() ;

		next unless $event->{'active'} ;

		next unless ( $event->{'time_left'} -= $delta ) <= 0 ;

		$event->timer_triggered() ;
	}
}

sub make_select_vec {

	my( $io_events ) = @_ ;

	my $select_vec = '' ;

	while( my( undef, $event ) = each %{$io_events} ) {

#print "make F: [", fileno $event->{'fh'}, "] ACT [$event->{'active'}]\n" ;

		unless ( defined fileno $event->{'fh'} ) {

#print "BAD FH $event->{'fh'}\n" ;
print "\n\n***EVENT BAD FH\n", $event->dump() ;

			$event->cancel() ;
		}

		next unless $event->{'active'} ;
		vec( $select_vec, fileno $event->{'fh'}, 1 ) = 1 ;
	}

	return $select_vec ;
}

sub trigger_select_vec {

	my( $event_type, $io_events, $select_vec ) = @_ ;

	while( my( undef, $event ) = each %{$io_events} ) {

		next unless $event->{'active'} ;
		if ( vec( $select_vec, fileno $event->{'fh'}, 1 ) ) {

			$event->trigger() ;
		}
	}

	return ;
}

############################################################################

package Stem::Event::Plain ;

######
# right now we trigger plain events when they are created. this should
# change to a queue and trigger after i/o and timer events
######

sub _build {
	my( $self ) = @_ ;
	$self->trigger() ;
	return ;
}

1 ;
