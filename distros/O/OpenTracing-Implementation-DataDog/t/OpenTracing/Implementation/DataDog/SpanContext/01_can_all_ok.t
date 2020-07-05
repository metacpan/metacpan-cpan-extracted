use Test::Most;
use Test::OpenTracing::Interface::SpanContext qw/can_all_ok/;

use strict;
use warnings;

use OpenTracing::Implementation::DataDog::SpanContext;
can_all_ok('OpenTracing::Implementation::DataDog::SpanContext');

done_testing();
