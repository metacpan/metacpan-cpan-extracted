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
my $strict_cache = Mojo::Cache->new->with_roles('+Strict');

throws_ok
    { $strict_cache->get('nonexistent_key') }
    qr/unknown key 'nonexistent_key'/,
    'nonexistent key throws when role applied and no values cached';

throws_ok
    { $strict_cache->set(new_key => 'I die') }
    qr/cannot set in strict_set mode/,
    'set in empty strict cache throws';

note 'Test strict non-empty cache';
my $strict_nonempty_cache = Mojo::Cache->new
                              ->set(key_that_exists => 'I am here!')
                              ->with_roles('+Strict')
                              ;
throws_ok
    { $strict_nonempty_cache->get('nonexistent_key') }
    qr/unknown key 'nonexistent_key'/,
    'nonexistent key throws when role applied and a value has been cached';

throws_ok
    { $strict_nonempty_cache->set(new_key => 'I die') }
    qr/cannot set in strict_set mode/,
    'set in non-empty strict cache throws';

lives_ok
    { $value = $strict_nonempty_cache->get('key_that_exists') }
    'get key that exists lives when role is applied';
is $value, 'I am here!', 'key returns expected value';

done_testing;
