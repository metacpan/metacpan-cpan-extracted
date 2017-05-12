# $Id: 05_api_4.t 56 2006-05-21 20:43:08Z rcaputo $
# vim: filetype=perl

# Test the version 3 API.

use strict;
use POE qw(Component::Client::DNS Component::Server::DNS);
use Test::More tests => 2;

my $server = POE::Component::Server::DNS->spawn( port => 0, options => { trace => 0 } );

my $resolver = POE::Component::Client::DNS->spawn(
  Alias   => 'named',
  Timeout => 3,
  Nameservers => [ '127.0.0.1' ],
);

# This is so hacky.

POE::Session->create(
  inline_states  => {
    _start   => \&_start,
    _go      => \&start_tests,
    _cease   => \&stop_tests,
    _stop    => sub { }, # avoid assert problems
    response => \&got_response,
    log	     => \&got_log,
  }
);

POE::Kernel->run();
exit;

sub _start {
  $poe_kernel->call( $server->session_id(), 'log_event', 'log' );
  $poe_kernel->delay( '_go', 5 );
  return;
}

sub start_tests {
  my $port = $server->sockport();
  $resolver->get_resolver()->port($port);

  # Default IN A.  Not found in /etc/hosts.
  $resolver->resolve(
    event   => "response",
    host    => "google.com",
    context => 1,
    timeout => 30,
  );

  return;
}

sub stop_tests {
  $poe_kernel->post( $server->session_id, 'shutdown' );
  return;
}

sub got_response {
  my ($request, $response) = @_[ARG0, ARG1];
  ok($request->{context}, "got response $request->{context} for $request->{host}");
  diag("Waiting 5 seconds\n");
  $poe_kernel->delay( '_cease', 5 );
  return;
}

sub got_log {
  my ($af,$packet) = @_[ARG0..ARG1];
  pass("Log event: $af");
  #$packet->print;
  return;
}
