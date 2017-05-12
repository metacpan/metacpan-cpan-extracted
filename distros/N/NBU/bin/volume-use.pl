#!/usr/local/bin/perl

use strict;

use Getopt::Std;
use Time::Local;
use NBU;

my %opts;
getopts('rhda:p:s:l:', \%opts);

NBU->debug($opts{'d'});

$opts{'r'} ||= ($opts{'s'} =~ /r/);
$opts{'r'} ||= ($opts{'s'} =~ /v/);

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

NBU::Media->populate(1);

sub dispInterval {
  my $i = shift;

  my $seconds = $i % 60;  $i = int($i / 60);
  my $minutes = $i % 60; $i = int($i / 60);
  my $hours = $i % 24;
  my $days = int($i / 24);

  my $fmt = sprintf("%02d", $seconds);
  $fmt = sprintf("%02d:", $minutes).$fmt;
  $fmt = sprintf("%02d:", $hours).$fmt;
  $fmt = "$days days ".$fmt if ($days);
  return $fmt;
}

my %usedCount;
my %oldest;
my %fillTime;
foreach my $volume (NBU::Media->listVolumes) {
  my $dt = $volume->lastWritten;
  if (($dt >= $midnightStart) && ($dt < $midnightEnd)) {
    if ($volume->full) {
      my ($s, $m, $h, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($dt);
      $year += 1900;
      $mm = $mon + 1;
      $dd = $mday;
      $yyyy = $year;
      my $key = $volume->pool->name;
      $key .= ":".sprintf("%04u%02u%02d", $year, $mm, $dd);
      $key .= ":".($opts{'h'} ? $volume->mmdbHost->name : "");
      $key .= ":".($opts{'r'} ? $volume->retention->level : "");
      $usedCount{$key} += 1;

      $key =$volume->pool->name.":".$volume->retention->level;
      my $age = $oldest{$key};
      $oldest{$key} = $volume->allocated if (!defined($age) || ($volume->allocated < $age));

      $fillTime{$key} += $volume->fillTime;
    }
  }
}

my %poolUsage;
my %levelUsage;
my %poollevelUsage;
foreach my $k (sort (keys %usedCount)) {
  my ($pool, $dt, $hostName, $level) = split(':', $k);
  my $c = $usedCount{$k};

  my $detail = "";

  $detail .= $hostName." " if (defined($hostName) && ($hostName ne ""));
  $detail .= "filled $c $pool volumes";
  $detail .= " at retention level ".NBU::Retention->byLevel($level)->description if (defined($level) && ($level =~ /^[0-9]+$/));
  $detail .= " on $dt\n";

  if (($opts{'s'} =~ /v/) && ($opts{'s'} =~ /r/)) {
    $poollevelUsage{$pool.":".$level} += $c;
  }
  elsif ($opts{'s'} =~ /v/) {
    $poolUsage{$pool} += $c;
  }
  elsif ($opts{'s'} =~ /r/) {
    $levelUsage{$level} += $c;
  }
  print $detail unless ($opts{'s'});
}

if (($opts{'s'} =~ /v/) && ($opts{'s'} =~ /r/)) {
  my $previousPool;
  my $poolCount = 0;
  for my $k (sort (keys %poollevelUsage)) {
    my ($pool, $level) = split(':', $k);
    if (defined($previousPool) && ($pool ne $previousPool)) {
      print "$previousPool uses a total of $poolCount volumes\n";
      $poolCount = 0;
    }

    my $c = $poollevelUsage{$k};

    my $span = time - $oldest{$k};
    $span /= (24 * 60 * 60);
    $span = sprintf("%3d", $span);

    my $velocity = int($fillTime{$k} / $c);

    print "$pool consumed $c volumes at retention level "
	    .NBU::Retention->byLevel($level)->description
	    ."; at an average velocity of ".dispInterval($velocity)
	    ."\n";

    $previousPool = $pool;
    $poolCount += $c;
  }
  print "$previousPool used a total of $poolCount volumes\n";
}
elsif ($opts{'s'} =~ /v/) {
  for my $pool (sort (keys %poolUsage)) {
    my $c = $poolUsage{$pool};
    print "$pool consumed $c volumes\n";
  }
}
elsif ($opts{'s'} =~ /r/) {
  for my $level (sort (keys %levelUsage)) {
    my $c = $levelUsage{$level};
    print $level.": ".NBU::Retention->byLevel($level)->description." consumed $c volumes\n";
  }
}
