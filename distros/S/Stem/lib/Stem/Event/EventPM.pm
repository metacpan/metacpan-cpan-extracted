#  File: Stem/Event/EventPM.pm

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

#print "required" ;

=head1 Stem::Event::EventPM

This module wraps the CPAN module Event.pm for use by the rest of
Stem. It provides the common API for the standard Stem::Event classes:

=over 4

=item Stem::Event
=item Stem::Event::Plain
=item Stem::Event::Timer
=item Stem::Event::Signal
=item Stem::Event::Read
=item Stem::Event::Write

=back

=cut

package Stem::Event::EventPM ;

use strict ;
use Event ;

@Stem::Event::EventPM::ISA = qw( Stem::Event ) ;

# basic wrappers for top level Event.pm calls.

sub _start_loop {
	$Event::DIED = \&_died ;
	Event::loop() ;
}

sub _died {
	my( $event, $err ) = @_ ;
        use Carp;
	Carp::cluck( "Stem::Event died: $err", "die called in [$event]\n",
                     map( "<$_>", caller() ), "\n" ) ;

	exit;
} ;


sub _stop_loop {
	Event::unloop_all( 1 ) ;
}

############################################################################

package Stem::Event::Plain ;

sub _build {

	my( $self ) = @_ ;
	
# create the plain event watcher

	$self->{'idle_event'} = Event->idle(
		'cb'		=> [ $self, 'idle_triggered' ],
		'repeat'	=> 0
	) ;

	return $self ;
}

sub idle_triggered {

	my( $self ) = @_ ;

	$self->trigger( 'plain' ) ;
	my $idle_event = delete $self->{'idle_event'} ;
	$idle_event->cancel() ;
}

############################################################################

package Stem::Event::Signal ;

sub _build {

	my( $self ) = @_ ;

	my $signal = $self->{'signal'} ;

# create the signal event watcher

	return Event->signal(
		'cb'		=> sub { $self->trigger() },
		'signal'	=> $signal,
	) ;
}

sub _cancel {
	my( $self, $signal_event ) = @_ ;
	$signal_event->cancel() ;
	return ;
}

############################################################################

package Stem::Event::Timer ;

sub _build {

	my( $self ) = @_ ;

	return Event->timer(
		'cb'		=> [ $self, 'timer_triggered' ],
		'hard'		=> $self->{'hard'},
		'after'		=> $self->{'delay'},
		'interval'	=> $self->{'interval'},
	) ;
}

sub _reset {
	my( $self, $timer_event, $delay ) = @_ ;
	$timer_event->again() ;
	return ;
}

sub _cancel {
	my( $self, $timer_event ) = @_ ;
	$timer_event->cancel() ;
	return ;
}

sub _start {
	my( $self, $timer_event ) = @_ ;
	$timer_event->start() ;
	return ;
}

sub _stop {
	my( $self, $timer_event ) = @_ ;
	$timer_event->stop() ;
	return ;
}

############################################################################

package Stem::Event::Read ;

sub _build {

	my( $self ) = @_ ;

# create the read event watcher

	return Event->io(
		'cb'	=> sub { $self->trigger() },
		'fd'	=> $self->{'fh'},
		'poll'	=> 'r',
	) ;
}

sub _cancel {
	my( $self, $read_event ) = @_ ;
	$read_event->cancel() ;
	return ;
}

sub _start {
	my( $self, $read_event ) = @_ ;
	$read_event->start() ;
	return ;
}

sub _stop {
	my( $self, $read_event ) = @_ ;
	$read_event->stop() ;
	return ;
}

############################################################################

package Stem::Event::Write ;

sub _build {

	my( $self ) = @_ ;

# create the write event watcher

# create the read event watcher

	return Event->io(
		'cb'	=> sub { $self->trigger() },
		'fd'	=> $self->{'fh'},
		'poll'	=> 'w',
	) ;

	return $self ;
}

sub _cancel {
	my( $self, $write_event ) = @_ ;
	$write_event->cancel() ;
	return ;
}

sub _start {
	my( $self, $write_event ) = @_ ;
	$write_event->start() ;
	return ;
}

sub _stop {
	my( $self, $write_event ) = @_ ;
	$write_event->stop() ;
	return ;
}

1 ;
