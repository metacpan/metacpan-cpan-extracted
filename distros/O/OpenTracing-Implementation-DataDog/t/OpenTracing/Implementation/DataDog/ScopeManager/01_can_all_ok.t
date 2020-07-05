use Test::Most;
use Test::OpenTracing::Interface::ScopeManager qw/can_all_ok/;

use strict;
use warnings;

use OpenTracing::Implementation::DataDog::ScopeManager;
can_all_ok('OpenTracing::Implementation::DataDog::ScopeManager');

done_testing();
