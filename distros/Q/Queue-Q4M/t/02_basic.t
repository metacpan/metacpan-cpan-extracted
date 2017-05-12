use strict;
use lib("t/lib");
use Test::Queue::Q4M (tests => 73);

BEGIN
{
    use_ok("Queue::Q4M");
}

{
    my $table = $Test::Queue::Q4M::TABLES[0];
    my $q = Queue::Q4M->connect(
        connect_info => \@Test::Queue::Q4M::CONNECT_INFO,
    );
    ok($q);
    isa_ok($q, "Queue::Q4M");
    
    my $max = 32;
    for my $i (1..$max) {
        ok($q->insert($table, { v => $i }));
    }
    
    my $count = 0;
    while ($q->next($table)) {
        my $h = $q->fetch_hashref();
        $count++;
        last if $h->{v} == $max;
    }
    
    is($count, $max);
    $q->disconnect;
}

{
    my $table = $Test::Queue::Q4M::TABLES[0];
    my $q = Queue::Q4M->connect(
        table => $table,
        connect_info => \@Test::Queue::Q4M::CONNECT_INFO,
    );
    ok($q);
    isa_ok($q, "Queue::Q4M");

    diag("Going to block for 5 seconds...");
    my $before = time();
    $q->next($table, 5);

    # This time difference could be off by a second or so,
    # so allow that much diffference
    my $diff = time() - $before;
    ok( $diff >= 4, "next() with timeout waited for 4 seconds ($diff)");
}

{
    my $q = Queue::Q4M->connect(
        connect_info => \@Test::Queue::Q4M::CONNECT_INFO,
    );
    ok($q);
    isa_ok($q, "Queue::Q4M");

    # Insert into a random table
    my $table = $Test::Queue::Q4M::TABLES[rand(@Test::Queue::Q4M::TABLES)];
    $q->insert( $table , { v => 1 } );

    my $max = 1;
    my $count = 0;
    while (my $which = $q->next(@Test::Queue::Q4M::TABLES, 5)) {
        is ($which, $table, "got from the table that we inserted" );
        my ($v) = $q->fetch( $which, 'v' );
        $count++;
        last if $count >= $max;
    }
}

{
    my $table   = $Test::Queue::Q4M::TABLES[0];
    my $timeout = 1;
    my $q = Queue::Q4M->connect(
        connect_info => \@Test::Queue::Q4M::CONNECT_INFO,
    );
    ok($q);
    isa_ok($q, "Queue::Q4M");

    my $rv = $q->next($table, $timeout);
    ok( ! $rv, "should return false. got (" . ($rv || '') . ")" );

    $q->disconnect;
}

{
    my $table   = $Test::Queue::Q4M::TABLES[0];
    my $timeout = 1;
    my $q = Queue::Q4M->connect(
        connect_info => \@Test::Queue::Q4M::CONNECT_INFO,
    );
    ok($q);
    isa_ok($q, "Queue::Q4M");

    my $max = 32;
    for my $i (1..$max) {
        $q->insert($table, { v => $i });
    }

    my $cond  = "$table:v>16";
    my $count = 0;
    while (my $rv = $q->next($cond)) {
        is($rv, $table);

        my $h = $q->fetch_hashref();
        $count++;
        last if $h->{v} == $max;
    }

    is($count, 16);

    $q->dbh->do("DELETE FROM $table");
    $q->disconnect;
}

{
    my $table   = $Test::Queue::Q4M::TABLES[0];
    my $timeout = 1;
    my $q = Queue::Q4M->connect(
        connect_info => \@Test::Queue::Q4M::CONNECT_INFO,
    );
    ok($q);
    isa_ok($q, "Queue::Q4M");

    $q->disconnect;

    ok($q->insert($table, { v => 1 }));
    ok($q->clear($table));
}

{
    my $table   = $Test::Queue::Q4M::TABLES[0];
    my $timeout = 1;
    my $q = Queue::Q4M->connect(
        connect_info => \@Test::Queue::Q4M::CONNECT_INFO,
    );
    ok($q);
    isa_ok($q, "Queue::Q4M");

    ok( $q->insert($table, { v => 1 }), "insert" );
    ok( $q->next($table), "next" );

    ok( $q->fetch($table) );
}

END
{
    local $@;
    eval {
        my $dbh = DBI->connect(@Test::Queue::Q4M::CONNECT_INFO);
        foreach my $table (@Test::Queue::Q4M::TABLES) {
            $dbh->do("DROP TABLE $table");
        }   
    };
}
