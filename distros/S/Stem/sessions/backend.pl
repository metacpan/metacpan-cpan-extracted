#!/usr/local/bin/perl -w

use strict ;
use lib '../lib' ;

use Stem::Event ;
use Stem::Socket ;
use Stem::AsyncIO ;

use Time::HiRes qw( time ) ;
use Getopt::Long ;

my $opts_ok = GetOptions(
	\my %opts,
	'upper_port=s',
	'reverse_port=s',
	'v|verbose',
	'help|h',
) ;

usage() unless $opts_ok ;
usage() if $opts{help} ;


my $time ;

# this table defines the servers. each entry has the default port
# number and the code to execute on the input data.

my %servers = (

	upper => {

		port => 8888,
		code => sub { uc $_[0] },
	},

	reverse => {

		port => 8889,
		code => sub { scalar( reverse $_[0] ) },
	},
) ;

start_servers() ;

Stem::Event::start_loop() ;

exit ;

sub start_servers {

	while( my( $id, $server ) = each %servers ) {

# make each server entry an object

		bless $server, __PACKAGE__ ;

# save its id in itself

		$server->{id} = $id ;

# get the port from the options or the default

		my $port = $opts{"${id}_port"} || $server->{port} ;

# get the listen socket and save it

		my $listen = Stem::Socket->new(
			object	=> $server,
			port	=> $port,
			server	=> 1,
		) ;

		die "can't listen on $port: $listen" unless ref $listen ;

		$server->{listen} = $listen ;
	}
}

# this is called when a socket is connected

sub connected {

	my( $server, $socket ) = @_ ;

# create a session object. blessed directly into this class because it
# is simple and works nicely

	my $self = bless {

		socket	=> $socket,
		id	=> $server->{id},
	}, __PACKAGE__ ;

# get an asyncio object and save it in the session object
# this will buffer all input and send it only when the socket is closed

	my $async = Stem::AsyncIO->new(
		object	=> $self,
		fh	=> $socket,
		send_data_on_close => 1,
	) ;
	ref $async or die "can't create Async: $async" ;
	$self->{async} = $async ;
}

# this is called when we have read data

sub async_read_data {

	my( $self, $data ) = @_ ;

# print "READ [$$data]\n" ;

# save (the ref to) the data 

	$self->{'data'} = $data ;

# get a random delay time

#	my $delay = .5 ;
	my $delay = rand( 1 ) + .5 ;
	$delay = .01 ;

#print "DELAY $delay\n" ;
$time = time() ;

# get and save a timer object with this delay

	my $timer = Stem::Event::Timer->new(
		object	=> $self,
		delay	=> $delay,
	) ;
	ref $timer or die "can't create Timer: $timer" ;
	$self->{timer} = $timer ;

	return ;
}

# timeout is over so this gets called

sub timed_out {

	my( $self ) = @_ ;

# my $delta = time() - $time ;
# printf "DELTA = %6f\n", $delta ;

# get the real datat
	my $data = ${$self->{data}};

# find the server (we could have saved this in the session object but
# we can do this quick lookup to get it)

	my $server = $servers{ $self->{'id'} } ;

# process the input data with the code in the server object

	my $echo_data = $server->{code}->( $data ) ;

# print "ECHO [$echo_data]\n" ;

# write out the echo data to the socket and close it when done.

	$self->{async}->final_write( $echo_data ) ;
}

sub usage {

	my ( $error ) = @_ ;

	$error ||= '' ;
	die <<DIE ;
$error
usage: $0 [--help|h] [--upper_port <port>] [--reverse_port <port>]


	upper_port <port>	Set the port for the upper case server
				(default is 8888)
	reverse_port <port>	Set the port for the string reverse server
				(default is 8889)
	help | h		Print this help text
DIE

}

# sub async_closed {
# 	my( $self ) = @_  ;
# print "CLOSED $self\n" ;
# }

# DESTROY {
# 	my( $self ) = @_  ;
# print "DESTROY $self\n" ;
# }
