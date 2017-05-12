use strict;
use POE;
use POE::Component::Server::BigBrother;

POE::Component::Server::BigBrother->spawn( alias => 'BigBrother_Server');

POE::Session->create(
      package_states => [
          'main' => { 'bb_status' => '_message' },
          'main' => [ qw ( _start ) ] ]
);

$poe_kernel->run();

exit 0;

sub _start {
  # Our session starts, register to receive all events from poco-BigBrother
  $poe_kernel->post ( 'BigBrother_Server', 'register', qw( all ) );
  return;
}

sub _message {
  my ($sender, $message, $bb_server) = @_[SENDER, ARG0, ARG1];
  print $message->{command}," message from ",$message->{host_name},$/;
}
