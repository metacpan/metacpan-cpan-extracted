use strict;
use warnings;

use Scalar::Util qw( blessed );
use Test::More tests => 8;

BEGIN { use_ok('Monitor::MetricsAPI') }

my $collector = Monitor::MetricsAPI->create(
    metrics => {
        test => {
            foo => sub { "foo bar baz" },
        },
    }
);

ok(blessed($collector), 'collector created successfully');

ok(blessed($collector->metric('test/foo')), 'metric foo created');

cmp_ok($collector->metric('test/foo')->type, 'eq', 'callback', 'metric foo is a callback');
cmp_ok($collector->metric('test/foo')->value, 'eq', "foo bar baz", 'callback value okay');

$collector->metric('test/foo')->callback(sub { "baz bar foo" });

cmp_ok($collector->metric('test/foo')->value, 'eq', "baz bar foo", 'callback redefined');

$collector->add_metric('test/bar', 'callback', sub { "xyzzy" });

ok(blessed($collector->metric('test/bar')), 'callback metric added in-flight');
cmp_ok($collector->metric('test/bar')->value, 'eq', 'xyzzy', 'in-flight callback metric value okay');
