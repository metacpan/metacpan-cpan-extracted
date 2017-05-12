use strict;
use warnings;
use Test::More tests => 2;
use POE qw(Component::Client::NTP);

POE::Session->create(
  package_states => [
	main => [qw(_start _stop _response)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  POE::Component::Client::NTP->get_ntp_response(
     host => 'bingosnet.uk',
     event => '_response',
     timeout => 5,
  );
  return;
}

sub _stop {
  pass('Refcount was decremented');
  return;
}


sub _response {
  my $packet = $_[ARG0];
  ok( $packet->{error}, 'There is an error: "' . $packet->{error} . '"');
  return;
}
