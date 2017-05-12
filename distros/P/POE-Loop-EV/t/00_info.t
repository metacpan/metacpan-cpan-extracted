use strict;
use warnings;

use Test::More;
use EV;
use POE 'Loop::EV';

is(POE::Kernel::poe_kernel_loop(), 'POE::Loop::EV', 'Using EV event loop for POE');

my $method = POE::Loop::EV::_backend_name( EV::backend() );
diag("Using EV $EV::VERSION with default backend '$method'");

done_testing;
