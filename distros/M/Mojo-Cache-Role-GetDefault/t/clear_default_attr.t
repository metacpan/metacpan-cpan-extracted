use Mojo::Base -strict;
use Test::More;
use Mojo::Cache;

my $cache = Mojo::Cache->new->with_roles('+GetDefault');

is $cache->get('key'), undef, 'unset key returns undef';

$cache->default('default');
is $cache->get('key'), 'default', 'default attr value returned';

$cache->clear_default;
is $cache->get('key'), 'default', 'previously set default returned when no default provided';

is $cache->get('other_key'), undef, 'no default returned after clearing default';
is $cache->get('other_other_key'), undef, 'no default returned after clearing default';

done_testing;
