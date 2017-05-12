#!/usr/bin/env perl
# this run a pppd inside a pty
# the filter is used to print each packet
# it should run for a while printing LCP packets before pppd gives up

use strict;
use warnings;
use POE;
use POE::Session;
use POE::Wheel::Run;
use POE::Filter::PPPHDLC;

sub hexdump {
  use IPC::Open2 qw(open2);
  open2 my $rd, my $wr, 'hexdump', '-C';
  print $wr $_[0];
  close $wr;
  local $/;
  <$rd>;
}

POE::Session->create(
  package_states => [
    main => [ '_start', 'input', 'error', 'close' ],
  ],
);

sub _start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  $heap->{wheel} = POE::Wheel::Run->new(
    Program => ['pppd', 'debug'],
    ErrorEvent => 'error',
    CloseEvent => 'close',
    StdoutEvent => 'input',
    StdioFilter => POE::Filter::PPPHDLC->new,
    Conduit => 'pty',
  );
}

sub input {
  my ($kernel, $heap, $packet) = @_[KERNEL, HEAP, ARG0];
  print hexdump $packet;

  my ($ppp_protocol) = unpack "n", $packet;
  my $pat_prefix = 'n';
  printf "ppp: protocol=%04x\n", $ppp_protocol;

  if ($ppp_protocol == 0xc021) {
    # LCP
    my ($lcp_code, $lcp_identifier, $lcp_length)
      = unpack "x[$pat_prefix] CCn", $packet;
    $pat_prefix .= "CCn";
    printf "lcp: code=%02x identifier=%02x length=%04x\n",
      $lcp_code, $lcp_identifier, $lcp_length;
  } else {
    # send an LCP Protocol-Reject
  }
}

sub error {
  print "error: @_[ARG0..$#_]\n";
}

sub close {
  print "close\n";
  delete $_[HEAP]->{wheel};
}

$poe_kernel->run();
exit;
