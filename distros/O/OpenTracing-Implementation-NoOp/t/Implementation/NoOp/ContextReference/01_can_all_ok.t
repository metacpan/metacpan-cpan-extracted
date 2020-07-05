use Test::Most;
use Test::OpenTracing::Interface::ContextReference qw/can_all_ok/;

use strict;
use warnings;

use OpenTracing::Implementation::NoOp::ContextReference;

can_all_ok('OpenTracing::Implementation::NoOp::ContextReference');

done_testing();
