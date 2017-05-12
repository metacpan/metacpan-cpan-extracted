#!/usr/local/bin/perl -w

use strict ;

use Stem::Event ;
use Stem::Socket ;
use Stem::AsyncIO ;
use Stem::Gather ;

use Data::Dumper ;
use Getopt::Long ;

my $opts_ok = GetOptions(
	\my %opts,
	'server_port=s',
	'upper_port=s',
	'reverse_port=s',
	'verbose|v',
	'help|h',
) ;

usage() unless $opts_ok ;
usage() if $opts{help} ;

my %backend_ports = (

	'reverse'	=> $opts{reverse_port} || 8888,
	'upper'		=> $opts{upper_port} || 8889,
) ;

# this controls the order of requests to the backends.

my @backend_ids = sort keys %backend_ports ;

my $listen = init_server( $opts{server_port} || 8887 ) ;

Stem::Event::start_loop() ;

exit ;

# create the listen socket for the server side of the middle layer.

sub init_server {

	my( $port ) = @_ ;

# create the middle layer listen socket

	my $listen = Stem::Socket->new(
		object	=> bless( {
		}, __PACKAGE__),
		method	=> 'client_connected',
		port	=> $port,
		server	=> 1,
	) ;

	die "can't listen on $port: $listen" unless ref $listen ;

	return $listen ;
}

# this is called when the server has accepted a socket connection

sub client_connected {

	my( $obj, $socket ) = @_ ;

# create the session object

	my $self = bless {}, __PACKAGE__ ;

# create and save the async io object for the client

	my $async = Stem::AsyncIO->new(
		object	=> $self,
		fh	=> $socket,
		read_method	=> 'client_read_data',
		send_data_on_close => 1,
	) ;
	ref $async or die "can't create Async: $async" ;
	$self->{client_async} = $async ;

# create and save the gather object

	my $gather = Stem::Gather->new(
		object	=> $self,
		keys	=> \@backend_ids,
	) ;

	ref $gather or die "can't create Gather: $gather" ;
	$self->{gather} = $gather ;
}

# this is called when all the data from client has been read.

sub client_read_data {

	my( $self, $data ) = @_ ;

	print "Client read [${$data}]\n"  if $opts{verbose} ;

# store the client data (a ref is passed in)

	$self->{'client_data'} = ${$data} ;

# connect to all of the backend servers

	$self->connect_to_backends() ;
}

# this connects the session to all of the backends

sub connect_to_backends {

	my( $self ) = @_ ;

# loop over all the backends

	foreach my $id ( @backend_ids ) {

# connect to the backend with this id and its port and save the
# connect object

		my $connect = Stem::Socket->new(
			object	=> $self,
			id	=> $id,
			port	=> $backend_ports{ $id },
			method	=> 'backend_connected',
		) ;

		ref $connect or die "can't create Socket: $connect" ;
		$self->{connect}{$id} = $connect ;
	}
}

# this is called when a backend end connection succeeds

sub backend_connected {

	my( $self, $socket, $id ) = @_ ;

# delete and shutdown the connect object as we no longer need it

	my $connect = delete $self->{connect}{$id} ;
	$connect->shut_down() ;

# create and save an async i/o object for this backend

	my $async = Stem::AsyncIO->new(
		object	=> $self,
		id	=> $id,
		fh	=> $socket,
		read_method	=> 'backend_read_data',
		send_data_on_close => 1,
	) ;
	ref $async or die "can't create Async: $async" ;
	$self->{async}{$id} = $async ;

# write the client data to the back end. no more data will follow.

	$async->final_write( \$self->{client_data} ) ;
}

# this is called when we have read all the data from the backend

sub backend_read_data {

	my( $self, $data, $id ) = @_ ;

	print "Backend $id READ [${$data}]\n" if $opts{verbose} ;

# save the backend data (we are passed a ref)

	$self->{backend_data}{$id} = ${$data} ;

# delete and shutdown the async i/o for the backend since we don't
# need it anymore

	my $async = delete $self->{async}{$id} ;
	$async->shut_down() ;

# mark that this backend is done

	$self->{'gather'}->gathered( $id ) ;
}

# this is called when all the backends are done.

sub gather_done {

	my( $self ) = @_ ;

	my $gather = delete $self->{gather} ;
	$gather->shut_down() ;

# no more backends so we return the joined backend data to the client.

# we don't need the gather object around anymore
# allow for self cleanup when it is done with the final write to the
# client.

	my $async = delete $self->{client_async} ;
	$async->final_write(
		join( '',  @{$self->{backend_data}}{ @backend_ids } )
	) ;
}



sub usage {

	my ( $error ) = @_ ;

	$error ||= '' ;
	die <<DIE ;
$error
usage: $0 [--help|h] [--upper_port <port>] [--reverse_port <port>]
	[--server_port <port>] [--v|--verbose]

	upper_port <port>	Set the port for the middleware server
				(default is 8888)
	upper_port <port>	Set the port for the upper case server
				(default is 8888)
	reverse_port <port>	Set the port for the string reverse server
				(default is 8889)
	verbose			Set verbose mode
	help | h		Print this help text
DIE

}

# this destroy can be uncommented to see the actual destruction of the
# various obects in this script.

# DESTROY {
# 	my( $self ) = @_ ;
# 	print "DEST [$self]\n" ;
# }
