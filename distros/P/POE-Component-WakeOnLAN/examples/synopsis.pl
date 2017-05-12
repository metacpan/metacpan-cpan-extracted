use strict;
use warnings;
use Data::Dumper;
use POE;
use POE::Component::WakeOnLAN;

my $mac_address = '00:0a:e4:4b:b0:94';

POE::Session->create(
   package_states => [
	'main' => [qw(_start _response)],
   ],
);


$poe_kernel->run();
exit 0;

sub _start {
  POE::Component::WakeOnLAN->wake_up( 
	macaddr => $mac_address,
	event   => '_response',
  );
  return;
}

sub _response {
  print Dumper( $_[ARG0] );
  return;
}
