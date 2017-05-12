use strict;
use warnings;

use Scalar::Util qw( refaddr );
use Test::More tests => 2;

BEGIN { use_ok('Monitor::MetricsAPI') }

my $coll1 = Monitor::MetricsAPI->create;
my $coll2 = Monitor::MetricsAPI->create;

cmp_ok(refaddr($coll1), '==', refaddr($coll2), 'create always returns the same collector');
