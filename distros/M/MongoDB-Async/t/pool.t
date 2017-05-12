use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Warn;
use Coro;
use Coro::EV;
use MongoDB::Async::Timestamp; # needed if db is being run as master

use MongoDB::Async;
use MongoDB::Async::Pool;


my $pool;
my @conns;

eval {
    my $host = "127.0.0.1";
    if (exists $ENV{MONGOD}) {
        $host = $ENV{MONGOD};
    }
    $pool = MongoDB::Async::Pool->new({host => $host, ssl => $ENV{MONGO_SSL}}, { timeout => 2});
};

if ($@) {
    plan skip_all => $@;
}
else {
    plan tests => 6;
}

push @conns, $pool->get;
push @conns, $pool->get;
push @conns, $pool->get;
push @conns, $pool->get;
push @conns, $pool->get;


	
is($pool->connections_in_use, 5, "allocating connections - connections_in_use");
is($pool->connections_in_pool, 0, "allocating connections - connections_in_pool");

#  test that we not creating new connection when already have 5 connection in pool
@conns = ();
push @conns, $pool->get;
push @conns, $pool->get;
push @conns, $pool->get;
push @conns, $pool->get;
push @conns, $pool->get;
@conns = ();


is($pool->connections_in_use, 0, "keeping connections - connections_in_use");
is($pool->connections_in_pool + @{$pool->{pool}}, 10, "keeping connections - connections_in_pool");


my $coll = $pool->get->driver_test_db->d_test_coll;

$coll->save({ _id => $_ , nyan => ("nyan" x 4096)}) for (1...3000);

# $pool->max_conns(1);

my $queries_running = 0;
my $max_running = 0;
my $queries_completed = 0;

async {
	# warn 'start';
	
	$max_running = $queries_running if $queries_running > $max_running;
	$queries_running++;
	$pool->get->driver_test_db->d_test_coll->find()->data;
	$queries_running--;
	
	$queries_completed++;
	
	if($queries_completed == 5){
		is($queries_completed, 5, 'all async queries compleated');
	
		$pool->get->driver_test_db->d_test_coll->drop();
		
		# is($max_running, 3, 'max_conn blocks coro');
		# TODO: write tests for testing timeout and max_conns. I tested it manually and it seems OK
		
		
		# global destruction not detected when running make test. Cleanup
		$_->{_parent_pool} = undef for @{$pool->{pool}};
		exit 0;
	}
	
	# warn 'done';
} for (1..5);

async {
	schedule while( $queries_running == 1 );
	
	ok($queries_running > 1, 'async queries in multiple connections');
	
};


# warn 'start loop';
my $w = EV::timer 3600, 3600, sub {}; # prevent EV::loop from exiting
EV::loop;