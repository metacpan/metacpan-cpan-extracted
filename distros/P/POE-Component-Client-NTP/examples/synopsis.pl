use strict;
use warnings;
use POE qw(Component::Client::NTP);
use Data::Dumper;

my $host = shift or die "Please specify a host name to query\n";

POE::Session->create(
  package_states => [
	main => [qw(_start _response)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  POE::Component::Client::NTP->get_ntp_response(
     host => $host,
     event => '_response',
  );
  return;
}

sub _response {
  my $packet = $_[ARG0];
  print Dumper( $packet );
  return;
}
