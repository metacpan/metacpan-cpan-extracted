#! /usr/bin/perl
# vim: ts=2 sw=2 filetype=perl expandtab

# Test case for POE::Component::Client::HTTP failing to redirect HEAD
# requests.

use strict;
use warnings;

sub DEBUG () { 0 }

BEGIN {
  my @proxies = grep /^http.*proxy$/i, keys %ENV;
  delete @ENV{@proxies} if @proxies;
}

use Test::More tests => 2;
use Test::POE::Server::TCP;
use POE qw(Component::Client::HTTP);
use HTTP::Request::Common qw(HEAD);

POE::Component::Client::HTTP->spawn( Alias => 'no_redir' );
POE::Component::Client::HTTP->spawn( Alias => 'redir', FollowRedirects => 5 );

POE::Session->create(
    inline_states => {
    _start => \&start,
    testd_registered => \&testd_start,
    testd_client_input => \&testd_input,
    manual => \&manual,
    automatic => \&automatic,
  }
);


sub start {
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

  $kernel->post(
      no_redir => request => manual => HEAD "http://localhost:$port/redir"
    );
}

sub testd_input {
  my ($kernel, $heap, $id, $input) = @_[KERNEL, HEAP, ARG0, ARG1];

  my $port = $heap->{testd}->port;

  my $data;
  if ($input =~ /redir/) {
    $data = <<"EOF";
HTTP/1.1 303 See Other
Location: http://localhost:$port/destination

EOF
  } else {
    $data = <<'EOF';
HTTP/1.1 200 Ok
Host:

EOF
  }
  $heap->{testd}->send_to_client($id, $data);
}

sub manual {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  my $response = $_[ARG1][0];

  my $code = $response->code();

  if ($code =~ /^3/) {

    $kernel->post(
        no_redir => request => manual => HEAD $response->header("location")
      );
    return;
  }

  $heap->{destination} = $_[ARG0][0]->header("host");

  my $port = $heap->{testd}->port;
  $kernel->post(
      redir => request => automatic => HEAD "http://localhost:$port/redir"
      );
}

sub automatic {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  my $rsp = $_[ARG1][0];

  my $code = $rsp->code();
  is($code, 200, "got correct response code");

  my $rsp_host = $rsp->request->header("host");
  my $exp_host = $heap->{destination};
  is( $rsp_host, $exp_host, "automatic redirect host matches manual result");
  $heap->{testd}->shutdown;
  $kernel->post( no_redir => 'shutdown' );
  $kernel->post( redir    => 'shutdown' );
}



POE::Kernel->run();
exit;
