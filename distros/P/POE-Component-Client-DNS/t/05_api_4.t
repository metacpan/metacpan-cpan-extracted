#!/usr/bin/perl -w
# vim: filetype=perl

# Test the version 3 API.

use strict;
sub POE::Kernel::ASSERT_DEFAULT () { 1 }
use POE qw(Component::Client::DNS);
use Test::More tests => 6;
use Test::NoWarnings;

my $resolver = POE::Component::Client::DNS->spawn(
  Alias   => 'named',
  Timeout => 5,
);

POE::Session->create(
  inline_states  => {
    _start   => \&start_tests,
    _stop    => sub { }, # avoid assert problems
    response => \&got_response,
  }
);

POE::Kernel->run();
exit;

sub start_tests {
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

  $resolver->resolve(
    event   => "response",
    host    => "google.com",
    context => $request++,
    nameservers => ['8.8.8.8', '8.8.4.4'],
  );
}

sub got_response {
  my ($request, $response) = @_[ARG0, ARG1];
  ok($request->{context}, "got response $request->{context}");
}
