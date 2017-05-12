use strict;
use warnings;

use Test::More;
BEGIN {
	eval { require Test::postgresql; } or Test::More->import(skip_all => 'Test::postgresql is not installed');
}
use POSIX qw(SIGTERM SIGKILL);

use IO::Async::Loop;
use Net::Async::PostgreSQL::Client;

use constant SHUTDOWN_DELAY => 5;

# Start up a PostgreSQL server
note 'Set up new PG instance';
my $pg = Test::postgresql->new(
	initdb_args => $Test::postgresql::Defaults{initdb_args} . ' --encoding=utf8'
) or Test::More->import(skip_all => 'Could not start PG instance via Test::postgresql: ' . $Test::postgresql::errstr);

# If we get this far, we're running PG and any further failures are most likely our fault.

note "Activated new PG instance with DSN " . $pg->dsn . " and pid " . $pg->pid;
plan tests => 3;

# Set up the event loop and start our client
my $loop = IO::Async::Loop->new;
my $dbh = new_ok('Net::Async::PostgreSQL::Client' => [
	debug			=> 0,
	host			=> 'localhost',
	service			=> $pg->port,
	database		=> 'postgres',
	user			=> 'postgres',
	pass			=> '',
]) or die "Failed to instantiate dbh";

# Register some handlers
$dbh->add_handler_for_event(
	closed => sub {
		pass("closed");
		$loop->later(sub { $loop->loop_stop });
	},
	ready_for_query => sub {
		pass('connected ok');
		$loop->later(sub {
			$dbh->terminate;
		});
		0;
	},
	notice => sub {
		my ($self, %args) = @_;
		warn("NOTICE: " . $args{notice});
		1;
	},
	error => sub {
		my ($self, %args) = @_;
		die "No error in hash? Was @_\n" unless exists $args{error};
		die "Error: " . Dumper($args{error});
		1;
	}
);

# Kick off the tests
$loop->add($dbh);
$dbh->connect;
$loop->loop_forever;

# Handle the shutdown ourselves, since IO::Async handles SIGCHLD.
if($pg->pid) {
	$loop->watch_child($pg->pid, sub {
		$pg->pid(undef);
		$pg->stop;
		$loop->loop_stop;
	});

	$loop->enqueue_timer(
		delay => SHUTDOWN_DELAY,
		code => sub {
			note 'Did not shut down after ' . SHUTDOWN_DELAY . ' seconds, sending SIGKILL';
			kill SIGKILL, $pg->pid;
		}
	);
	kill SIGTERM, $pg->pid;
	$loop->loop_forever;
}

