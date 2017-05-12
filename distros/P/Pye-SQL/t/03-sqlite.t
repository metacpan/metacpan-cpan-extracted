#!/usr/bin/env perl

use warnings;
use strict;
use Test::More;

BEGIN {
	eval { require DBD::SQLite; 1 }
		|| plan skip_all => 'DBD::SQLite required';

	plan tests => 9;
	use_ok('Pye::SQL');
}

my $pye = Pye::SQL->new(
	db_type => 'sqlite',
	database => ':memory:', # in memory database
	table => 'pye_test'
);

ok($pye, 'Pye::SQL object created');

$pye->{dbh}->do('CREATE TABLE pye_test (
	session_id TEXT NOT NULL,
	date TEXT NOT NULL,
	text TEXT NOT NULL,
	data TEXT
)');

$pye->{dbh}->do('CREATE INDEX logs_per_session ON pye_test (session_id)');

ok($pye->log(1, "What's up?"), "Simple log message");

ok($pye->log(1, "Some data", { hey => 'there' }), "Log message with data structure");

sleep(1);

ok($pye->log(2, "Yo yo ma"), "Log message for another session");

my @latest_sessions = $pye->list_sessions;

is(scalar(@latest_sessions), 2, "We only have one session");

is($latest_sessions[0]->{id}, '2', "We have the correct session ID");

my @logs = $pye->session_log(1);

is(scalar(@logs), 2, 'Session has two log messages');

ok(exists $logs[1]->{data} && $logs[1]->{data}->{hey} eq 'there', 'Second log message has a data element');

unlink 't/test.db';

done_testing();
