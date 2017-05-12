#  File: Stem/Event.pm

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

# this is the base class for all of the other event classes. it
# provides common services and also stubs for the internal _methods so
# the other classes don't need to declare them if they don't use them.

package Stem::Event ;

use Stem::Class ;

use strict ;

# this will hold the hashes of events for each event type.

my %all_events = (

	plain	=> {},
	signal	=> {},
	timer	=> {},
	read	=> {},
	write	=> {},
) ;

# table of loop types to the Stem::Event::* class name

my %loop_to_class = (

	event	=> 'EventPM',
	perl	=> 'Perl',
	tk	=> 'Tk',
	wx	=> 'Wx',
#	gtk	=> 'Gtk',
#	qt	=> 'Qt',
) ;

# use the requested event loop and default to perl on windows and
# event.pm elsewhere.

my $loop_class = _get_loop_class() ;

init_loop() ;


sub init_loop {

	$loop_class->_init_loop() ;

Stem::Event::Queue::_init_queue() if defined &Stem::Event::Queue::_init_queue ;

}

sub start_loop {

	$loop_class->_start_loop() ;
}

sub stop_loop {

	$loop_class->_stop_loop() ;
}

sub trigger {

	my( $self, $method ) = @_ ;

# never trigger inactive events

	return unless $self->{active} ;


	$method ||= $self->{'method'} ;
#print "METHOD [$method]\n" ;

	$self->{'object'}->$method( $self->{'id'} ) ;

	Stem::Msg::process_queue() if defined &Stem::Msg::process_queue;

	return ;
}

#################
# all the stuff below is a rough cell call trace thing. it needs work
# it would be put inside the trigger method
# 'log_type' attribute is set or the event type is used.
#_init subs need to set event_log_type in the object
#use Stem::Trace 'log' => 'stem_status', 'sub' => 'TraceStatus' ;
#use Stem::Trace 'log' => 'stem_error' , 'sub' => 'TraceError' ;
#	$log_type = $self->{'log_type'} || $self->{'event_type'} ;
#	TraceStatus "[$log_type] [$object] [$method]\n" ;
#	$Stem::Event::current_object = $object ;
#	my ( $cell_name, $target ) = Stem::Route::lookup_cell_name( $object ) ;
# 	if ( $cell_name ) {
# #		Debug 
# #		    "EVENT $event to $cell_name:$target [$object] [$method]\n" ;
# 	}
# 	else {
# #		Debug "EVENT $event to [$object] [$method]\n" ;
# 	}
#################


# get all the event objects for an event type
# this is a class sub.

sub _get_events {

	my( $event_type ) = @_ ;

	my $events = $all_events{ $event_type } ;

	return unless $events ;

	return values %{$events} if wantarray ;

	return $events ;
}

# initialize the subclass object for this event and store generic event
# info.

sub _build_core_event {

#print "BAZ\n" ;

	my( $self, $event_type ) = @_ ;


#print "EVT [$self] [$event_type]\n" ;

# call and and check the return of the core event constructor

	if ( my $core_event = $self->_build() ) {

# return the error if it was an error string

		return $core_event unless ref $core_event ;

# save the core event

		$self->{core_event} = $core_event ;
	}
	
# mark the event type and track it

	$self->{event_type} = $event_type ;
	$all_events{ $event_type }{ $self } = $self ;

	return ;
}

# these are the public versions of the support methods.
# subclasses can provide a _method to override the stub ones in this class.

sub cancel {

	my( $self ) = @_ ;

	$self->{'active'} = 0 ;
	delete $self->{'object'} ;

# delete the core object

	if ( my $core_event = delete $self->{core_event} ) {

	# call the core cancel

		$self->_cancel( $core_event ) ;
	}

# delete this event from the tracking hash

	delete $all_events{ $self->{event_type} }{ $self } ;

	return ;
}

sub start {
	my( $self ) = @_ ;

	$self->{'active'} = 1 ;
	$self->_start( $self->{core_event} ) ;

	return ;
}

sub stop {
	my( $self ) = @_ ;

	$self->{'active'} = 0 ;
	$self->_stop( $self->{core_event} ) ;

	return ;
}

# stubs for the internal methods that subclasses should override if needed.

sub _init_loop {}
sub _build {}
sub _start {}
sub _stop {}
sub _reset {}
sub _cancel {}

use Stem::Debug qw( dump_socket dump_owner dump_data ) ;

sub dump_events {

	print dump_data( \%all_events ) ;
}

sub dump {

	my( $self ) = @_ ;

	my $event_text = <<TEXT ;
EV:	$self
ACT:	$self->{'active'}
TEXT

	my $obj_dump = dump_owner $self->{'object'} ;
	$event_text .= <<TEXT ;
OBJ:	$obj_dump
METH:	$self->{'method'}
TEXT

	if ( my $fh = $self->{'fh'} ) {

		my $fh_text = dump_socket( $self->{'fh'} ) ;
		$event_text .= <<TEXT ;
FH:	$fh_text
TEXT
	}

	if ( $self->{event_type} eq 'timer' ) {

		my $delay = $self->{delay} || 'NONE' ;
		my $interval = $self->{interval} || 'NONE' ;
		$event_text .= <<TEXT ;
DELAY:	$delay
INT:	$interval
TEXT
	}

	if ( my $io_timer_event = $self->{'io_timer_event'} ) {

		$event_text = "IO TIMER: >>>>>\n" . $io_timer_event->dump() .
				"END\n";
	}

	return <<DUMP ;

>>>
$event_text<<<

DUMP

}

#############
# change this to a cleaner loop style which can handle more event loops and 
# try them in sequence
#############

sub _get_loop_class {

	my $loop_type = $Stem::Vars::Env{ 'event_loop' } ||
			($^O =~ /win32/i ? 'perl' : 'event' );

	$loop_type = 'perl' unless $loop_to_class{ $loop_type } ;
	my $loop_class = "Stem::Event::$loop_to_class{ $loop_type }" ;

	unless ( eval "require $loop_class" ) {
		die "can't load $loop_class: $@" if $@ && $@ !~ /locate/ ;

		$loop_type = 'perl' ;
		eval { require Stem::Event::Perl } ;
		die "can't load event loop Stem::Event::Perl $@" if $@ ;
	}

	# save the event loop that we loaded.

	#print "using event loop [$loop_type]\n" ;
	$Stem::Vars::Env{ 'event_loop' } = $loop_type ;

	return $loop_class ;
}


############################################################################

package Stem::Event::Plain ;

BEGIN {
	@Stem::Event::Plain::ISA = qw( Stem::Event ) ;
}

=head2 Stem::Event::Plain::new

This class creates an event that will trigger a callback after all
other pending events have been triggered.

=head2 Example

	$plain_event = Stem::Event::Plain->new( 'object' => $self ) ;

=cut

my $attr_spec_plain = [

	{
		'name'		=> 'object',
		'required'	=> 1,
		'type'		=> 'object',
		'help'		=> <<HELP,
This object gets the method callbacks
HELP
	},
	{
		'name'		=> 'method',
		'default'	=> 'triggered',
		'help'		=> <<HELP,
This method is called on the object when the plain event is triggered
HELP
	},
	{
		'name'		=> 'id',
		'help'		=> <<HELP,
The id is passed to the callback method as its only argument. Use it to
identify different instances of this object.
HELP

	},
] ;

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec_plain, @_ ) ;
	return $self unless ref $self ;

	my $err = $self->_core_event_build( 'plain' ) ;
	return $err if $err ;

	return $self ;
}

############################################################################

package Stem::Event::Signal ;

BEGIN { our @ISA = qw( Stem::Event ) } ;

=head2 Stem::Event::Signal::new

This class creates an event that will trigger a callback whenever
its its signal has been received.  

=head2 Example

	$signal_event = Stem::Event::Signal->new( 'object' => $self,
						  'signal' => 'INT' ) ;

	sub sig_int_handler { die "SIGINT\n" }

=cut

my $attr_spec_signal = [

	{
		'name'		=> 'object',
		'required'	=> 1,
		'type'		=> 'object',
		'help'		=> <<HELP,
This object gets the method callbacks
HELP
	},
	{
		'name'		=> 'method',
		'help'		=> <<HELP,
This method is called on the object when this event is triggered. The
default method name for the signal NAME is 'sig_name_handler' (all lower case)
HELP
	},
	{
		'name'		=> 'signal',
		'required'	=> 1,
		'help'		=> <<HELP,
This is the name of the signal to handle. It is used as part of the
default handler method name.
HELP
	},
	{
		'name'		=> 'active',
		'default'	=> 1,
		'type'		=> 'boolean',
		'help'		=> <<HELP,
This flag marks the event as being active. It can be toggled with the
start/stop methods.
HELP
	},
	{
		'name'		=> 'id',
		'help'		=> <<HELP,
The id is passed to the callback method as its only argument. Use it to
identify different instances of this object.
HELP

	},
] ;

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec_signal, @_ ) ;
	return $self unless ref $self ;

	my $signal = uc $self->{'signal'} ;

	return "Unknown signal: $signal" unless exists $SIG{ $signal } ;

	$self->{'method'} ||= "sig_\L${signal}_handler" ;
	$self->{'signal'} = $signal ;

	my $err = $self->_build_core_event( 'signal' ) ;
	return $err if $err ;

#print "SELF SIG $self\nPID $$\n" ;

	return $self ;
}


############################################################################

package Stem::Event::Timer ;

BEGIN { our @ISA = qw( Stem::Event ) } ;

=head2 Stem::Event::Timer::new

This class creates an event that will trigger a callback after a time
period has elapsed. The initial timer delay is set from the 'delay',
'at' or 'interval' attributes in that order. If the 'interval'
attribute is not set, the timer will cancel itself after its first
triggering (it is a one-shot). The 'hard' attribute means that the
next interval delay starts before the callback to the object is
made. If a soft timer is selected (hard is 0), the delay starts after
the callback returns. So the hard timer ignores the time taken by the
callback and so it is a more accurate timer. The accuracy a soft timer
is affected by how much time the callback takes.

=head2 Example

	$timer_event = Stem::Event::Timer->new( 'object' => $self,
						'delay'  => 5,
						'interval'  => 10 ) ;

	sub timed_out { print "timer alert\n" } ;


=cut

BEGIN {

my $attr_spec_timer = [

	{
		'name'		=> 'object',
		'required'	=> 1,
		'type'		=> 'object',
		'help'		=> <<HELP,
This object gets the method callbacks
HELP
	},
	{
		'name'		=> 'method',
		'default'	=> 'timed_out',
		'help'		=> <<HELP,
This method is called on the object when the timeout is triggered
HELP
	},
	{
		'name'		=> 'delay',
		'help'		=> <<HELP,
Delay this amount of seconds before triggering the first time. If this
is not set then the 'at' or 'interval' attributes will be used.
HELP
	},
	{
		'name'		=> 'interval',
		'help'		=> <<HELP,
Wait this time (in seconds) before any repeated triggers. If not set
then the timer is a one-shot
HELP
	},
	{
		'name'		=> 'at',
		'help'		=> <<HELP,
Trigger in the future at this time (in epoch seconds). It will set the intial 
delay to the different between the current time and the 'at' time.
HELP
	},
	{
		'name'		=> 'hard',
		'type'		=> 'boolean',
		'default'	=> 0,
		'help'		=> <<HELP,
If this is set, the interval time starts when the event is
triggered. If it is not set, the interval time starts when the object
callback has finished. So 'hard' timers repeat closer to equal
intervals while without 'hard' the repeat time is dependant on how
long the callback takes.
HELP
	},
	{
		'name'		=> 'active',
		'default'	=> 1,
		'type'		=> 'boolean',
		'help'		=> <<HELP,
This flag marks the event as being active. It can be toggled with the
start/stop methods.
HELP
	},
	{
		'name'		=> 'id',
		'help'		=> <<HELP,
The id is passed to the callback method as its only argument. Use it to
identify different instances of this object.
HELP

	},
] ;

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec_timer, @_ ) ;
	return $self unless ref $self ;

# the delay is either set, or at a future time or the interval

	my $delay = exists( $self->{ 'delay' } ) ?
			$self->{ 'delay' } :
			exists( $self->{ 'at' } ) ?
				$self->{ 'at' } - time() :
				$self->{'interval'} ;

#print "INT $self->{'interval'} DELAY $delay\n" ;

# squawk if no delay value

	return "No initial delay was specified for timer"
		unless defined $delay ;

	$self->{'delay'} = $delay ;
	$self->{'time_left'} = $delay ;

	my $err = $self->_build_core_event( 'timer' ) ;
	return $err if $err ;

##########
# check on this logic
#########

	$self->_stop unless $self->{'active'} ;

	return $self ;
}

}

sub reset {

	my( $self, $reset_delay ) = @_ ;

	return unless $self->{'active'} ;

# if we don't get passed a delay, use the interval or the delay attribute

	$reset_delay ||= ($self->{'interval'}) ?
			$self->{'interval'} : $self->{'delay'} ;

# track the new delay and reset the real timer (if we are using one)

	$self->{'time_left'} = $reset_delay ;

	$self->_reset( $self->{core_event}, $reset_delay ) ;

	return ;
}

sub timer_triggered {

	my( $self ) = @_ ;

#print time(), " TIMER TRIG\n" ;
#use Carp qw( cluck ) ;
#cluck ;

# check if this is a one-shot timer

	$self->cancel() unless $self->{'interval'} ;

# reset the timer count before the trigger code for hard timers
#(trigger on fixed intervals)

	$self->reset( $self->{'interval'} ) if $self->{'hard'};

	$self->trigger() ;

# reset the timer count before the trigger code for soft timers
#(trigger on at least fixed intervals)

	$self->reset( $self->{'interval'} ) unless $self->{'hard'};
}

############################################################################

####################################################################
# common methods for the Read/Write event classes to handle the optional
# I/O timeouts.
# these override Stem::Event's methods and then call those via SUPER::

package Stem::Event::IO ;

BEGIN { our @ISA = qw( Stem::Event ) } ;

sub init_io_timeout {

	my( $self ) = @_ ;

	my $timeout = $self->{'timeout'} ;
	return unless $timeout ;

	$self->{'io_timer_event'} = Stem::Event::Timer->new(
		'object'	=> $self,
		'interval'	=> $timeout,
	) ;

	return ;
}

sub cancel {

	my( $self ) = @_ ;

#print "IO CANCEL $self\n" ;

	if ( my $io_timer_event = delete $self->{'io_timer_event'} ) {
		$io_timer_event->cancel() ;
	}

	$self->SUPER::cancel() ;

	delete $self->{'fh'} ;

	return ;
}

sub start {

	my( $self ) = @_ ;

	if ( my $io_timer_event = $self->{'io_timer_event'} ) {
		$io_timer_event->start() ;
	}

	$self->SUPER::start() ;

	return ;
}

sub stop {

	my( $self ) = @_ ;

	$self->{'active'} = 0 ;

	if ( my $io_timer_event = $self->{'io_timer_event'} ) {
		$io_timer_event->stop() ;
	}

	$self->SUPER::stop() ;

	return ;
}

sub timed_out {

	my( $self ) = @_ ;

#	$self->{log_type} = "$self->{'event_type'}_timeout" ;
	$self->trigger( $self->{'timeout_method'} ) ;
}

#######################################################

package Stem::Event::Read ;

BEGIN { our @ISA = qw( Stem::Event::IO ) }

=head2 Stem::Event::Read::new

This class creates an event that will trigger a callback whenever
its file descriptor has data to be read.  It takes an optional timeout
value which will trigger a callback to the object if no data has been
read during that period.

Read events are active when created - a call to the stop method is
needed to deactivate them.

=cut

BEGIN {

my $attr_spec_read = [

	{
		'name'		=> 'object',
		'required'	=> 1,
		'type'		=> 'object',
		'help'		=> <<HELP,
This object gets the method callbacks
HELP
	},
	{
		'name'		=> 'fh',
		'required'	=> 1,
		'type'		=> 'handle',
		'help'		=> <<HELP,
This file handle is checked if it has data to read
HELP
	},
	{
		'name'		=> 'timeout',
		'help'		=> <<HELP,
How long to wait (in seconds) without being readable before calling
the timeout method
HELP
	},
	{
		'name'		=> 'method',
		'default'	=> 'readable',
		'help'		=> <<HELP,
This method is called on the object when the file handle has data to read
HELP
	},
	{
		'name'		=> 'timeout_method',
		'default'	=> 'read_timeout',
		'help'		=> <<HELP,
This method is called on the object when the hasn't been readable
after the timeout period
HELP
	},
	{
		'name'		=> 'active',
		'default'	=> 1,
		'type'		=> 'boolean',
		'help'		=> <<HELP,
This flag marks the event as being active. It can be toggled with the
start/stop methods.
HELP
	},
	{
		'name'		=> 'id',
		'help'		=> <<HELP,
The id is passed to the callback method as its only argument. Use it to
identify different instances of this object.
HELP

	},
] ;

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec_read, @_ ) ;
	return $self unless ref $self ;

# 	return <<ERR unless defined fileno $self->{fh} ;
# Stem::Event::Read: $self->{fh} is not an open handle
# ERR

	my $err = $self->_build_core_event( 'read' ) ;
	return $err if $err ;

	$self->init_io_timeout() ;

	return $self ;
}

}
############################################################################

package Stem::Event::Write ;

BEGIN { our @ISA = qw( Stem::Event::IO ) } ;

=head2 Stem::Event::Write::new

This class creates an event that will trigger a callback whenever
its file descriptor can be written to.  It takes an optional timeout
value which will trigger a callback to the object if no data has been
written during that period.

Write events are stopped when created - a call to the start method is
needed to activate them.

=cut

my $attr_spec_write = [

	{
		'name'		=> 'object',
		'required'	=> 1,
		'type'		=> 'object',
		'help'		=> <<HELP,
This object gets the method callbacks
HELP
	},
	{
		'name'		=> 'fh',
		'required'	=> 1,
		'type'		=> 'handle',
		'help'		=> <<HELP,
This file handle is checked if it is writeable
HELP
	},
	{
		'name'		=> 'timeout',
		'help'		=> <<HELP,
How long to wait (in seconds) without being writeable before calling
the timeout method
HELP
	},
	{
		'name'		=> 'method',
		'default'	=> 'writeable',
		'help'		=> <<HELP,
This method is called on the object when the file handle is writeable
HELP
	},
	{
		'name'		=> 'timeout_method',
		'default'	=> 'write_timeout',
		'help'		=> <<HELP,
This method is called on the object when the hasn't been writeable
after the timeout period
HELP
	},
	{
		'name'		=> 'active',
		'default'	=> 0,
		'type'		=> 'boolean',
		'help'		=> <<HELP,
This flag marks the event as being active. It can be toggled with the
start/stop methods.
NOTE: Write events are not active by default.
HELP
	},
	{
		'name'		=> 'id',
		'help'		=> <<HELP,
The id is passed to the callback method as its only argument. Use it to
identify different instances of this object.
HELP

	},
] ;

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec_write, @_ ) ;
	return $self unless ref $self ;

	my $err = $self->_build_core_event( 'write' ) ;
	return $err if $err ;

#print $self->dump_events() ;

	$self->init_io_timeout() ;

	$self->stop() unless $self->{'active'} ;

#print $self->dump() ;

	return $self ;
}

1 ;
