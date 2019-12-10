use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Mojo::Cache;

note 'Test non-strict cache';
my $cache = Mojo::Cache->new;

lives_ok
    { $cache->get('nonexistent_key') }
    'nonexistent key lives when role not applied and no values cached';

$cache->set(key_that_exists => 'I am here!');
lives_ok
    { $cache->get('nonexistent_key') }
    'nonexistent key lives when role not applied and a value has been cached';

note 'Test strict cache';
my $strict_cache = Mojo::Cache->new->with_roles('+Strict');

throws_ok
    { $strict_cache->get('nonexistent_key') }
    qr/unknown key 'nonexistent_key'/,
    'nonexistent key throws when role applied and no values cached';

$strict_cache->set(key_that_exists => 'I am here!');
throws_ok
    { $strict_cache->get('nonexistent_key') }
    qr/unknown key 'nonexistent_key'/,
    'nonexistent key throws when role applied and a value has been cached';

my $value;
lives_and
    { $value = $strict_cache->get('key_that_exists') }
    'key that exists lives when role is applied';
is $value, 'I am here!', 'key returns expected value';

done_testing;
