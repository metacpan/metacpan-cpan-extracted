use Mojo::Base -strict;
use Test::More;
use Mojo::Cache;

my $cache = Mojo::Cache->new->with_roles('+GetDefault');

is $cache->get('key'), undef, 'unset key returns undef';

$cache->default('value');
is $cache->get('key'), 'value', 'default static attr value returned';

is
    $cache->get('other_key', 'override value'),
    'override value',
    'default value provided to get overrides default attr value';
is $cache->get('other_key'), 'override value', 'override value returned when override value not provided';

done_testing;
