use Mojo::Base -strict;
use Test::More;
use Mojo::Cache;

my $cache = Mojo::Cache->new->with_roles('+GetDefault');

is $cache->get('key'), undef, 'unset key returns undef';

$cache->default(sub { "value: $_" });
is $cache->get('key'), 'value: key', 'default sub value returned';

$cache->clear_default;
is $cache->get('key'), 'value: key', 'previously set default returned when no default set';

$cache->default(sub { "other_value: $_" });
is $cache->get('key'), 'value: key', 'previously set default returned when new default set';

is $cache->get('other_key'), 'other_value: other_key', 'unset key gets current default';
$cache->clear_default;
is $cache->get('other_key'), 'other_value: other_key', 'previously set default returned when no default set';

note 'Test key is available as first argument';
is $cache->get('first_arg_key'), undef, 'unset key returns undef';

$cache->default(sub { "value: $_[0]" });
is $cache->get('first_arg_key'), 'value: first_arg_key', 'default sub value returned';

$cache->clear_default;
is $cache->get('first_arg_key'), 'value: first_arg_key', 'previously set default returned when no default set';

$cache->default(sub { "other_value: $_[0]" });
is $cache->get('first_arg_key'), 'value: first_arg_key', 'previously set default returned when new default set';

done_testing;
