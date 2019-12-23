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

my $value;
lives_ok
    { $value = $cache->get('key_that_exists') }
    'get key that exists lives when role is not applied';
is $value, 'I am here!', 'key returns expected value';

note 'Test strict empty cache';
my $strict_cache = Mojo::Cache->new->with_roles('+Strict')->strict_get(1);

throws_ok
    { $strict_cache->get('nonexistent_key') }
    qr/unknown key 'nonexistent_key'/,
    'nonexistent key throws when role applied and no values cached';

$strict_cache->strict_get(0);
lives_ok
    { $value = $strict_cache->get('nonexistent_key') }
    'get nonexistent key lives with strict_get 0';
is $value, undef, 'undef returned';

note 'Test strict non-empty cache';
$strict_cache = Mojo::Cache->new
                           ->set(key_that_exists => 'I am here!')
                           ->with_roles('+Strict')
                           ->strict_get(1)
                           ;

throws_ok
    { $strict_cache->get('nonexistent_key') }
    qr/unknown key 'nonexistent_key'/,
    'nonexistent key throws strict_get 1 and value cached';

lives_ok
    { $value = $strict_cache->get('key_that_exists') }
    'get key that exists lives with strict_get 1';
is $value, 'I am here!', 'expected value';

$strict_cache->strict_get(0);
lives_ok
    { $value = $strict_cache->get('nonexistent_key') }
    'get nonexistent key lives with strict_get 0';
is $value, undef, 'undef returned';

lives_ok
    { $value = $strict_cache->get('key_that_exists') }
    'get key that exists lives with strict_get 0';
is $value, 'I am here!', 'expected value';

done_testing;
