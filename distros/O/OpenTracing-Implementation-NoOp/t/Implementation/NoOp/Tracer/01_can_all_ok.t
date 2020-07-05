use Test::Most;
use Test::OpenTracing::Interface::Tracer qw/can_all_ok/;

use strict;
use warnings;

use OpenTracing::Implementation::NoOp::Tracer;

can_all_ok('OpenTracing::Implementation::NoOp::Tracer');

done_testing();
