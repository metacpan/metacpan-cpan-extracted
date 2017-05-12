use strict;
use warnings;

use Scalar::Util qw( blessed );
use Test::More tests => 9;

BEGIN { use_ok('Monitor::MetricsAPI') }

my $collector = Monitor::MetricsAPI->create(
    metrics => {
        test => {
            foo => 'counter',
            bar => 'counter',
        },
    }
);

ok(blessed($collector), 'collector created successfully');

ok(blessed($collector->metric('test/foo')), 'metric foo created');
ok(blessed($collector->metric('test/bar')), 'metric bar created');

cmp_ok($collector->metric('test/foo')->type, 'eq', 'counter', 'metric foo is a counter');
cmp_ok($collector->metric('test/bar')->type, 'eq', 'counter', 'metric bar is a counter');

cmp_ok($collector->metric('test/foo')->value, '==', 0, 'counter metric initialized to zero');

$collector->metric('test/foo')->increment;
$collector->metric('test/bar')->add(10);

cmp_ok($collector->metric('test/foo')->value, '==', 1, 'counter increment');
cmp_ok($collector->metric('test/bar')->value, '==', 10, 'counter add(10)');
