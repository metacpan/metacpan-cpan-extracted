use strict;
use warnings;

use Scalar::Util qw( blessed );
use Test::More tests => 17;

BEGIN { use_ok('Monitor::MetricsAPI') }

my $collector = Monitor::MetricsAPI->create(
    metrics => {
        test => {
            foo => 'list',
        },
    }
);

ok(blessed($collector), 'collector created successfully');

ok(blessed($collector->metric('test/foo')), 'metric foo created');

cmp_ok($collector->metric('test/foo')->type, 'eq', 'list', 'metric foo is a list');
cmp_ok(ref($collector->metric('test/foo')->value), 'eq', 'ARRAY', 'metric value is array reference');

ok(scalar @{$collector->metric('test/foo')->value} == 0, 'list metric initialized empty');

ok($collector->metric('test/foo')->size == 0, 'size method passes');

$collector->metric('test/foo')->push(1, 2, 3, 4);

ok($collector->metric('test/foo')->size == 4, 'size method shows four entries');
is_deeply($collector->metric('test/foo')->value, [1,2,3,4], 'list values match');

ok(! $collector->metric('test/foo')->has_limit, 'list has no limit');

$collector->metric('test/foo')->limit(3);

ok($collector->metric('test/foo')->has_limit, 'list limit has been set');

is_deeply($collector->metric('test/foo')->value, [2,3,4], 'too-long list truncated properly after limit set');

$collector->metric('test/foo')->push(5);

is_deeply($collector->metric('test/foo')->value, [3,4,5], 'old list entries dropped to stay within limit');

$collector->metric('test/foo')->clear_limit;

ok(! $collector->metric('test/foo')->has_limit, 'list limit has been removed');

$collector->metric('test/foo')->push(6,7,8);

is_deeply($collector->metric('test/foo')->value, [3,4,5,6,7,8], 'list is accepting more values properly');

$collector->metric('test/foo')->limit(20);

ok($collector->metric('test/foo')->has_limit, 'list limit has been set much higher than size');
is_deeply($collector->metric('test/foo')->value, [3,4,5,6,7,8], 'list not modified after larger-than-list limit set');

