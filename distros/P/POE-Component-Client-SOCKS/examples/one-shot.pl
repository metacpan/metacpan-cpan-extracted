use strict;
use POE qw(Component::Client::SOCKS Wheel::ReadWrite Filter::Line);
use Data::Dumper;

POE::Session->create(
	package_states => [
	  'main' => [ qw(_start _success _failed _conn_input _conn_error) ],
	],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  POE::Component::Client::SOCKS->connect( 
	SocksProxy => '127.0.0.1',
	RemoteAddress => 'cou.ch',
	RemotePort => 6667,
	SuccessEvent => '_success',
	FailureEvent => '_failed',
  );
  return;
}

sub _success {
  my ($heap,$args) = @_[HEAP,ARG0];
  warn Dumper( $args );
  $heap->{wheel} = POE::Wheel::ReadWrite->new(
	Handle => $args->{socket},
	Filter => POE::Filter::Line->new(),
	InputEvent => '_conn_input',
	ErrorEvent => '_conn_error',
  );
  return;
}

sub _failed {
  warn Dumper( $_[ARG0] );
  return;
}

sub _conn_input {
  warn $_[ARG0], "\n";
  return;
}

sub _conn_error {
  delete $_[HEAP]->{wheel};
  return;
}
