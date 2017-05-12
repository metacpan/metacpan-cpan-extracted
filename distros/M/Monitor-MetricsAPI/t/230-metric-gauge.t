use strict;
use warnings;

use Scalar::Util qw( blessed );
use Test::More tests => 9;

BEGIN { use_ok('Monitor::MetricsAPI') }

my $collector = Monitor::MetricsAPI->create(
    metrics => {
        test => {
            foo => 'gauge',
            bar => 'gauge',
        },
    }
);

ok(blessed($collector), 'collector created successfully');

ok(blessed($collector->metric('test/foo')), 'metric foo created');
ok(blessed($collector->metric('test/bar')), 'metric bar created');

cmp_ok($collector->metric('test/foo')->type, 'eq', 'gauge', 'metric foo is a gauge');
cmp_ok($collector->metric('test/bar')->type, 'eq', 'gauge', 'metric bar is a gauge');

cmp_ok($collector->metric('test/foo')->value, '==', 0, 'gauge metric initialized to zero');

$collector->metric('test/foo')->set(50);
$collector->metric('test/bar')->set(10);

cmp_ok($collector->metric('test/foo')->value, '==', 50, 'gauge set(50)');
cmp_ok($collector->metric('test/bar')->value, '==', 10, 'gauge set(10)');
