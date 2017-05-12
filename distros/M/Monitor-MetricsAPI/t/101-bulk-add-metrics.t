use strict;
use warnings;

use Scalar::Util qw( blessed );
use Test::More tests => 8;

BEGIN { use_ok('Monitor::MetricsAPI') }

my $collector = Monitor::MetricsAPI->create(
    metrics => {
        test => {
            foo => 'counter',
        },
    }
);

ok(blessed($collector), 'collector created successfully');
ok(blessed($collector->metric('test/foo')), 'metric created at collector startup');

my $same_collector = Monitor::MetricsAPI->create(
    metrics => {
        test => {
            bar => 'counter',
        },
        baz => {
            xyzzy => 'counter',
        }
    }
);

ok(blessed($same_collector), 'collector retrieved successfully');
ok(blessed($same_collector->metric('test/bar')), 'bulk add test metric');
ok(blessed($same_collector->metric('baz/xyzzy')), 'bulk add xyzzy metric');

ok(blessed($collector->metric('test/bar')), 'bulk add metric accessible through original collector');
ok(blessed($collector->metric('test/foo')), 'original metric still present');
