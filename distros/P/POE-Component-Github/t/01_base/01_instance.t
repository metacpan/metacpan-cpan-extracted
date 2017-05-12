use strict;
use warnings;
use Test::More tests => 2;
use POE qw(Component::Github);

my $github = POE::Component::Github->spawn();
isa_ok( $github, 'POE::Component::Github');

$poe_kernel->post( $github->get_session_id, 'shutdown' );

$poe_kernel->run();
pass("Okay the kernel returned");
