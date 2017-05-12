BEGIN {
	$_tests = 7;
	unshift @INC, 'blib/lib', 'blib/arch';
	my $o = select STDOUT;
	$| = 1;
	select $o;
	print "1..$_tests\n";

	require Config;
	if( ! $Config::Config{'useithreads'} ) {
		print STDERR "Skip: not supported on this platform\n";
		lock( $_pos );
		for( $_pos = 1; $_pos <= $_tests; $_pos ++ ) {
			print "ok $_pos\n";
		}
		exit( 0 );
	}

	$SIG{'__DIE__'} = sub {
		print STDERR "Skip: not supported on this platform\n";
		lock( $_pos );
		for( $_pos = 1; $_pos <= $_tests; $_pos ++ ) {
			print "ok $_pos\n";
		}
		exit( 0 );
	};

}

use threads;
use threads::shared;

$SIG{'__DIE__'} = '';

require Socket::Class;
import Socket::Class qw(:all);

our $RUNNING : shared = 1;
our $_pos : shared = 1;

$server = Socket::Class->new(
	'blocking' => 0,
) or warn Socket::Class->error;

our $port = 11340;
while( ! $server->bind( 'localhost', $port ) ) {
	$port ++;
	if( $port > 65535 ) {
		$server = undef;
		last;
	}
}
if( $server ) {
	$server->listen( 10 ) or $server = undef;
}

if( ! $server ) {
	_fail_all();
	goto _end;
}
_check( 1 );

threads->create( \&server_thread, $server );

for $i( 1 .. 3 ) {
	$client = Socket::Class->new(
		'remote_addr' => 'localhost',
		'remote_port' => $port,
		'blocking' => 0,
	) or warn Socket::Class->error;
	_check( $client );
	
	if( ! $client ) {
		_fail_all();
		goto _close;
	}
	
	threads->create( \&client_thread, $client );
}

for $i( 1 .. 100 ) {
	{
		lock( $_pos );
		last if $_pos > $_tests;
	}
	$server->wait( 20 );
}

_close:
$RUNNING = 0;
foreach $thread( threads->list ) {
	eval {
		$thread->join();
	};
}

_end:

1;

sub server_thread {
	my( $server ) = @_;
	my( $client );
	while( $RUNNING ) {
		$client = $server->accept();
		if( ! defined $client ) {
			# server is closed
			last;
		}
		elsif( ! $client ) {
			$server->wait( 10 );
			next;
		}
		threads->create( \&response_thread, $client );
	}
	$server->free();
	return 1;
}

sub response_thread {
	my( $client ) = @_;
	my( $got, $buf );
	$client->set_blocking( 0 );
	while( $RUNNING ) {
		$got = $client->read( $buf, 1024 );
		if( ! defined $got ) {
			# connection error
			warn $client->error;
			last;
		}
		elsif( ! $got ) {
			$client->wait( 10 );
			next;
		}
		$client->write( 'hello client' );
		last;
	}
	$client->wait( 50 );
	#$client->free();
	#threads->self->detach if $RUNNING;
	return 1;
}

sub client_thread {
	my( $client ) = @_;
	my( $got, $buf );
	$client->write( 'hello server' );
	while( $RUNNING ) {
		$got = $client->read( $buf, 1024 );
		if( ! defined $got ) {
			# connection error
			warn $client->error;
			last;
		}
		elsif( ! $got ) {
			$client->wait( 10 );
			next;
		}
		_check( 1 );
		last;
	}
	$client->wait( 50 );
	#$client->free();
	#threads->self->detach if $RUNNING;
	return 1;
}

sub _check {
	lock( $_pos );
	print "" . ($_[0] ? "ok" : "not ok") . " $_pos\n";
	$_pos ++;
}

sub _skip_all {
	print STDERR "Skipped: probably not supported on this platform\n";
	lock( $_pos );
	for( ; $_pos <= $_tests; $_pos ++ ) {
		print "ok $_pos\n";
	}
}

sub _fail_all {
	lock( $_pos );
	for( ; $_pos <= $_tests; $_pos ++ ) {
		print "not ok $_pos\n";
	}
}
