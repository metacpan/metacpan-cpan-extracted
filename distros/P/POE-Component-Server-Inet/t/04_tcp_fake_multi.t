use strict;
use warnings;
use Test::More tests => 15;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite);
use_ok('POE::Component::Server::Inet');

my $wait = 8;

my $inetd = POE::Component::Server::Inet->spawn( options => { trace => 0 } );
isa_ok( $inetd, 'POE::Component::Server::Inet' );

my $port = $inetd->add_tcp( port => 0, program => \&_fake );

POE::Session->create(
   package_states => [
	'main' => [qw(_start _stop _sock_up _sock_fail _input _error _shutdown _connect)],
   ],
   options => { trace => 0 },
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->alias_set( 'MOOCOW' );
  $heap->{multi} = 6;
  $kernel->yield( '_connect' ) for 1 .. $heap->{multi};
  return;
}
sub _connect {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $factory = POE::Wheel::SocketFactory->new(
	RemoteAddress => '127.0.0.1',
	RemotePort    => $port,
	SuccessEvent  => '_sock_up',
	FailureEvent  => '_sock_fail',
  );
  $heap->{factories}->{ $factory->ID() } = $factory;
  return;
}

sub _shutdown {
  $inetd->shutdown();
  return;
}

sub _stop {
  pass('Everything went away okay');
  return;
}

sub _sock_up {
  my ($kernel,$heap,$socket,$factory_id) = @_[KERNEL,HEAP,ARG0,ARG3];
  pass('Connected okay');
  delete $heap->{factories}->{ $factory_id };
  my $wheel = POE::Wheel::ReadWrite->new(
	Handle       => $socket,
	InputEvent   => '_input',
	ErrorEvent   => '_error',
  );
  $heap->{wheels}->{ $wheel->ID() } = $wheel;
  $wheel->put('MOOOOOO!');
  return;
}

sub _sock_fail {
  my ($operation, $errnum, $errstr, $factory_id) = @_[ARG0..ARG3];
  diag("Wheel $factory_id generated $operation error $errnum: $errstr\n");
  delete $_[HEAP]->{factories}->{ $factory_id }; # shut down that wheel
  return;
}

sub _error {
  my ($kernel,$heap,$wheel_id) = @_[KERNEL,HEAP,ARG3];
  pass('Got a disconnect which is fine');
  delete $heap->{wheels}->{ $wheel_id };
  $heap->{multi}--;
  return unless $heap->{multi} <= 0;
  diag("Waiting $wait seconds for the dust to settle\n");
  $kernel->delay( '_shutdown', $wait );
  return;
}

sub _input {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  fail('Oh noes we received something');
  return;
}

sub _fake {
  return;
}
