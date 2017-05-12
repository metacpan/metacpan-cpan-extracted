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
	'domain' => 'unix',
	'local_path' => 'test.socket',
	'listen' => 5,
) or die Socket::Class->error;

threads->create( \&server_thread, $server );

$client = Socket::Class->new(
	'domain' => 'unix',
	'remote_path' => $server->local_path,
) or die Socket::Class->error;

if( ! defined $client->is_writable( 100 ) ) {
	die $client->error;
}
$client->write( "S" x 512 );

threads->create( \&client_thread, $client );

our $client_count = 0;
our $client_ts : shared = &microtime();

sleep( 2 );

$RUNNING = 0;
foreach $thread( threads->list() ) {
	$thread->join();
}

1;

sub server_thread {
	my( $sock ) = @_;
	my( $client, $buf );
	say "\nstarting server thread";
	say "\nServer running at " . $sock->local_path;
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
	say "\nclosing server thread";
}

sub response_thread {
	my( $sock ) = @_;
	my( $got, $buf, $trhd );
	$trhd = threads->self;
	say "\nstarting response thread";
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
	say "\nclosing response thread";
	$sock->free();
	$trhd->detach() if $RUNNING;
	return 1;
}

sub client_thread {
	my( $sock ) = @_;
	my( $got, $buf, $trhd, $tid );
	say "\nstarting client thread";
	$trhd = threads->self;
	$tid = $trhd->tid;
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
		$client_count ++;
		if( ( $client_count % 1000 ) == 0 ) {
			my $ac = sprintf( '%0.1f', $client_count / ( &microtime() - $client_ts ) );
			print "$tid got $client_count packets a $got bytes ($ac p/s)\n";
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
	say "\nclosing client thread";
	$sock->free();
	$trhd->detach() if $RUNNING;
	return 1;
}

sub microtime {
	my( $sec, $usec ) = &Time::HiRes::gettimeofday();
	return $sec + $usec / 1000000;
}
