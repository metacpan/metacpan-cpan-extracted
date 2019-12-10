use Mojo::Base -strict;
use Test::More;
use Mojo::Cache;

my $cache = Mojo::Cache->new(max_keys => 1)->with_roles('+Exists');

ok !$cache->exists('key'), 'exists returns false';
is $cache->get('key'), undef, 'get returns undef when key does not exist';

$cache->set(key => 'value');
ok $cache->exists('key'), 'exists returns true';
is $cache->get('key'), 'value', 'get returns expected value when key exists';

note 'Test cache eviction';
ok !$cache->exists('other_key'), 'exists returns false';
is $cache->get('other_key'), undef, 'get returns undef when key does not exist';

$cache->set(other_key => 'other_value');
ok $cache->exists('other_key'), 'exists returns true';
is $cache->get('other_key'), 'other_value', 'get returns expected value when key exists';

ok !$cache->exists('key'), 'exists returns false';
is $cache->get('key'), undef, 'get returns undef when key does not exist';

done_testing;
