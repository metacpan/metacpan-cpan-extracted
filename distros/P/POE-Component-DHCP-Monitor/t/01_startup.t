use Test::More tests => 7;  
use POE;
use Net::DHCP::Packet;
use Socket;
require_ok( 'POE::Component::DHCP::Monitor' );

POE::Session->create(
  package_states => [
	'main' => [qw(_default _start _stop dhcp_monitor_registered dhcp_monitor_socket)],
  ],
  options => { trace => 0 },
  heap => { ports => 2 },
);

$poe_kernel->run();
exit 0;

sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    $heap->{monitor} =
        POE::Component::DHCP::Monitor->spawn(
                port  => 0,              # default shown
		port2  => 0,
		options => { trace => 0 },
        );
    isa_ok( $heap->{monitor}, 'POE::Component::DHCP::Monitor' );
    return;
}

sub _stop {
  pass("Poco shutdown and let our refcount go");
  return;
}

sub _default {
  my ($event, $args) = @_[ARG0 .. $#_];
  return 0 unless $event =~ /^dhcp_monitor_/;
  diag("$event:" . join(' ', @$args) . "\n");
  return 0;
}

sub dhcp_monitor_registered {
  pass($_[STATE]);
  isa_ok( $_[ARG0], 'POE::Component::DHCP::Monitor' );
  return;
}

sub dhcp_monitor_socket {
  pass($_[STATE]);
  my ($port, $myaddr) = sockaddr_in($_[ARG0]);
  diag("Bound to $port\n");
  $_[HEAP]->{ports}--;
  $_[HEAP]->{monitor}->shutdown() if $_[HEAP]->{ports} <= 0;
  return;
}
