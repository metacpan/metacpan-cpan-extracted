#!/usr/bin/env perl

  use Net::Iperf::Parser;

  my $p = new Net::Iperf::Parser;

  my @rows = `iperf -c iperf.volia.net -P 2`;

  foreach (@rows) {
    $p->parse($_);
    print $p->dump if ($p->is_valid && $p->is_global_avg);
  }
