use strict;
use warnings;
use Test::More tests => 7;
use POE;
use_ok('POE::Component::WakeOnLAN');

my $mac_address = '00:0a:e4:4b:b0:94';

POE::Session->create(
   package_states => [
	'main' => [qw(_start _stop _response)],
   ],
);


$poe_kernel->run();
exit 0;

sub _start {
  POE::Component::WakeOnLAN->wake_up( 
	macaddr => $mac_address,
	event   => '_response',
	_arbitary => { qw(foo moo bar cow) },
  );
  return;
}

sub _stop {
  pass("Okay the poco let us go");
  return;
}

sub _response {
  my $ans = $_[ARG0];
  ok( $ans->{macaddr} eq '000ae44bb094', 'MAC Address is fine' );
  ok( $ans->{address} eq '255.255.255.255', 'Yes, we used a broadcast' );
  ok( $ans->{port} == 9, 'The port was okay as well' );
  ok( $ans->{_arbitary}->{foo} eq 'moo', 'Arbitary 1 was okay' );
  ok( $ans->{_arbitary}->{bar} eq 'cow', 'Arbitary 2 was okay' );
  return;
}
