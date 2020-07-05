use Test::Most;
use Test::OpenTracing::Interface::Scope qw/can_all_ok/;

use strict;
use warnings;

use OpenTracing::Implementation::DataDog::Scope;
can_all_ok('OpenTracing::Implementation::DataDog::Scope');

done_testing();
