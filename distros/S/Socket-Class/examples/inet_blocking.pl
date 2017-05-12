#!/usr/bin/perl

BEGIN {
	unshift @INC, 'blib/lib', 'blib/arch';
}

use threads;
use threads::shared;

use Time::HiRes;
use Socket::Class;

sub say { print @_, "\n"; }

our $RUNNING : shared = 1;

$server = Socket::Class->new(
	'local_addr' => '127.0.0.1',
	'listen' => 5,
) or die Socket::Class->error;
threads->create( \&server_thread, $server );


$client = Socket::Class->new(
	'remote_addr' => '127.0.0.1',
	'remote_port' => $server->local_port,
) or die Socket::Class->error;

if( ! defined $client->is_writable( 100 ) ) {
	die $client->error;
}
$client->write( "S" x 512 );

threads->create( \&client_thread, $client );

our $packet_count = 0;
our $client_ts : shared;

sleep( 9 );

$RUNNING = 0;
foreach $thread( threads->list() ) {
	$thread->join();
}

sub server_thread {
	my( $sock ) = @_;
	my( $client, $buf );
	say "\nServer running at " . $sock->local_addr . ' port ' . $sock->local_port;
	$sock->set_blocking( 0 );
	while( $RUNNING ) {
		if( $client = $sock->accept() ) {
			threads->create( \&response_thread, $client );
		}
		else {
			$sock->wait( 10 );
		}
	}
	$sock->free();
	print "\nclosing server thread\n";
}

sub response_thread {
	my( $sock ) = @_;
	my( $got, $buf, $trhd );
	$trhd = threads->self;
	print "\nstarting response thread\n";
	say "Incoming connection from " . $sock->local_addr . ":" . $sock->local_port;
	while( $RUNNING ) {
		$got = $sock->is_readable( 100 );
		if( ! defined $got ) {
			# error
			warn $sock->error;
			last;
		}
		elsif( $got < 1 ) {
			next;
		}
		$got = $sock->recv( $buf, 4096 );
		if( ! defined $got ) {
			# error
			warn $sock->error;
			last;
		}
		$got = $sock->is_writable( 100 );
		if( ! defined $got ) {
			# error
			warn $sock->error;
			last;
		}
		elsif( $got < 1 ) {
			next;
		}
		$sock->send( "C" x 512 );
	}
	print "\nclosing response thread\n";
	$sock->free();
	threads->self->detach() if $RUNNING;
	return 1;
}

sub client_thread {
	my( $sock ) = @_;
	my( $got, $buf, $trhd, $tid );
	print "\nstarting client thread\n";
	$trhd = threads->self;
	$tid = $trhd->tid;
	$client_ts = &Time::HiRes::time();
	while( $RUNNING ) {
		$got = $sock->is_readable( 100 );
		if( ! defined $got ) {
			# error
			warn $sock->error;
			last;
		}
		elsif( $got < 1 ) {
			next;
		}
		$got = $sock->recv( $buf, 4096 );
		if( ! defined $got ) {
			# error
			warn $sock->error;
			last;
		}
		$packet_count ++;
		if( ($packet_count % 100) == 0 ) {
			my $ac = sprintf( '%0.1f', $packet_count / (&Time::HiRes::time() - $client_ts) );
			print "$tid got $packet_count packets a $got bytes $ac p/s\n";
		}
		$got = $sock->is_writable( 100 );
		if( ! defined $got ) {
			# error
			warn $sock->error;
			last;
		}
		elsif( $got < 1 ) {
			next;
		}
		$sock->send( "S" x 512 );
	}
	print "\nclosing client thread\n";
	$sock->free();
	threads->self->detach() if $RUNNING;
	return 1;
}
