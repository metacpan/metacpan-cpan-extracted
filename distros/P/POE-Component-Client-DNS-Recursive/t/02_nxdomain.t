use strict;
use warnings;
use Test::More tests => 4;

use POE qw(Component::Client::DNS::Recursive);

POE::Session->create(
  package_states => [
	'main', [qw(_start _stop _child _response)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  POE::Component::Client::DNS::Recursive->resolve(
	event => '_response',
	host => 'clock.badger',
  );
  return;
}

sub _stop {
  pass('Reference has gone');
  return;
}

sub _child {
  pass('Child ' . $_[ARG0]);
  return;
}

sub _response {
  my $error = $_[ARG0]->{error};
  return unless $error;
  is( $error, 'NXDOMAIN', 'No such domain' );
  return;
}
