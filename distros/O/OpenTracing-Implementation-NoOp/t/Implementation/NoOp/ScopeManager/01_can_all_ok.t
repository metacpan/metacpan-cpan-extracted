use Test::Most;
use Test::OpenTracing::Interface::ScopeManager qw/can_all_ok/;

use strict;
use warnings;

use OpenTracing::Implementation::NoOp::ScopeManager;

can_all_ok('OpenTracing::Implementation::NoOp::ScopeManager');

done_testing();
