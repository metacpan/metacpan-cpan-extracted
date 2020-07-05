use Test::Most;
use Test::OpenTracing::Interface::SpanContext qw/can_all_ok/;

use strict;
use warnings;

use OpenTracing::Implementation::NoOp::SpanContext;

can_all_ok('OpenTracing::Implementation::NoOp::SpanContext');

done_testing();
