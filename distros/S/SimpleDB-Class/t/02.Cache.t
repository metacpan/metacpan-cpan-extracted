use Test::More tests => 5;
use Test::Deep;
use lib '../lib';

use_ok( 'SimpleDB::Class::Cache' );
my $servers = [
    {'socket' => '/tmp/foo/bar'},
    {'host' => '127.0.0.1', port=>'11211'},
];
my $cache = SimpleDB::Class::Cache->new(servers=>$servers);

isa_ok($cache, 'SimpleDB::Class::Cache');

cmp_deeply($cache->servers, $servers, 'can get the servers list back');

isa_ok($cache->memcached, 'Memcached::libmemcached');

is($cache->fix_key('domain','test this'), 'domain:test_this', 'keys with spaces are fixed');

# everything else requires a connection
