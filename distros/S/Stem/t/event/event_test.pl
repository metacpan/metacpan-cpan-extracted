#!/usr/local/bin/perl -w

BEGIN {
	$Stem::Vars::Env{ 'event_loop' } = shift ;

	unless ( eval { require Time::HiRes } ) {

		Time::HiRes->import( qw( time ) ) ;
	}
}

use strict ;

#use Test::More tests => 29 ;
use Test::More tests => 24 ;

use Symbol ;

use Stem::Event ;
use Stem::Class ;

my $self = bless {} ;

test_events() ;

exit ;

sub test_events {

#	test_null_events() ;
#	test_plain_events () ;
#	test_signal_events () ;
	test_hard_timer_events () ;
	test_soft_timer_events () ;
	test_io_events () ;
}

sub test_null_events {

	local $SIG{__WARN__} = sub{} if
			$Stem::Vars::Env{ 'event_loop' } eq 'event' ;

	Stem::Event::start_loop() ;

	ok( 1, 'null - event loop exit' ) ;
}

sub test_plain_events {

	my $event = Stem::Event::Plain->new(
		'object' => $self
	) ;

	ok( ref $event, 'plain event created' ) ;

	Stem::Event::start_loop() ;

	ok( 1, 'plain - event loop exit' ) ;
}

# callback method for plain

sub triggered {

	my( $self ) = @_ ;

	ok( 1, 'plain event triggered' ) ;
}

sub test_signal_events {

	SKIP: {
		if ( $^O =~ /win32/i ) {

			skip( "signals not supported on windows", 3 ) ;
			return ;
		}

		my $event = Stem::Event::Signal->new(
			'object'	=> $self,
			'signal'	=> 'INT',
		) ;

		ok( ref $event, 'signal event created' ) ;

		$self->{'sig_event'} = $event ;

		kill 'INT', $$ ;

#print "kill INT\n" ;

		Stem::Event::start_loop() ;

		ok( 1, 'signal - event loop exit' ) ;
	}
}

# callback method for signal

sub sig_int_handler {

	my( $self ) = @_ ;

	ok( 1, 'signal event triggered' ) ;

	$self->{'sig_event'}->cancel() ;
	Stem::Event::stop_loop() ;
}


use constant INTERVAL	=> 4 ;
use constant SLEEP	=> 2 ;
use constant TIMER_CNT	=> 2 ;

# hard timeouts are timed from the beginning of the callback. so accumulated
# time in the callback doesn't affect the next callback.

sub test_hard_timer_events {

	my $event = Stem::Event::Timer->new(
		'object'	=> $self,
		'method'	=> 'hard_timeout',
		'interval'	=> INTERVAL,
		'delay'		=> INTERVAL,	# REMOVE - only for .10
		'repeat'	=> 1,
		'hard'		=> 1,
	) ;

	ok( ref $event, 'hard timer event created' ) ;
	print "$event\n" unless ref $event ;

	$self->{'hard_timer_event'} = $event ;
	$self->{'hard_timer_count'} = TIMER_CNT ;
	$self->{'hard_timer_start_time'} = time ;

	Stem::Event::start_loop() ;

	ok( 1, 'hard timer - event loop exit' ) ;
}

sub hard_timeout {

	my( $self ) = @_ ;

	ok( 1, 'hard timer event triggered' ) ;

	if ( --$self->{'hard_timer_count'} > 0 ) {

		my $time = time ;
		my $delta = $time - $self->{'hard_timer_start_time'} ;
		$self->{'hard_timer_start_time'} = $time ;

		ok( $delta >= INTERVAL, 'hard delta' ) ;

		hard_sleep( SLEEP ) ;

		return ;
	}

	
	my $time = time ;
	my $delta = $time - $self->{'hard_timer_start_time'} ;

#print "O $self->{'hard_timer_start_time'} T $time D $delta I ", INTERVAL, "\n" ;

	ok( $delta >= INTERVAL, 'hard delta 2' ) ;
	ok( $delta <= INTERVAL + SLEEP, 'hard delta sleep' ) ;

	$self->{'hard_timer_event'}->cancel() ;

	Stem::Event::stop_loop() ;
}


# Soft timeouts are timed from the end of the callback. so accumulated
# time in the callback delays the next callback.

sub test_soft_timer_events {

	my $event = Stem::Event::Timer->new(
		'object'	=> $self,
		'method'	=> 'soft_timeout',
		'interval'	=> INTERVAL,
		'delay'		=> INTERVAL,	# REMOVE  - only for .10
		'repeat'	=> 1,
	) ;

	ok( ref $event, 'soft timer event created' ) ;
#	print "$event\n" unless ref $event ;

	$self->{'soft_timer_event'} = $event ;
	$self->{'soft_timer_count'} = TIMER_CNT ;
	$self->{'soft_timer_start_time'} = time ;

#print "OTIME $self->{'soft_timer_start_time'}\n" ;

	Stem::Event::start_loop() ;

	ok( 1, 'soft timer - event loop exit' ) ;
}

sub soft_timeout {

	my( $self ) = @_ ;

	ok( 1, 'soft timer event triggered' ) ;

	if ( --$self->{'soft_timer_count'} > 0 ) {

		my $time = time ;
		my $delta = $time - $self->{'soft_timer_start_time'} ;

#print "T $time D $delta I ", INTERVAL, "\n" ;

		ok( $delta >= INTERVAL, 'soft delta' ) ;

		hard_sleep( SLEEP ) ;

#my $curr_time = time() ;
#print "DONE $curr_time\n" ;

		return ;
	}

	my $time = time ;
	my $delta = $time - $self->{'soft_timer_start_time'} ;

#print "TIME2 $time OTIME $self->{'soft_timer_start_time'} DEL $delta INTERVAL ", INTERVAL, "\n" ;

#	ok( $delta >= INTERVAL, 'soft delta 2' ) ;
	ok( $delta >= INTERVAL + SLEEP, 'soft delta 3' ) ;

	$self->{'soft_timer_event'}->cancel() ;

	Stem::Event::stop_loop() ;
}

sub test_io_events {

	Stem::Event::init_loop() ;

	my $read_fh = gensym ;
	my $write_fh = gensym ;

# get a pipe to read/write through.

	use Socket;
	socketpair( $read_fh, $write_fh, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) ;

	$self->{read_fh} = $read_fh ;
	$self->{write_fh} = $write_fh ;
	$self->{message} = 'Stem Read/Write Event' ;

	# create the read and write events

	my $read_event = Stem::Event::Read->new(
				'object'	=>	$self,
				'fh'		=>	$read_fh,
				'timeout'	=>	3,
	) ;

	ok( ref $read_event, 'read event created' ) ;
	$self->{'read_event'} = $read_event ;

	my $write_event = Stem::Event::Write->new(
				'object'	=>	$self,
				'fh'		=>	$write_fh,
	) ;

	ok( ref $write_event, 'write event created' ) ;
	$self->{'write_event'} = $write_event ;

	Stem::Event::start_loop() ;

	ok( 1, 'io - event loop exit' ) ;
}

sub read_timeout {

	my( $self ) = @_ ;

	ok( 1, 'read event timed out' ) ;

	$self->{'write_event'}->start() ;
}


sub writeable {

	my( $self ) = @_ ;

	ok( 1, 'write event triggered' ) ;

	syswrite( $self->{'write_fh'}, $self->{'message'} ) ;

	$self->{'write_event'}->cancel() ;
}

sub readable {

	my( $self ) = @_ ;

	ok(1, 'read event triggered' ) ;

	my( $read_buf ) ;

	my $bytes_read = sysread( $self->{'read_fh'}, $read_buf, 1000 ) ;

	ok( $bytes_read, 'read byte count' ) ;

	is( $read_buf, $self->{'message'}, 'read event compare' ) ;

	$self->{'read_event'}->cancel() ;

	Stem::Event::stop_loop() ;
}

# do a real hard sleep without alarm signal as that can screw up the tests
# sleep time is in (float) seconds

sub hard_sleep {

	my( $sleep_time ) = @_ ;

#print "BEFORE TIME $sleep_time\n" ;
	while( $sleep_time > 0 ) {

		my $curr_time = time() ;
		select( undef, undef, undef, $sleep_time ) ;

		$sleep_time -= time() - $curr_time ;

#print "AFTER TIME $sleep_time\n" ;
	}
}

1 ;
