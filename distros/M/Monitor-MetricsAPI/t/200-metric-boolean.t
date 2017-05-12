use strict;
use warnings;

use Scalar::Util qw( blessed );
use Test::More tests => 11;

BEGIN { use_ok('Monitor::MetricsAPI') }

my $collector = Monitor::MetricsAPI->create(
    metrics => {
        test => {
            foo => 'boolean',
            bar => 'boolean',
        },
    }
);

ok(blessed($collector), 'collector created successfully');

ok(blessed($collector->metric('test/foo')), 'metric foo created');
ok(blessed($collector->metric('test/bar')), 'metric bar created');

cmp_ok($collector->metric('test/foo')->type, 'eq', 'boolean', 'metric foo is a boolean');
cmp_ok($collector->metric('test/bar')->type, 'eq', 'boolean', 'metric bar is a boolean');

ok(!defined $collector->metric('test/foo')->value, 'boolean metric initialized undef');

$collector->metric('test/foo')->true;
$collector->metric('test/bar')->false;

cmp_ok($collector->metric('test/foo')->value, '==', 1, 'true boolean is true');
cmp_ok($collector->metric('test/bar')->value, '==', 0, 'false boolean is false');

$collector->metric('test/bar')->true;

cmp_ok($collector->metric('test/bar')->value, '==', 1, 'false boolean successfully changed to true');

$collector->metric('test/bar')->unknown;

ok(!defined $collector->metric('test/bar')->value, 'boolean metric set to unknown');
