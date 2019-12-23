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
my $strict_cache = Mojo::Cache->new->with_roles('+Strict')->strict_set(1);

throws_ok
    { $strict_cache->set(key => 'value') }
    qr/cannot set in strict_set mode/,
    'cannot set with strict_set 0 in empty cache';

$strict_cache->strict_set(0);
lives_ok
    { $strict_cache->set(key => 'value') }
    'set allowed with strict_set 0 in empty cache';
is $strict_cache->get('key'), 'value', 'correct value set';

note 'Test strict non-empty cache';
$strict_cache = Mojo::Cache->new
                           ->set(key_that_exists => 'I am here!')
                           ->with_roles('+Strict')
                           ->strict_set(1)
                           ;

is $strict_cache->get('key_that_exists'), 'I am here!', 'expected value returned for existing key';
throws_ok
    { $strict_cache->set(key => 'value') }
    qr/cannot set in strict_set mode/,
    'non-empty cache cannot set with strict_set 1';

$strict_cache->strict_set(0);
lives_ok
    { $strict_cache->set(key => 'value') }
    'set allowed with strict_set 0 in non-empty cache';
is $strict_cache->get('key_that_exists'), 'I am here!', 'expected value returned for existing key';
is $strict_cache->get('key'), 'value', 'correct value set';

done_testing;
