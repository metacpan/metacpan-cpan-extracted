use Test::Most;
use Test::OpenTracing::Interface::Span qw/can_all_ok/;

use strict;
use warnings;

use OpenTracing::Implementation::NoOp::Span;

can_all_ok('OpenTracing::Implementation::NoOp::Span');

done_testing();
