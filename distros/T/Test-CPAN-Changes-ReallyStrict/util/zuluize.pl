#!/usr/bin/perl

# Replace DZIL style date-time with W3CDTF style while keeping the time right.

use strict;
use warnings;

use DateTime::Format::Strptime;

open my $ifh, '<', 'Changes'     or die "Can't open Changes, $!";
open my $ofh, '>', 'Changes.out' or die "Can't open Changes.out for write, $!";

while ( defined( my $line = <$ifh> ) ) {
  if ( $line =~ qr{(^[\d.]+\s+)(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s+([^\s]+)} ) {
    my $prelude  = $1;
    my $date     = $2;
    my $timezone = $3;
    print "TS: $2 , TZ: $3\n";
    my $strp = DateTime::Format::Strptime->new(
      pattern   => '%Y-%m-%d %H:%M:%S',
      time_zone => $timezone,
    );
    $line = join '', ( $prelude, $strp->parse_datetime($date)->set_time_zone('UTC'), "Z\n" );
  }
  elsif ( $line =~ /^\s*\d/ ) {
    my $lineclone = $line;
    chomp $lineclone;
    print "Datestamp line $lineclone skipped, probably already ok\n";
  }
  print {$ofh} $line;
}

