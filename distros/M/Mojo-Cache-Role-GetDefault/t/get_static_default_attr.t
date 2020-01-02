use Mojo::Base -strict;
use Test::More;
use Mojo::Cache;

my $cache = Mojo::Cache->new->with_roles('+GetDefault');

is $cache->get('key'), undef, 'unset key returns undef';

$cache->default('value');
is $cache->get('key'), 'value', 'default static value returned';

$cache->clear_default;
is $cache->get('key'), 'value', 'previously set default returned when no default set';

$cache->default('other_value');
is $cache->get('key'), 'value', 'previously set default returned when new default provided';

is $cache->get('other_key', 'other_value'), 'other_value', 'new default works for new key';

$cache->clear_default;
is $cache->get('other_key'), 'other_value', 'previously set default returned when no default set';

$cache->default('new_value');
is $cache->get('other_key'), 'other_value', 'previously set default returned when new default set';

done_testing;
