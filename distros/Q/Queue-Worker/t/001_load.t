use strict;
use warnings FATAL => 'all';

use Test::TempDatabase;
use Test::More tests => 21;

BEGIN { use_ok( 'Queue::Worker'); }

Test::TempDatabase->become_postgres_user;

my $temp_db = Test::TempDatabase->create(dbname => 'queue_worker_db');
my $dbh = $temp_db->handle;
$dbh->do("set client_min_messages to warning");

package Q1;
use base 'Queue::Worker';

sub name { return 'q1'; }

sub process {
	my ($self, $msg) = @_;
	push @{ $self->{msgs} }, $msg;
}

package Q2;
use base 'Queue::Worker';

sub name { return 'q2'; }

sub process {
	$dbh->do("insert into fork_res values (?)", undef, $_[1]);
	my $v = $dbh->selectcol_arrayref("select v from value_res");
	$v->[0]++;
	$dbh->do("update value_res set v = ?", undef, $v->[0]);
}

package main;

Q1->create_table($dbh);
Q2->create_table($dbh);

ok($dbh->do("select * from queue_worker_q1"));
ok($dbh->do("select * from queue_worker_q2"));

Q1->enqueue($dbh, "h$_") for (1 .. 3);
is_deeply($dbh->selectcol_arrayref("select count(*) from queue_worker_q1")
		, [ 3 ]);

my $q1 = Q1->new;
isa_ok($q1, 'Q1');

$q1->run($dbh);
is_deeply($q1->{msgs}, [ 'h1', 'h2', 'h3' ]);

my @pids;
sub do_fork {
	if (my $pid = fork()) {
		push @pids, $pid;
		return;
	}
	$dbh->{InactiveDestroy} = 1;
	undef $dbh;
	$dbh = $temp_db->connect('queue_worker_db');
	$temp_db->{db_handle} = $dbh;
	sleep 1;
	shift()->($dbh);
	exit;
}

Q2->enqueue($dbh, "h$_") for (1 .. 5);
$dbh->do("create table fork_res (m text)");
$dbh->do("create table value_res (v integer)");
$dbh->do("insert into value_res values (0)");

do_fork(sub {
	my $q = Q2->new;
	$q->run(shift());
}) for (1 .. 7);
waitpid($_, 0) for @pids;
is_deeply($dbh->selectcol_arrayref("select count(*) from fork_res"), [ 5 ]);
is_deeply($dbh->selectcol_arrayref("select v from value_res"), [ 5 ]);

package Q21;
use base 'Q2';

sub process {
	my $q2 = Q21->new;
	Test::More::is($q2->run($dbh), 0);
}

package main;

my $q21 = Q21->new;
is($q21->run($dbh), 0);

Q21->enqueue($dbh, "h1");
is($q21->run($dbh), 1);

package Q22;
use base 'Q2';

sub process { die "hoho"; }

package main;

my $q22 = Q22->new;

Q22->enqueue($dbh, "h1");
eval { $q22->run($dbh); };
like($@, qr/hoho/);

is_deeply($dbh->selectcol_arrayref("select count(*) from queue_worker_q1")
		, [ 0 ]);

Q21->enqueue($dbh, "h1");
is($q21->run($dbh), 1);

my $_waits = 0;
my $_posts = 0;
package Q23;
use base 'Q2';

sub process {}

package S;

sub trywait {
	$_waits++;
	shift()->{sem}->trywait;
}

sub post {
	$_posts++;
	Q23->enqueue($dbh, "race") if $_posts < 2;
	shift()->{sem}->post;
}

package main;

my $q23 = Q23->new;
$q23->{semaphore} = bless({ sem => $q23->{semaphore} }, 'S');
Q23->enqueue($dbh, "h1");

is($q23->run($dbh), 2);
is($_posts, $_waits);

isa_ok(Q1->get_semaphore, 'POSIX::RT::Semaphore::Named');

Q1->unlink_semaphore;
unlike(`ls /dev/shm`, qr/q1/);
Q2->unlink_semaphore;
unlike(`ls /dev/shm`, qr/q2/);

Queue::Worker->create_table($dbh, 'ho');
ok($dbh->do("select * from queue_worker_ho"));
