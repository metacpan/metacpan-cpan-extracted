use Test::More;
use PGObject::Util::AsyncPool;

#Setup

plan skip_all => 'DATABASE_TESTING is not set' unless $ENV{DATABASE_TESTING};
my $masterdbh = DBI->connect('dbi:Pg:dbname=postgres', undef, undef) || plan skip_all => 'Could not connect to "dbi:Pg:dbname=postgres"';
$masterdbh->do("CREATE DATABASE $ENV{DATABASE_TESTING}") || plan skip_all => 'Could not create database $ENV{DATABASE_TESTING}';;


plan tests => 603;

# Basic Tests

my $pool = PGObject::Util::AsyncPool->new("dbi:Pg:dbname=$ENV{DATABASE_TESTING}", undef, undef, undef, {pollfreq=>0.1});

ok($pool, 'Got a pool');

for my $num(1 .. 300) {
   my $callback = sub {
       my $sth = shift;
       my ($val) = $sth->fetchrow_array;
       is($num, $val, "Test run $num got right val");
   };
   $pool->run('select ?', $callback, [$num]);
}

# Queing Tests

#clear loop
$pool->poll_loop;

$pool->run('select pg_sleep(2)', sub {ok(1, "Callback Triggered on sleep") }, []);

for my $num(1 .. 300) {
   my $callback = sub {
       my $sth = shift;
       my ($val) = $sth->fetchrow_array;
       is($num, $val, "Test run $num got right val");
   };
   $pool->run("select ?", $callback, [$num]);
}


$pool->poll_loop;
undef $pool; # trigger destructors on connections

ok($masterdbh->do("DROP DATABASE $ENV{DATABASE_TESTING}"), 'Restored to consistent state');
$masterdbh->disconnect;
