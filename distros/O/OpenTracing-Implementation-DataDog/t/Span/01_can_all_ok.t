use Test::Most;
use Test::OpenTracing::Interface::Span qw/can_all_ok/;

use strict;
use warnings;

use OpenTracing::Implementation::DataDog::Span;
can_all_ok('OpenTracing::Implementation::DataDog::Span');

done_testing();
