#!perl
# vim: ts=2 sw=2 filetype=perl expandtab

# simple test case to exhibit behaviour where PoCoClHTTP fails when cancelling
# a request before connection pool connections have been established

use strict;
use warnings;

BEGIN {
  my @proxies = grep /^http.*proxy$/i, keys %ENV;
  delete @ENV{@proxies} if @proxies;
}

use HTTP::Request;
use HTTP::Status;
use Test::More;

plan tests => 4;

use constant DEBUG => 0;

sub POE::Kernel::TRACE_EVENTS     () { 0 }
sub POE::Kernel::TRACE_REFCNT     () { 0 }
sub POE::Kernel::CATCH_EXCEPTIONS () { 0 }
use Test::POE::Server::TCP;
use POE qw(Filter::Stream Component::Client::HTTP);

POE::Component::Client::HTTP->spawn( Alias => 'ua' );

POE::Session->create(
  inline_states => {
    _start   => \&client_start,
    response => \&response_handler,
    testd_registered => \&testd_start,
    testd_client_input => \&testd_input,
  }
);

our %responses;
eval { POE::Kernel->run(); };
ok (!$@, "cancelling req before connection succeeds does not die");
diag($@) if $@;

exit;

sub client_start{
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  DEBUG and warn "client starting...\n";

  $heap->{testd} = Test::POE::Server::TCP->spawn(
    Filter => POE::Filter::Stream->new,
    address => 'localhost',
  );
}

sub testd_start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  my $port = $heap->{testd}->port;

  my $request = HTTP::Request->new('GET', "http://localhost:$port/cancel");
  my $req2    = HTTP::Request->new('GET', "http://localhost:$port/one");

  $_[KERNEL]->post( ua => request => response => $request );
  $_[KERNEL]->post( ua => request => response => $req2 );

  $_[KERNEL]->post( ua => cancel  => $request );
}

sub testd_input {
  my ($kernel, $heap, $id, $input) = @_[KERNEL, HEAP, ARG0, ARG1];

  my $data = <<'EOF';
HTTP/1.1 204 OK

EOF
  if ($input =~ /(?:one|two)/) {
    pass("got expected request");
    $heap->{testd}->send_to_client($id, $data);
  } elsif ($input =~ /cancel/) {
    fail("got request that was supposed to be cancelled");
    $heap->{testd}->send_to_client($id, $data);
  } else {
    BAIL_OUT("got a request that isn't even supposed to exist");
  }
}

sub response_handler {
  my $heap = $_[HEAP];
  my $response = $_[ARG1][0];
  my $request  = $_[ARG0][0];

  my $path = $request->uri->path;
  if ($path eq '/cancel') {
    is ($response->code, 408, "got a correct response code for the cancelled request");
  } elsif ($path eq '/one') {
    is ($response->code, 204, "got a correct response code for the non-cancelled request");
    $heap->{testd}->shutdown;
    $_[KERNEL]->post( ua => 'shutdown' );
  }
}
