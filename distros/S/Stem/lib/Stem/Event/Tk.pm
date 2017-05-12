#  File: Stem/Event/Tk.pm

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

=head1 Stem::Event::Tk

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

package Stem::Event::Tk ;

use strict ;
use Tk ;

use Stem::Event::Signal ;

my $tk_main_window ;

# basic wrappers for top level Tk.pm calls.

sub _init_loop {

	$tk_main_window ||= MainWindow->new() ;
	$tk_main_window->withdraw() ;
}

sub _start_loop {
	_init_loop() ;
	MainLoop() ;
}

sub _stop_loop {

#print "STOP INFO ", $tk_main_window->afterInfo(), "\n" ;

	$tk_main_window->destroy() ;
	$tk_main_window = undef ;
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

	$self->trigger() ;
	my $idle_event = delete $self->{'idle_event'} ;
	$idle_event->cancel() ;
}

############################################################################

package Stem::Event::Timer ;

sub _build {

	my( $self ) = @_ ;

Stem::Event::Tk::_init_loop() ;

# tk times in milliseconds and stem times in floating seconds so
# we convert to integer ms.

	my $delay_ms = int( $self->{'delay'} * 1000 ) ;

#	$self->{interval_ms} = int( ( $self->{'interval'} || 0 ) * 1000 ) ;

	my $timer_method = $self->{'interval'} ? 'repeat' : 'after' ;

	return $tk_main_window->$timer_method(
				$delay_ms,
				[$self => 'timer_triggered']
	) ;
}

sub _reset {

	my( $self, $timer_event, $delay ) = @_ ;
	my $delay_ms = int( $delay * 1000 ) ;
	$timer_event->time( $delay_ms ) ;
}

sub _cancel {
	my( $self, $timer_event ) = @_ ;
	$timer_event->cancel() ;
	return ;
}

############################################################################

package Stem::Event::Read ;

sub _build {

	my( $self ) = @_ ;
	goto &_start if $self->{active} ;
	return ;
}

sub _start {

	my( $self ) = @_ ;

	return $tk_main_window->fileevent(
		$self->{'fh'},
		'readable',
		[$self => 'trigger']
	) ;
}

sub _cancel { goto &_stop }

sub _stop {
	my( $self ) = @_ ;

	$tk_main_window->fileevent(
		$self->{'fh'},
		'readable',
		''
	) ;
}

############################################################################

package Stem::Event::Write ;

sub _build {
	my( $self ) = @_ ;
	goto &_start if $self->{active} ;
	return ;
}

sub _start {

	my( $self ) = @_ ;

	return $tk_main_window->fileevent(
		$self->{'fh'},
		'writable',
		[$self => 'trigger']
	) ;
}

sub _cancel { goto &_stop }

sub _stop {

	my( $self ) = @_ ;

	$tk_main_window->fileevent(
		$self->{'fh'},
		'writable',
		''
	) ;
}

1 ;
