use Mojo::Base -strict;
use Test::More;
use Mojo::Cache;

my $cache = Mojo::Cache->new->with_roles('+GetDefault');

is $cache->get('key'), undef, 'unset key returns undef';
is $cache->get('key', 'value'), 'value', 'default static value returned';
is $cache->get('key'), 'value', 'previously set default returned when no default provided';
is $cache->get('key', 'other_value'), 'value', 'previously set default returned when new default provided';

is $cache->get('other_key'), undef, 'unset key unaffected by previously set default';
is $cache->get('other_key', 'other_value'), 'other_value', 'new default works for new value';
is $cache->get('other_key'), 'other_value', 'previously set default returned when no default provided';
is $cache->get('other_key', 'new_value'), 'other_value', 'previously set default returned when new default provided';

done_testing;
