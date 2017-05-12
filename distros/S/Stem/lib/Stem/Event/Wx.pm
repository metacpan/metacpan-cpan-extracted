#  File: Stem/Event/Wx.pm

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

=head1 Stem::Event::Wx

This module is a pure Perl event loop. It requires Perl 5.8 (or
better) which has safe signal handling.  It provides the common event
API for the standard classes:

=cut

package Stem::Event::Wx ;

use strict ;

use base qw( Stem::Event ) ;
use Stem::Event::Perl ;
use Wx ;

my $app = Stem::Event::Wx::App->new() ;
my $wx_timer = Stem::Event::Wx::Timer->new() ;

# this will call the io_poll_timer method in $wx_timer's class

my $io_poll_timer = Stem::Event::Timer->new(
	object		=> $wx_timer,
	interval	=> 1,			# .1 second poll
	method		=> 'io_poll_timer',
) ;

sub _start_loop {

# _build just sets the min delay for the wx timer. this will make sure
# any timer events get going when we start the loop.

	Stem::Event::Timer::_build() ;
	Wx::wxTheApp->MainLoop() ;
}

sub _stop_loop {

	Wx::wxTheApp->ExitMainLoop() ;
}


package Stem::Event::Timer ;

sub _build {

	my $min_delay = Stem::Event::Perl::find_min_delay() ;
	$wx_timer->set_wx_timer_delay( $min_delay ) ;
	return ;
}

############################################################################

# this class subclasses Wx::Timer and its Notify method will be called
# after the current delay.

package Stem::Event::Wx::Timer ;

use base qw( Wx::Timer ) ;

BEGIN {

	unless ( eval { require Time::HiRes } ) {

		Time::HiRes->import( qw( time ) ) ;
	}
}

my $last_time ;

sub set_wx_timer_delay {

	my( $self, $delay ) = @_ ;

#print "WX DELAY [$delay]\n" ;
	if ( $delay ) {

		$self->Start( int( $delay * 1000 ), 0 );
		$last_time = time() ;
		return ;
	}

	$self->Stop();
}

# Wx calls this method when its timers get triggered. this is the only
# wx timer callback in this wrapper. all the others are handled with
# perl in Event.pm and Event/Perl.pm

sub Notify {

#print "NOTIFY\n" ;
	my $delta_time = time() - $last_time ;
	my $min_delay = Stem::Event::Perl::find_min_delay() ;
	$wx_timer->set_wx_timer_delay( $min_delay ) ;
	Stem::Event::Perl::trigger_timer_events( $delta_time ) ;
}

sub io_poll_timer {

#print "IO POLL\n" ;

	Stem::Event::Perl::_one_time_loop() ;
}


############################################################################

# this class is needed to subclass Wx::App and to make our own
# WxApp. it needs to provide OnInit which is called at startup and has
# to return true.

package Stem::Event::Wx::App ;

use base 'Wx::App' ;
sub OnInit { return( 1 ) }

1 ;

__END__
