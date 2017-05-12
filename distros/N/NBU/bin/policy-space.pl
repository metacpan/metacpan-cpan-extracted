#!/usr/local/bin/perl -w

use strict;

use Getopt::Std;
use Time::Local;

my %opts;
getopts('d?ht:a:p:', \%opts);

if ($opts{'?'}) {
  print STDERR <<EOT;
policy-space.pl [-a <as of date>] [-p <days in period>] [-t <schedule type>]  [-h]
EOT

  exit;
}

use NBU;

NBU->debug($opts{'d'});

my $period = 1;
my ($mm, $dd, $yyyy);
if (!$opts{'a'}) {
  my ($s, $m, $h, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
  $year += 1900;
  $mm = $mon + 1;
  $dd = $mday;
  $yyyy = $year;
}
else {
  $opts{'a'} =~ /^([\d]{4})([\d]{2})([\d]{2})$/;
  $mm = $2;
  $dd = $3;
  $yyyy = $1;
}
if ($opts{'p'}) {
  $period = $opts{'p'};
}

my ($midnightStart, $midnightEnd);
if ($period > 0) {
  $midnightStart = timelocal(0, 0, 0, $dd, $mm-1, $yyyy);
  $midnightEnd = $midnightStart + (24 * 60 * 60 * $period);
}
else {
  $midnightEnd = timelocal(0, 0, 0, $dd, $mm-1, $yyyy);
  $midnightStart = $midnightEnd + (24 * 60 * 60 * $period);
}


NBU::Class->populate;

my @list;
if ($#ARGV > -1 ) {
  for my $policyName (@ARGV) {
    my $p = NBU::Class->byName($policyName);
    push @list, $p if (defined($p));
  }
}
else {
  @list = NBU::Class->list();
}

my $totalImages = 0;
my $totalSize = 0;
foreach my $p (@list) {
  my @hl = (sort {$a->name cmp $b->name} $p->clients);
  if (@hl) {
    for my $h (@hl) {
      my %totalHostImages;
      my %totalHostSize;
      foreach my $i (sort { $b->ctime <=> $a->ctime} $h->images) {
	next if ($i->ctime < $midnightStart);
	next if ($i->ctime > $midnightEnd);

        my $st = $i->schedule->type;
        next if ($opts{'t'} && ($st ne $opts{'t'}));

        $totalHostImages{$st} += 1;
        $totalHostSize{$st} += $i->size;
      }

      #
      # Maintain running total for this entire scan
      foreach my $k (keys %totalHostImages) {
        $totalImages += $totalHostImages{$k};
        $totalSize += $totalHostSize{$k};
      }

      #
      # Add up sizes from all schedule types for this host
      my $ths = 0; my $thi = 0;
      foreach my $k (keys %totalHostImages) {
        $thi += $totalHostImages{$k};
        $ths += $totalHostSize{$k};
      }

      if ($opts{'h'}) {
	my $hn = sprintf("%-15s", $h->name);
	$ths = sprintf("%.2fGB", $ths / 1024 / 1024);
	print "$hn: $thi images, $ths\n";
        if (!defined($opts{'t'})) {
	  foreach my $k (keys %totalHostImages) {
	    my $hs = sprintf("%.2fGB", $totalHostSize{$k} / 1024 / 1024);
	    my $hi = $totalHostImages{$k};
	    print "  $k: $hi images, $hs\n";
	  }
        }
      }
    }
  }
}

$totalSize = sprintf("%.2fGB", $totalSize / 1024 / 1024);
print "Between ".localtime($midnightStart)." and ".localtime($midnightEnd).", ";
print "$totalImages backup images consumed $totalSize\n";
