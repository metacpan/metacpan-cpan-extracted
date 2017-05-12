#!perl

use Test::More;
use Postgredis;
use Test::PostgreSQL;

my $psql;
if ($ENV{TRAVIS}) {
    $ENV{PG_CONNECT_STR} = "postgresql:///travis_ci_test";
} elsif ($ENV{TEST_PG_CONNECT_STR}) {
    $ENV{PG_CONNECT_STR} = $ENV{TEST_PG_CONNECT_STR};
} else {
    $psql = Test::PostgreSQL->new() or plan
        skip_all => $test::postgresql::errstr;
    $ENV{PG_CONNECT_STR} = "postgresql:///test";
    $ENV{PG_CONNECT_DSN} = $psql->dsn;
}

my $db = Postgredis->new('test_namespace')->flushdb;

my $version = $db->pg->query('select version()')->array->[0];
my ($major,$minor,$sub) = ( $version =~ m[PostgreSQL (\d+)\.(\d+).(\d+)] );

plan skip_all => "need pg >= 9 ($version)" unless $major >= 9;
plan skip_all => "need pg >= 9.4 ($version)" unless $minor >= 4;
diag "Testing with PostgreSQL $major.$minor.$sub";
my $dbh = $db->pg->dbh;
{
    local $dbh->{PrintError} = 0;
    local $dbh->{RaiseError} = 0;
    my $skip = 0;
    my $sth = $dbh->prepare("select '5'::jsonb") or BAIL_OUT $DBI::errstr;
    $sth->execute or do { $skip = 1; };
    if ($skip) {
        $psql->stop;
        plan skip_all => "No jsonb datatype in execute ($DBI::errstr).";
    }
    my $got = $dbh->selectall_arrayref($sth);
    is_deeply $got, [['5']];
}

# Keys
ok $db->set("hi","there");
ok $db->set("hi","there");
is $db->get("hi"), "there";
ok $db->set("hi","here");
is $db->get("hi"), "here";
ok $db->set("hi:2","here");
ok $db->set("hi:3","here");
is_deeply $db->keys('hi:*'), [ 'hi:2', 'hi:3' ];
ok $db->exists("hi");
ok !$db->exists("hi9");
ok $db->del("hi:3");
ok !$db->exists("hi:3");

# JSON values
ok $db->set("hello", { world => 42 });
is_deeply($db->get("hello"), { world => 42 } );

# More values
for my $str (
    q[don't],
    q[xx"zz],
    q[zz\\z],
    q[rêsumé],
    q[♠	♡ ♢ ♣],
) {
    ok $db->set(val => $str);
    is $db->get(val), $str;
}

# Hashes
ok $db->hset("good",night => "moon"), "hset";
ok $db->hset("bad",moon => "rising"), "hset";
is $db->hget("good","night"), "moon", "hget";
is $db->hget("bad","moon"), "rising", "hget";
is_deeply $db->hgetall("good"),{ night => "moon" }, "hgetall";
ok $db->hdel("good","night"), "hdel";

# Sets
for my $i (5,4,2,1,3) {
    ok $db->sadd('nums',$i), "sadd";
}
is_deeply [ sort @{ $db->smembers('nums')} ], [1..5], "smembers";
ok $db->srem("nums",3), "srem";
is_deeply [ sort @{ $db->smembers('nums')} ], [1,2,4,5], "smembers";

# Sorted sets
ok $db->zadd(letters => 10 => 'c'), 'zadd';
ok $db->zadd(letters => 5 => 'd' ), 'zadd';
ok $db->zadd(letters => 1 => 'a'), 'zadd';
is $db->zscore(letters => 'a'), 1, 'zscore';
is $db->zscore(letters => 'c'), 10, 'zscore';
is $db->zscore(letters => 'd'), 5, 'zscore';
is_deeply $db->zrangebyscore('letters', 2, 20), ['d','c'], 'zrangebyscore';
ok $db->zrem(letters => 'a'), "zrem";
ok $db->zrem(letters => 'c'), "zrem";

# Sorted sets, real numbers
ok $db->zadd(pi => 3.21 => 'second'), 'zadd';
ok $db->zadd(pi => 3.14 => 'first'), 'zadd';
ok $db->zadd(pi => 3.21 => 'third'), 'zadd';
is_deeply $db->zrangebyscore('pi', 1, 4), [qw/first second third/], 'zrangebyscore';

# Counters
my $start = $db->incr("countme");
is $db->incr("countme"), $start + 1, "incr";
is $db->incr("countme"), $start + 2, "incr";
my $nother = $db->incr("countme2");
is $db->incr("countme2"), $nother + 1, "incr";

done_testing();

