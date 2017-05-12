#!/usr/bin/perl
# vim: filetype=perl

use warnings;
use strict;
use lib qw(./mylib ../mylib);

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use Test::More tests => 2;
use POE;
use POE::Component::Client::Keepalive;
use POE::Component::Resolver;
use Socket qw(AF_INET);

POE::Session->create(
  inline_states => {
    _child    => sub { },
    _start    => \&start,
    _stop     => \&crom_count_the_responses,
    got_resp  => \&got_resp,
  }
);

POE::Kernel->run();
exit;

# Start up!  Create a Keepalive component.  Request one connection.
# The request is specially formulated to time out immediately.  We
# should receive no other response (especially not a resolve error
# like "Host has no address."

sub start {
  my $heap = $_[HEAP];

  $heap->{errors} = [ ];

  $heap->{cm} = POE::Component::Client::Keepalive->new(
    resolver => POE::Component::Resolver->new(af_order => [ AF_INET ]),
  );

  $heap->{cm}->allocate(
    scheme => "http",
    addr   => "seriously-hoping-this-never-resolves.fail",
    port   => 80,
    event  => "got_resp",
    context => "moo",
    timeout => -1,
  );
}

# We received a response.  Count it.

sub got_resp {
  my ($heap, $stuff) = @_[HEAP, ARG0];
  push @{$heap->{errors}}, $stuff->{function};
}

# End of run.  We're good if we receive only one timeout response.

sub crom_count_the_responses {
  my @errors = @{$_[HEAP]{errors}};
  ok(
    @errors == 1,
    "should have received one response (actual=" .  @errors . ")"
  );
  ok( $errors[0] eq "connect", "the one response was a connect error");
}
