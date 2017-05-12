use strict;
use warnings;
use Test::More tests => 22;
use POE qw(Component::Client::NTP);

my @fields = (
 'Root Delay',
 'Version Number',
 'Precision',
 'Leap Indicator',
 'Transmit Timestamp',
 'Receive Timestamp',
 'Stratum',
 'Originate Timestamp',
 'Reference Timestamp',
 'Poll Interval',
 'Reference Clock Identifier',
 'Mode',
 'Root Dispersion',
 'Receive Timestamp',
 'Transmit Timestamp',
);

POE::Session->create(
  package_states => [
	main => [qw(_start _stop _response)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  POE::Component::Client::NTP->get_ntp_response(
     host => 'pool.ntp.org',
     event => '_response',
     context => 'word',
  );
  return;
}

sub _stop {
  pass('Refcount was decremented');
  return;
}


sub _response {
  my $packet = $_[ARG0];
  ok( $packet->{response}, 'There is a response' );
  use Data::Dumper;
  local $Data::Dumper::Indent=1;
  diag( Dumper( $packet->{response} ) );
  is( ref $packet->{response}, 'HASH', 'And the response is a HASHREF' );
  ok( defined $packet->{response}->{ $_ }, $_ ) for @fields;
  ok( $packet->{host}, 'There is a host' );
  is( $packet->{host}, 'pool.ntp.org', 'and it is the right thing' );
  ok( $packet->{context}, 'There is context' );
  is( $packet->{context}, 'word', 'and it is the right thing' );
  return;
}
