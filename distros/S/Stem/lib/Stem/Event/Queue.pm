#  File: Stem/Event/Queue.pm

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

# this class provides a way to deliver certain events and messages
# synchronously with the main event loop. this is done by queueing the
# actual event/message and writing a byte down a special pipe used
# only inside this process. the other side of the pipe has a read
# event that when triggered will then deliver the queued
# events/messages.

# when using Stem::Event::Signal you need to use this module as
# well. perl signals will be delivered (safely) between perl
# operations but they could then be delivered inside an executing
# event handler and that means possible corruption. so this module
# allows those signal events to be delivered by the event loop itself.


package Stem::Event::Queue ;

use strict ;
use warnings ;

use Socket;
use IO::Handle ;

use base 'Exporter' ;
our @EXPORT = qw( &mark_not_empty ) ;

my( $queue_read, $queue_write, $queue_read_event ) ;

my $self ;

sub _init_queue {

	socketpair( $queue_read, $queue_write,
		 AF_UNIX, SOCK_STREAM, PF_UNSPEC ) || die <<DIE ;
can't create socketpair $!
DIE

#print fileno( $queue_read ), " FILENO\n" ;

	$self = bless {} ;

	$queue_read->blocking( 0 ) ;
	$queue_read_event = Stem::Event::Read->new(
		'object'	=> $self,
		'fh'		=> $queue_read,
	) ;

	ref $queue_read_event or die <<DIE ;
can't create Stem::Event::Queue read event: $queue_read_event
DIE

}

my $queue_is_marked ;

sub mark_not_empty {

	my( $always_mark ) = @_ ;

# don't mark the queue if it is already marked and we aren't forced
# the signal queue always marks the queue

	return if $queue_is_marked && !$always_mark ;

	syswrite( $queue_write, 'x' ) ;

	$queue_is_marked = 1 ;
}

sub readable {

	sysread( $queue_read, my $buf, 10 ) ;

	$queue_is_marked = 0 ;

#	Stem::Event::Plain::process_queue();
	Stem::Event::Signal::process_signal_queue();
#	Stem::Msg::process_queue() if defined &Stem::Msg::process_queue;

	return ;
}

1 ;
