use strict;
use Test::More tests => 19;
use Queue::Leaky;

SKIP: {
    skip "Define QLEAKY_Q4M_DSN to run this test", 7 unless $ENV{QLEAKY_Q4M_DSN};

    my $table = join('_', qw(qleaky test), $$);
    my $queue = Queue::Leaky->new(
        queue => {
            module => 'Q4M',
            connect_info => [
                $ENV{QLEAKY_Q4M_DSN},
                $ENV{QLEAKY_Q4M_USERNAME} || 'root',
                $ENV{QLEAKY_Q4M_PASSWORD},
                { RaiseError => 1, AutoCommit => 1 },
            ],
        },
    );

    isa_ok( $queue->queue, 'Queue::Leaky::Driver::Q4M' );

    my $dbh = $queue->queue->q4m->dbh;

    ok( $dbh->do("create table $table (v text) engine=queue"), "create table ok" );

    my $message = {
        v => "Hello!",
    };

    ok( $queue->insert($table, $message) );
    my $rv = $queue->next($table);
    is( $rv, $table );
    is( $queue->fetch($rv)->{v}, "Hello!" );
    ok( $queue->clear($table) );

    ok( $dbh->do("drop table $table"), "clean up ok" );
}

SKIP: {
    skip "Define QLEAKY_MEMCACHED_SERVERS to run this test", 12 unless $ENV{QLEAKY_MEMCACHED_SERVERS};

    my $max = 3;
    my $queue = Queue::Leaky->new(
        max_items => $max,
        state => {
            module => 'Memcached',
            memcached => {
                servers => [ split(/\s+/, $ENV{QLEAKY_MEMCACHED_SERVERS}) ],
            }
        },
    );

    for my $count (1 .. $max) {
        ok( $queue->insert($count) );
    }
    ok( !$queue->insert("I'm not there") );

    for my $count (1 .. $max) {
        ok( $queue->next );
        is( $queue->fetch, $count );
    }
    ok( !$queue->next );

    is( $queue->state_get($queue->queue), 0 );
}
