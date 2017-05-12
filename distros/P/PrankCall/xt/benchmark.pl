#! /usr/bin/env perl

use strict;
use warnings;
use Benchmark qw{cmpthese};

sub prankit {
  my ($host, $path) = @_;
  require PrankCall;
  my $prank = PrankCall->new(host => $host, port => 5000);
  $prank->get(path => '/');
}

sub lwpit {
  my $url = shift;
  require LWP::UserAgent;
  my $ua = LWP::UserAgent->new;
  $ua->timeout(0);
  $ua->get($url);
}

cmpthese(10000, {
  lwp => sub { lwpit('http://localhost:5000/') },
  prank => sub { prankit('http://localhost', '/')}
});

##  RESULTS
#  Rate   lwp prank
#  lwp   1148/s    --  -59%
#  prank 2770/s  141%    --
