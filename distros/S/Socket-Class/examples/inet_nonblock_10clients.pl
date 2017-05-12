#!/usr/bin/perl
BEGIN {
	unshift @INC, 'blib/lib', 'blib/arch';
}

use threads;
use threads::shared;

use Time::HiRes;
use Socket::Class;

our $RUNNING : shared = 1;
our $LockSay : shared;

sub say {
	lock( $LockSay );
	print @_, "\n";
}

$server = Socket::Class->new(
	'local_addr' => '127.0.0.1',
	'listen' => 5,
	'blocking' => 0,
) or die Socket::Class->error;
threads->create( \&server_thread, $server );

our $packet_count = 0;
our $client_ts;

for $i( 1 .. 10 ) {
	$client = Socket::Class->new(
		'remote_addr' => '127.0.0.1',
		'remote_port' => $server->local_port,
		'blocking' => 0,
	) or die Socket::Class->error;

	threads->create( \&client_thread, $client );
	
	$client->write( "S" x 512 );
}

sleep( 10 );
$RUNNING = 0;
foreach $thread( threads->list() ) {
	eval {
		$thread->join();
	};
}

1;

sub server_thread {
	my( $sock ) = @_;
	my( $client, $buf );
	say "starting server thread";
	say "Server running at " . $sock->local_addr . ' port ' . $sock->local_port;
	while( $RUNNING ) {
		if( $client = $sock->accept() ) {
			threads->create( \&response_thread, $client );
		}
		else {
			$sock->wait( 100 );
		}
	}
	say "closing server thread";
	$sock->free();
}

sub response_thread {
	my( $sock ) = @_;
	my( $got, $buf, $trhd, $tid );
	$trhd = threads->self;
	$tid = $trhd->tid;
	say "starting response thread $tid";
	say "Incoming connection from " . $sock->remote_addr . ":" . $sock->remote_port;
	$sock->set_blocking( 0 );
	while( $RUNNING ) {
		$got = $sock->read( $buf, 4096 );
		if( ! defined $got ) {
			# error
			warn $sock->error;
			last;
		}
		elsif( $got == 0 ) {
			#$trhd->yield;
			$sock->wait( 1 );
			next;
		}
		$sock->write( "C" x 512 );
	}
	say "closing response thread $tid";
	$sock->free();
	threads->self->detach() if $RUNNING;
	return 1;
}

sub client_thread {
	my( $sock ) = @_;
	my( $got, $buf, $trhd, $tid );
	$trhd = threads->self;
	$tid = $trhd->tid;
	say "starting client thread $tid";
	$client_ts = &Time::HiRes::time();
	while( $RUNNING ) {
		$got = $sock->read( $buf, 4096 );
		if( ! defined $got ) {
			# error
			warn $sock->error;
			last;
		}
		elsif( $got == 0 ) {
			$trhd->yield;
			$sock->wait( 1 );
			next;
		}
		$packet_count ++;
		if( ($packet_count % 300) == 0 ) {
			my $ac = sprintf( '%0.1f', $packet_count / (&Time::HiRes::time() - $client_ts) );
			say "$tid got $packet_count packets a $got bytes ($ac p/s)";
		}
		$sock->write( "S" x 512 );
	}
	say "closing client thread $tid";
	$sock->free();
	threads->self->detach() if $RUNNING;
	return 1;
}
