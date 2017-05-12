use strict;
use lib("t/lib");
use Test::Queue::Q4M (tests => 38);

BEGIN
{
    use_ok("Queue::Q4M");
}


my $dsn      = $ENV{Q4M_DSN};
my $username = $ENV{Q4M_USER};
my $password = $ENV{Q4M_PASSWORD};
my @tables   = map {
    join('_', qw(q4m test table), $_, $$)
} 1..10;

if ($dsn !~ /^dbi:mysql:/i) {
    $dsn = "dbi:mysql:dbname=$dsn";
}

my $dbh = DBI->connect($dsn, $username, $password);
foreach my $table (@tables) {
    $dbh->do(<<EOSQL);
        CREATE TABLE IF NOT EXISTS $table (
            v INTEGER NOT NULL
        ) ENGINE=queue;
EOSQL
}

{
    my $table = $tables[0];
    my $q = Queue::Q4M->connect(
        connect_info => [ $dsn, $username, $password ]
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

    my $status = $q->status;
    isa_ok($status, 'Queue::Q4M::Status');

    ok($status->rows_written);

}

END
{
    local $@;
    eval {
        foreach my $table (@tables) {
            $dbh->do("DROP TABLE $table");
        }   
    };
}

