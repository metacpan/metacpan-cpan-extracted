# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Object-Collection.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More 'no_plan';    #tests => 'noplan';

use Test::More;
use lib 't/lib';
use Data::Dumper;

eval { 
    require Cache::Memcached;
};
if ( $@ ) {
    plan skip_all => 'Not found Cache::Memcached';
    }
$memd = new Cache::Memcached:: {
    'servers'            => ["127.0.0.1:11211"],
    'debug'              => 0,
    'compress_threshold' => 10_000,
    'namespace'          => time()
};

## check if run memcached
unless ( $memd->set( "__test___", '1' ) ) {
    plan skip_all => 'Memcached no running at 127.0.0.1:11211 ?';
}
else {

    plan tests => 25;
}

use_ok('Objects::Collection');
use_ok('Objects::Collection::Memcached');

$memd->set_compress_threshold(10_000);
$memd->enable_compress(0);
$memd->set_debug;
ok !( new Objects::Collection::Memcached:: ), 'empty params';
ok my $coll = ( new Objects::Collection::Memcached:: $memd), 'create';
ok !$coll->fetch_object(1), 'get non_exists';
is_deeply(
    $coll->create( 1 => { 2 => 2 } ),
    { '1' => { '2' => 2 } },
    'check set'
);

$coll->delete_objects( 1, 2, 3 );
ok !$coll->fetch_object(1), 'check delete';

is_deeply(
    $coll->create( 1 => { 2 => 2 }, 3 => { 4 => 4 } ),
    {
        '1' => { '2' => 2 },
        '3' => { '4' => 4 }
    },
    'check create'
);
ok my $t3 = $coll->fetch_object(3), 'get key 3';
isa_ok tied %$t3, 'Objects::Collection::ActiveRecord', 'check is ActiveRecord';
$t3->{5} = 5;
ok( ( tied %$t3 )->_changed(), 'check changed' );
$coll->store_changed;
$coll->release_objects;
ok my $t3_ = $coll->fetch_objects(3), 'get key 3';
is_deeply $t3_,
  {
    '3' => {
        '4' => 4,
        '5' => 5
    }
  },
  'check store_changed';
is_deeply $coll->list_ids, [3], 'check list_ids';
my $ns = 'ns1';
ok my $collns = ( new Objects::Collection::Memcached:: $memd, $ns ),
  "create with prefix $ns";
is_deeply $collns->list_ids, [], 'cache after init';
is $collns->_ns, $ns, 'check prefix attribute';

is_deeply $collns->create( 1 => { 2 => 2 }, 3 => { 6 => 6 } ),
  {
    '1' => { '2' => 2 },
    '3' => { '6' => 6 }
  },
  'create with ns';

is_deeply my $ns3 = $collns->fetch_object(3), { '6' => 6 }, 'get key 3';
$ns3->{7} = 7;
is_deeply $collns->fetch_object(3),
  {
    '6' => 6,
    '7' => 7
  },
  'changed key 3';
ok my $collns2 = ( new Objects::Collection::Memcached:: $memd, $ns ),
  "create2 with prefix $ns";
is_deeply $collns2->fetch_object(3), { '6' => 6 }, 'get key 3 from coll2';
$collns->store_changed();
$collns2->release_objects();
is_deeply $collns2->fetch_object(3),
  {
    '6' => 6,
    '7' => 7
  },
  'check store';
$collns2->release_objects();
is_deeply $collns->fetch_object(3),
  {
    '6' => 6,
    '7' => 7
  },
  "check before delete 3";
$collns->delete_objects(3);
ok !$collns2->fetch_object(3), 'check delete in memcache';

