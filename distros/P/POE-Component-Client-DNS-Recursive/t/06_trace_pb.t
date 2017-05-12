use strict;
use warnings;
use Test::More qw(no_plan);

use POE qw(Component::Client::DNS::Recursive);

POE::Session->create(
  package_states => [
	'main', [qw(_start _stop _child _response _trace)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  POE::Component::Client::DNS::Recursive->resolve(
	event => $_[SESSION]->postback( '_response' ),
	trace => $_[SESSION]->postback( '_trace' ),
	host => 'www.google.com',
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
  my $packet = $_[ARG1]->[0]->{response};
  return unless $packet;
  isa_ok( $packet, 'Net::DNS::Packet' );
  ok( scalar $packet->answer, 'We got answers' );
  return;
}

sub _trace {
  pass('Got a trace');
  my $packet = $_[ARG1]->[0];
  isa_ok( $packet, 'Net::DNS::Packet' );
  return;
}
