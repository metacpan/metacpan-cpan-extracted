use Mojo::Base -strict;
use Test::More;
use Mojo::Cache;

my $cache = Mojo::Cache->new->with_roles('+GetDefault');

is $cache->get('key'), undef, 'unset key returns undef';
is $cache->get('key', sub { "value: $_" }), 'value: key', 'default sub value returned';
is $cache->get('key'), 'value: key', 'previously set default returned when no default provided';
is $cache->get('key', sub { 'other_value' }), 'value: key', 'previously set default returned when new default provided';

is $cache->get('other_key'), undef, 'unset key unaffected by previously set default';
is $cache->get('other_key', sub { "other_value: $_" }), 'other_value: other_key', 'new default sub works for new value';
is $cache->get('other_key'), 'other_value: other_key', 'previously set default returned when no default provided';
is
    $cache->get('other_key', sub { "new_value: $_" }),
    'other_value: other_key',
    'previously set default returned when new default provided';

note 'Test key is available as first argument';
is $cache->get('first_arg_key'), undef, 'unset key returns undef';

is $cache->get('first_arg_key', sub { "value: $_[0]" }), 'value: first_arg_key', 'default sub value returned';

is
    $cache->get('first_arg_key', sub { "new_value: $_[0]" }),
    'value: first_arg_key',
    'previously set default returned when new default provided';

done_testing;
