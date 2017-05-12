use blib;
use strict;
use POE qw(Component::Server::DNS);

my $dns_server = POE::Component::Server::DNS->spawn( port => 5353 );

POE::Session->create(
	package_states => [ 'main' => [ qw(_start) ], ],
);

$poe_kernel->run();
exit 0;

sub _start {
  $poe_kernel->alias_set('foo');
  undef;
}
