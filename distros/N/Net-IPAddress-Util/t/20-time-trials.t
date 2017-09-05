#!/usr/bin/env perl

BEGIN {
  if ($] ge '5.012') {
    use strict;
    use warnings;
  }
  if ($] ge '5.026') {
    use lib '.';
  }
}

use Net::IPAddress::Util qw( :constr radix_sort );
use Net::IPAddress::Util::Range;
use Net::IPAddress::Util::Collection;
use Test::More tests => 1;
use Time::HiRes qw(time);

SKIP: {
  skip 'Author tests only', 1 unless -d '.git';
  skip 'Set $ENV{IP_UTIL_TIME_TRIALS} if you want time trials', 1 unless $ENV{IP_UTIL_TIME_TRIALS};
  # TODO better method for finding the break-even point. Newton's?
  diag('This is going to take a while. Unset $ENV{IP_UTIL_TIME_TRIALS} if you don\'t want time trials.');
  my ($savings, $count, $total);
  my $mult = $ENV{IP_UTIL_TIME_TRIALS};
  my @to_sort;
  my ($r, $tr, $p, $tp);
  my (@rsorted, @psorted);
  {
    $total = 0;
    $savings = 0;
    for my $iter (1 .. $mult) {
      $count = 100;
      while ($count-->0) {
        $total += $count;
        @to_sort = ();
        for my $i (1 .. $count) {
          push @to_sort, mk_v4();
        }
        {
          $r = time;
          @rsorted = radix_sort(@to_sort);
          $tr = time - $r;
        }
        {
          $p = time;
          @psorted = sort { $a <=> $b } @to_sort;
          $tp = time - $p;
        }
        $savings += eval { ($tp - $tr) / $tp };
      }
    }
    $savings = sprintf('%.3f', (0 - $savings) / $mult);
    diag("Radix-Sorting (1 .. 100) IPv4 addresses averages $savings\% faster");
  }
  {
    $total = 0;
    $savings = 0;
    for my $iter (1 .. $mult) {
      $count = 100;
      while ($count-->0) {
        $total += $count;
        @to_sort = ();
        for my $i (1 .. $count) {
          push @to_sort, mk_v6();
        }
        {
          $r = time;
          @rsorted = radix_sort(@to_sort);
          $tr = time - $r;
        }
        {
          $p = time;
          @psorted = sort { $a <=> $b } @to_sort;
          $tp = time - $p;
        }
        $savings += eval { ($tp - $tr) / $tp };
      }
    }
    $savings = sprintf('%.3f', (0 - $savings) / $mult);
    diag("Radix-Sorting (1 .. 100) IPv6 addresses averages $savings\% faster");
  }
  {
    $total = 0;
    $savings = 0;
    for my $iter (1 .. $mult) {
      $count = 100;
      while ($count-->0) {
        $total += $count;
        @to_sort = ();
        for my $i (1 .. $count) {
          push @to_sort, Net::IPAddress::Util::Range->new({ lower => mk_v6(), upper => mk_v6() });
        }
        my $coll = Net::IPAddress::Util::Collection->new(@to_sort);
        {
          $r = time;
          @rsorted = $coll->sorted();
          $tr = time - $r;
        }
        {
          $p = time;
          @psorted = sort { $a <=> $b } @$coll;
          $tp = time - $p;
        }
        $savings += eval { ($tp - $tr) / $tp };
      }
    }
    $savings = sprintf('%.3f', (0 - $savings) / $mult);
    diag("Radix-Sorting (1 .. 100) IPv6 address ranges averages $savings\% faster");
  }
  ok('Ran time trials');
};

sub mk_v4 {
  my $a = int(rand(256));
  my $b = int(rand(256));
  my $c = int(rand(256));
  my $d = int(rand(256));
  return IP("$a.$b.$c.$d");
}

sub mk_v6 {
  my @digits = qw( 0 1 2 3 4 5 6 7 8 9 a b c d e f );
  my $plen = int(rand(16)) + 1;
  my $slen = int(rand(16)) + 1;
  my $mlen = 32 - ($plen + $slen);
  my $x = '';
  for (1 .. $plen) {
    $x .= $digits[ rand @digits ];
  }
  $x .= '0' x $mlen;
  for (1 .. $slen) {
    $x .= $digits[ rand @digits ];
  }
  return IP($x);
}