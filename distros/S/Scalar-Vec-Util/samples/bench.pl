#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark qw<cmpthese>;

use lib qw<blib/arch blib/lib>;
use Scalar::Vec::Util qw<vfill vcopy veq>;

BEGIN {
 print 'We ';
 if (eval "use Bit::Vector; 1") {
  *HAS_BV = sub () { 1 };
 } else {
  *HAS_BV = sub () { 0 };
  print "don't ";
 }
 print "have Bit::Vector.\n\n";
}

my $run = -1;
my $n   = 100_000;

sub inc {
 ++$_[0];
 $_[0] = 0 if $_[0] >= $n;
 $_[0];
}

sub add {
 $_[0] += $_[1];
 $_[0] = 0 if $_[0] >= $n;
 $_[0];
}

sub len {
 return $n - ($_[0] > $_[1] ? $_[0] : $_[1])
}

sub bench_fill {
 my ($tests, $desc) = @_;

 my ($x, $y, $bv) = map "", 1 .. 2;
 vec($_, $n - 1, 1) = 0 for $x, $y;
 $bv = Bit::Vector->new($n, 1) if HAS_BV;

 my ($i, $j, $k) = map 0, 1 .. 3;
 my $m = @$tests;

 print 'fill';
 print ", $desc" if defined $desc;
 print ":\n";

 cmpthese $run, {
  vfill     => sub {
   my ($u, $v) = @{$tests->[$i]};
   vfill($x, $u, $v, 1);
   ++$i;
   $i %= $m;
  },
  vfill_pp  => sub {
   my ($u, $v) = @{$tests->[$j]};
   Scalar::Vec::Util::vfill_pp($y, $u, $v, 1);
   ++$j;
   $j %= $m;
  },
  (vfill_bv => sub {
   my ($u, $v) = @{$tests->[$k]};
   $bv->Interval_Fill($u, $u + $v - 1);
   ++$k;
   $k %= $m;
  }) x HAS_BV,
 };

 print "\n";
}

bench_fill [ map { my $i = $_; map [ $i, $n - $i - $_ ], 0 .. 8 } 0 .. 8 ];

sub bench_copy {
 my ($tests, $desc) = @_;

 my ($x1, $x2, $y1, $y2, $bv1, $bv2) = map "", 1 .. 4;
 vec($_, $n - 1, 1) = 0 for $x1, $x2, $y1, $y2;
 ($bv1, $bv2) = Bit::Vector->new($n, 2) if HAS_BV;

 my ($i, $j, $k) = map 0, 1 .. 3;
 my $m = @$tests;

 print 'copy';
 print ", $desc" if defined $desc;
 print ":\n";

 cmpthese $run, {
  vcopy     => sub {
   my ($u, $v, $w) = @{$tests->[$i]};
   vcopy($x1, $u, $x2, $v, $w);
   ++$i;
   $i %= $m;
  },
  vcopy_pp  => sub {
   my ($u, $v, $w) = @{$tests->[$j]};
   Scalar::Vec::Util::vcopy_pp($y1, $u, $y2, $v, $w);
   ++$j;
   $j %= $m;
  },
  (vcopy_bv => sub {
   my ($u, $v, $w) = @{$tests->[$k]};
   $bv2->Interval_Copy($bv1, $v, $u, $w);
   ++$k;
   $k %= $m;
  }) x HAS_BV,
 };

 print "\n";
}

bench_copy [
 map {
  my $i = $_;
  map {
   my $j = $i + 8 * $_;
   map [ $i, $j, len($i, $j) - $_ ], 0 .. 8;
  } 0 .. 8;
 } 0 .. 8
], 'aligned, forward';

bench_copy [
 map {
  my $i = $_;
  map {
   my $j = $i + 8 * $_;
   map [ $j, $i, len($i, $j) - $_ ], 0 .. 8;
  } 0 .. 8;
 } 0 .. 8
], 'aligned, backward';

bench_copy [
 map {
  my $i = $_;
  map {
   my $j = $_;
   map [ $i, $j, len($i, $j) - $_ ], 0 .. 8;
  } 0 .. 8;
 } 0 .. 8
], 'misaligned';

sub bench_move {
 my ($tests, $desc) = @_;

 my ($x, $y, $bv) = map "", 1 .. 2;
 vec($_, $n - 1, 1) = 0 for $x, $y;
 $bv = Bit::Vector->new($n, 1) if HAS_BV;

 my ($i, $j, $k) = map 0, 1 .. 3;
 my $m = @$tests;

 print 'move';
 print ", $desc" if defined $desc;
 print ":\n";

 cmpthese $run, {
  vcopy     => sub {
   my ($u, $v, $w) = @{$tests->[$i]};
   vcopy($x, $u, $x, $v, $w);
   ++$i;
   $i %= $m;
  },
  vcopy_pp  => sub {
   my ($u, $v, $w) = @{$tests->[$j]};
   Scalar::Vec::Util::vcopy_pp($y, $u, $y, $v, $w);
   ++$j;
   $j %= $m;
  },
  (vcopy_bv => sub {
   my ($u, $v, $w) = @{$tests->[$k]};
   $bv->Interval_Copy($bv, $v, $u, $w);
   ++$k;
   $k %= $m;
  }) x HAS_BV,
 };

 print "\n";
}

bench_move [
 map {
  my $i = $_;
  map {
   my $j = $i + 8 * $_;
   map [ $i, $j, len($i, $j) - $_ ], 0 .. 8;
  } 0 .. 8;
 } 0 .. 8
], 'aligned, forward';

bench_move [
 map {
  my $i = $_;
  map {
   my $j = $i + 8 * $_;
   map [ $j, $i, len($i, $j) - $_ ], 0 .. 8;
  } 0 .. 8;
 } 0 .. 8
], 'aligned, backward';

bench_move [
 map {
  my $i = $_;
  map {
   my $j = $_;
   map [ $i, $j, len($i, $j) - $_ ], 0 .. 8;
  } 0 .. 8;
 } 0 .. 8
], 'misaligned';

my $i = 0;
my $j = int $n / 2;
my $x = '';
vfill $x, 0, $n, 1;
my $y = '';
vfill $y, 0, $n, 1;
my ($bv1, $bv2, $bv3, $bv4);
if (HAS_BV) {
 ($bv1, $bv2, $bv3, $bv4) = Bit::Vector->new($n, 4);
 $bv1->Fill();
 $bv2->Fill();
}

print "eq, origin:\n";
cmpthese $run, {
 veq     => sub { veq $x, 0, $y, 0, $n },
 veq_pp  => sub { Scalar::Vec::Util::veq_pp($x, 0, $y, 0, $n) },
 (veq_bv => sub { $bv1->equal($bv2) }) x HAS_BV,
};
print "\n";

print "eq, random:\n";
cmpthese $run, {
 veq     => sub { veq $x, inc($i), $y, inc($j), len($i, $j) },
 veq_pp  => sub { Scalar::Vec::Util::veq_pp($x, inc($i), $y, inc($j), len($i, $j)) },
 (veq_bv => sub {
   inc($i);
   inc($j);
   my $l = len($i, $j);
   $bv3->Resize($l);
   $bv3->Interval_Copy($bv1, 0, $i, $l);
   $bv4->Resize($l);
   $bv4->Interval_Copy($bv2, 0, $j, $l);
   $bv3->equal($bv4);
  }) x HAS_BV,
};
print "\n";
