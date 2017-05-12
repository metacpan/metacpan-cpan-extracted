use strict;
use warnings;

use Scalar::Util qw( blessed );
use Test::More tests => 5;

BEGIN { use_ok('Monitor::MetricsAPI') }

my $collector = Monitor::MetricsAPI->create(
    listen => '*:8200',
);

ok(blessed($collector), 'collector created successfully');
ok(blessed($collector->servers->{'0.0.0.0:8200'}), 'listener added');

$collector->add_server('*:8201');

ok(blessed($collector->servers->{'0.0.0.0:8200'}), 'original listener still present');
ok(blessed($collector->servers->{'0.0.0.0:8201'}), 'new listener present');
