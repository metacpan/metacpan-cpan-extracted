use strict;
use warnings;

use Scalar::Util qw( blessed );
use Test::More tests => 7;

use DateTime;
no warnings 'redefine';
local *DateTime::_core_time = sub { return 823812309; };

BEGIN { use_ok('Monitor::MetricsAPI') }

my $collector = Monitor::MetricsAPI->create(
    metrics => {
        test => {
            foo => 'timestamp',
        },
    }
);

ok(blessed($collector), 'collector created successfully');

ok(blessed($collector->metric('test/foo')), 'metric foo created');

cmp_ok($collector->metric('test/foo')->type, 'eq', 'timestamp', 'metric foo is a timestamp');

ok(!defined $collector->metric('test/foo')->value, 'counter metric initialized as undefined');

$collector->metric('test/foo')->now;

cmp_ok($collector->metric('test/foo')->value, 'eq', '1996-02-08T20:45:09Z', 'valid ISO-8601 string');

cmp_ok(ref($collector->metric('test/foo')->dt), 'eq', 'DateTime', 'metric has DateTime attribute');

