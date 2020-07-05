use Test::Most;
use Test::OpenTracing::Interface::Scope qw/can_all_ok/;

use strict;
use warnings;

use OpenTracing::Implementation::NoOp::Scope;

can_all_ok('OpenTracing::Implementation::NoOp::Scope');

done_testing();
