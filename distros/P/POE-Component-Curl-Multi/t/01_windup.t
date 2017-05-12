use strict;
use warnings;
use Test::More 'no_plan';
use POE qw[Component::Curl::Multi];

my $multi = POE::Component::Curl::Multi->spawn();
isa_ok( $multi, 'POE::Component::Curl::Multi' );
$multi->shutdown;
$poe_kernel->run();
pass('Wound down');
exit 0;
