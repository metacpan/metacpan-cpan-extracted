use Test::More tests => 7;

use strict;
use POE;
use_ok('POE::Component::Proxy::SOCKS');

POE::Session->create(
	package_states => [
	  'main' => [ qw(_start _stop _child _time_out socksd_registered) ],
	],
	options => { trace => 0 },
);

$poe_kernel->run();
exit 0;

sub _start {
  my $kernel = $_[KERNEL];
  my $pbobj = POE::Component::Proxy::SOCKS->spawn( port => 0 );
  isa_ok( $pbobj, 'POE::Component::Proxy::SOCKS' );
  pass('started');
  $kernel->delay( '_time_out' => 60 );
  undef;
}

sub _stop {
  pass('stopped');
}

sub _time_out {
  die;
}

sub _child {
  my ($kernel,$what,$who) = @_[KERNEL,ARG0,ARG1];
  if ( $what eq 'create' ) {
	$kernel->post( $who => 'shutdown' );
	pass('created');
	return;
  }
  if ( $what eq 'lose' ) {
	pass('lost');
	$kernel->delay( '_time_out' );
	return;
  }
  undef;
}

sub socksd_registered {
  my ($kernel,$pbobj) = @_[KERNEL,ARG0];
  isa_ok( $pbobj, 'POE::Component::Proxy::SOCKS' );
  return;
}
