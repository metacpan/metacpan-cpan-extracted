
use Test;
BEGIN { plan tests => 1, onfail => sub { print "Bail out!\n"; } };

use POE; #stupidly required to get $poe_kernel object
use POE::Component::LaDBI;

$poe_kernel->run(); #stupidly required to suppress POE::Kernel::DESTROY warning

ok(1); # If we made it this far, we're ok.
