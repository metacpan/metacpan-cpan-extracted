use Test::Most;
use Test::OpenTracing::Interface::Tracer qw/can_all_ok/;

use strict;
use warnings;

use OpenTracing::Implementation::DataDog::Tracer;
can_all_ok('OpenTracing::Implementation::DataDog::Tracer');

done_testing();
