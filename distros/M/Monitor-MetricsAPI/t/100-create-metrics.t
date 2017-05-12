use strict;
use warnings;

use Scalar::Util qw( blessed );
use Test::More tests => 4;

BEGIN { use_ok('Monitor::MetricsAPI') }

my $collector = Monitor::MetricsAPI->create(
    metrics => {
        test => {
            foo => 'counter',
        },
        bar => {
            baz => {
                zippitydoo => sub { 1; },
            },
        },
    }
);

ok(blessed($collector), 'collector created successfully');
ok(blessed($collector->metric('test/foo')), 'metric created at collector startup');
ok(blessed($collector->metric('bar/baz/zippitydoo')), 'callback metric created at collector startup');
