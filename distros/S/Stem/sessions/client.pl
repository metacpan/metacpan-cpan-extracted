#!/usr/local/bin/perl -w

use strict ;
use lib '../lib' ;

BEGIN {
#	$Stem::Vars::Env{event_loop} = 'perl' ;
}

use Stem ;
use Stem::Socket ;
use Stem::AsyncIO ;

use Getopt::Long ;

my $opts_ok = GetOptions(
	\my %opts,
	'port=s',
	'max_clients=i',
	'total_clients=i',
	'string_min_len=i',
	'string_max_len=i',
	'verbose|v',
	'help|h',
) ;

usage() unless $opts_ok ;
usage() if $opts{help} ;

# set defaults for various options

$opts{max_clients} ||= 1 ;
$opts{total_clients} ||= 1 ;
$opts{port} ||= 8887 ;
$opts{string_min_len} ||= 8 ;

my $client_cnt = 0 ;

my %clients ;

make_clients() ;

Stem::Event::start_loop() ;

exit ;

# this creates and saves the client sessions

sub make_clients {

# keep making new clients if we are under the total and the parallel counts

	while( $client_cnt < $opts{total_clients} && 
	       keys %clients < $opts{max_clients} ) {

# get a random token for our data

		my $data = rand_string( $opts{string_min_len},
					$opts{string_max_len},
		) ;

		print "String [$data]\n" if $opts{verbose} ;

# make the session object

		my $self = bless { 
			data	=> $data,
		}, __PACKAGE__ ;

# create the connection object and save it

		my $connect = Stem::Socket->new(
			object	=> $self,
			port	=> $opts{port},
		) ;
		ref $connect or die "can't create Socket: $connect" ;
		$self->{connect} = $connect ;

# save the session object so we can track all the active ones

		$clients{ $self } = $self ;

# print "cnt $client_cnt max $max_clients num ", keys %clients, "\n" ;

		$client_cnt++ ;
	}
}

# this is called when we have connected to the middle layer server

sub connected {

	my( $self, $socket ) = @_ ;

# save the connected socket

	$self->{'socket'} = $socket ;

# we don't need the connection object anymore

	my $connect = delete $self->{connect} ;
	$connect->shut_down() ;

# create and save an async i/o object to do i/o with the middle layer server

	my $async = Stem::AsyncIO->new(
		object	=> $self,
		fh	=> $socket,
		send_data_on_close => 1,
	) ;
	ref $async or die "can't create Async: $async" ;
	$self->{async} = $async ;

# write the data to the middle layer (and send no more data)

	$async->final_write( \$self->{data} ) ;
}

# this is called when we have read all the data from the middle layer

sub async_read_data {

	my( $self, $data ) = @_ ;

	print "Read [${$data}]\n" if $opts{verbose} ;

# we don't need the async i/o object anymore

	my $async = delete $self->{async} ;
	$async->shut_down() ;

# make the string that we expect back from the middle layer

	my $expected = uc( $self->{data} ) . reverse( $self->{data} ) ;

	print "Expected [$expected]\n" if $opts{verbose} ;

# check and report the results
	if ( ${$data} ne $expected ) {

		print "ERROR\n"  if $opts{verbose} ;
	}
	else {
		print "OK\n"  if $opts{verbose} ;
	}

# delete this client session as we are done

	delete( $clients{ $self } ) ;

# replace this session with a new one (if we haven't hit the max yet)

	make_clients() ;
}

INIT {

my @alpha = ( 'a' .. 'z', '0' .. '9' ) ;

sub rand_string {

	my( $min_len, $max_len ) = @_ ;

	$min_len ||= 8 ;
	$max_len ||= $min_len ;


	my $length = $min_len + int rand( $max_len - $min_len + 1 ) ;

	return join '', map $alpha[rand @alpha], 1 .. $length ;
}

}

sub usage {

	my ( $error ) = @_ ;

	$error ||= '' ;
	die <<DIE ;
$error
usage: $0 [--help|h] [--verbose|v] [--port <port>]
	[--total_clients <count>] [--max_clients <count>]
	[--string_min_len <len>] [--max_clients <count>]

	port <port>		Set the port for the middle layer server
				(default is 8887)
	max_clients <count>	Set the maximum number of parallel clients
				(default is 1)
	total_clients <count>	Set the total number of clients to run
				(default is 1)
	string_min_len <len>	Set the minimum length for the random strings
				(default is 8)
	string_max_len <len>	Set the maximum length for the random strings
				(default is string_min_len which means a fixed
				 length string)
	help | h		Print this help text
DIE

}
