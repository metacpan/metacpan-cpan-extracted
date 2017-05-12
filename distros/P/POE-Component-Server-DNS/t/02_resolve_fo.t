# $Id: 05_api_4.t 56 2006-05-21 20:43:08Z rcaputo $
# vim: filetype=perl

# Test the version 3 API.

use strict;
use POE qw(Component::Client::DNS Component::Server::DNS);
use Test::More tests => 4;

my $server = POE::Component::Server::DNS->spawn( port => 0, forward_only => 1 );

my $resolver = POE::Component::Client::DNS->spawn(
  Alias   => 'named',
  Timeout => 3,
  Nameservers => [ '127.0.0.1' ],
);

POE::Session->create(
  inline_states  => {
    _start   => \&_start,
    _go      => \&start_tests,
    _stop    => sub { }, # avoid assert problems
    response => \&got_response,
  }
);

POE::Kernel->run();
exit;

sub _start {
  $poe_kernel->delay( '_go', 5 );
  return;
}

sub start_tests {
  my $port = $server->sockport();
  $resolver->get_resolver->port($port);
  $_[HEAP]->{requests} = 4;
  my $request = 1;

  # Default IN A.  Override timeout.
  $resolver->resolve(
    event   => "response",
    host    => "localhost",
    context => $request++,
    timeout => 30,
  );

  # Default IN A.  Not found in /etc/hosts.
  $resolver->resolve(
    event   => "response",
    host    => "google.com",
    context => $request++,
    timeout => 30,
  );

  # IN PTR
  $resolver->resolve(
    event   => "response",
    host    => "127.0.0.1",
    class   => "IN",
    type    => "PTR",
    context => $request++,
  );

  # Small timeout.
  $resolver->resolve(
    event   => "response",
    host    => "google.com",
    context => $request++,
    timeout => 0.001,
  );
}

sub got_response {
  my ($request, $response) = @_[ARG0, ARG1];
  ok($request->{context}, "got response $request->{context} for $request->{host}");
  $poe_kernel->post( $server->session_id, 'shutdown' ) if $_[HEAP]->{requests}-- <= 1;
}
