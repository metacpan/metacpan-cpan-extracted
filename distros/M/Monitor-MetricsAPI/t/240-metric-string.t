use strict;
use warnings;

use Scalar::Util qw( blessed );
use Test::More tests => 9;

BEGIN { use_ok('Monitor::MetricsAPI') }

my $collector = Monitor::MetricsAPI->create(
    metrics => {
        test => {
            foo => 'string',
            bar => 'string',
        },
    }
);

ok(blessed($collector), 'collector created successfully');

ok(blessed($collector->metric('test/foo')), 'metric foo created');
ok(blessed($collector->metric('test/bar')), 'metric bar created');

cmp_ok($collector->metric('test/foo')->type, 'eq', 'string', 'metric foo is a string');
cmp_ok($collector->metric('test/bar')->type, 'eq', 'string', 'metric bar is a string');

cmp_ok($collector->metric('test/foo')->value, 'eq', '', 'string metric initialized to empty string');

$collector->metric('test/foo')->set('foo bar baz');
$collector->metric('test/bar')->set('xyzzy');

cmp_ok($collector->metric('test/foo')->value, 'eq', 'foo bar baz', 'string set');
cmp_ok($collector->metric('test/bar')->value, 'eq', 'xyzzy', 'string set');
