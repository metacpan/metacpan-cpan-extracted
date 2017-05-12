use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok('POE::Component::Server::Ident') };
use Socket;
use POE qw(Filter::Line);
use Test::POE::Client::TCP;

my $identd = POE::Component::Server::Ident->spawn ( Alias => 'Ident-Server', BindAddr => '127.0.0.1', BindPort => 0, Multiple => 1 );

isa_ok( $identd, 'POE::Component::Server::Ident' );

POE::Session->create(
    package_states => [
	main => [qw(_start _stop identd_request idc_input idc_connected idc_socket_failed)],
    ],
    heap => { Port1 => 12345, Port2 => 123, UserID => 'bingos', Identd => $identd },
  );

POE::Kernel->run();
exit;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my ($remoteport,undef) = unpack_sockaddr_in( $heap->{Identd}->getsockname() );
  $kernel->call ( 'Ident-Server' => 'register' );
  $heap->{idc} = Test::POE::Client::TCP->spawn(
	address   => '127.0.0.1',
	port	  => $remoteport,
	localaddr => '127.0.0.1',
	prefix    => 'idc',
	filter    => POE::Filter::Line->new( Literal => "\x0D\x0A" ),
	autoconnect => 1,
  );
  return;
}

sub _stop {
  pass("Client stopped");
  return;
}

sub idc_socket_failed {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->call( 'Ident-Server' => 'shutdown' );
  $heap->{idc}->shutdown();
  return;
}

sub idc_connected {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{idc}->send_to_server( 'Garbage' );
  return;
}

sub idc_input {
  my ($kernel,$heap,$input) = @_[KERNEL,HEAP,ARG0];
  ok( $input =~ /INVALID-PORT/, "Got the reply" );
  $kernel->post ( 'Ident-Server' => 'shutdown' );
  $heap->{idc}->shutdown();
  return;
}

sub identd_request {
  my ($kernel,$heap,$sender,$peeraddr,$first,$second) = @_[KERNEL,HEAP,SENDER,ARG0,ARG1,ARG2];
  return;
}
