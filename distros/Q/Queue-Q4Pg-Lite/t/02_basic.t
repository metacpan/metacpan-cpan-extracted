use strict;
use lib("t/lib");
use Test::Queue::Q4Pg::Lite (tests => 66);

BEGIN
{
    use_ok("Queue::Q4Pg::Lite");
}

{
    my $table = $Test::Queue::Q4Pg::Lite::TABLES[0];
    my $q = Queue::Q4Pg::Lite->connect(
        connect_info => \@Test::Queue::Q4Pg::Lite::CONNECT_INFO,
    );
    ok($q);
    isa_ok($q, "Queue::Q4Pg::Lite");

    my $max = 32;
    for my $i (1..$max) {
        ok($q->insert($table, { v => $i }));
    }
    my $count = 0;
    while ($q->next($table)) {
        my $h = $q->fetch_hashref();
        $count++;
        $q->ack;
        last if $h->{v} == $max;
    }
    is($count, $max);
    $q->disconnect;
}

{
    my $table   = $Test::Queue::Q4Pg::Lite::TABLES[0];
    my $timeout = 1;
    my $q = Queue::Q4Pg::Lite->connect(
        connect_info => \@Test::Queue::Q4Pg::Lite::CONNECT_INFO,
    );
    ok($q);
    isa_ok($q, "Queue::Q4Pg::Lite");

    my $max = 32;
    for my $i (1..$max) {
        $q->insert($table, { v => $i });
    }

    my $count = 0;
    while (my $rv = $q->next($table, { v => { "<=", 16 } })) {
        is(ref $rv, "HASH");

        my $h = $q->fetch_hashref();
        $count++;
        $q->ack;
        last if $h->{v} == 16;
    }

    is($count, 16);

    $q->dbh->do("DELETE FROM $table");
    $q->disconnect;
}

{
    my $table   = $Test::Queue::Q4Pg::Lite::TABLES[0];
    my $timeout = 1;
    my $q = Queue::Q4Pg::Lite->connect(
        connect_info => \@Test::Queue::Q4Pg::Lite::CONNECT_INFO,
    );
    ok($q);
    isa_ok($q, "Queue::Q4Pg::Lite");

    $q->disconnect;

    ok($q->insert($table, { v => 1 }));
    ok($q->insert($table, { v => 2 }));
    ok($q->clear($table));
}

{
    my $table   = $Test::Queue::Q4Pg::Lite::TABLES[0];
    my $timeout = 1;
    my $q = Queue::Q4Pg::Lite->connect(
        connect_info => \@Test::Queue::Q4Pg::Lite::CONNECT_INFO,
    );
    ok($q);
    isa_ok($q, "Queue::Q4Pg::Lite");

    ok( $q->insert($table, { v => 1 }), "insert" );
    ok( $q->next($table), "next" );
    ok( $q->fetch($table) );
    ok( $q->ack, "ack" );

    $q->disconnect;
}

END
{
    local $@;
    eval {
        my $dbh = DBI->connect(@Test::Queue::Q4Pg::Lite::CONNECT_INFO);
        foreach my $table (@Test::Queue::Q4Pg::Lite::TABLES) {
            $dbh->do("DROP TABLE $table");
        }
    };
}
