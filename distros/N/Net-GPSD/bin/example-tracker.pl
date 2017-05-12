#!/usr/bin/perl -w

=head1 NAME

example-tracker.pl - Net::GPSD subscribe method example with custom handler this verson filters gpsd data based on time, distance and track.

=cut

use strict;
use lib qw{./lib ../lib};
use Net::GPSD;

my ($host,$port)=split(q{:}, shift()||'');
$host||=q{localhost};
$port||=q{2947};

my $gps=Net::GPSD->new(host=>$host, port=>$port) || die("Error: Cannot connect to the gpsd server");

print join("|", qw{Type Status Time Lat Lon Alt Speed Heading}), "\n";
my $config={
             time=>5,       #seconds
             distance=>100, #meters
             track=>20      #meters
           };

$gps->subscribe(handler=>\&gpsd_handler,
                config=>$config);

sub gpsd_handler {
  my $p1=shift(); #last true return or undef if first
  my $p2=shift(); #current fix
  my $config=shift();
  unless (defined($p1)) {
    report({type=>"first", point=>$p2});
    return $p2;
  } else {
    my $time_delta=$gps->time($p1, $p2);
    if ($time_delta > $config->{'time'}) {
      report({type=>"time", point=>$p2});
      return $p2;
    } else {
      my $distance_delta=$gps->distance($p1, $p2);
      if ($distance_delta > $config->{'distance'}) {
        report({type=>"distance", point=>$p2});
        return $p2;
      } else {
        my $track_delta=$gps->distance($gps->track($p1, $gps->time($p1,$p2)), $p2);
        if ($track_delta > $config->{'track'}) {
          report({type=>"track", point=>$p2});
          return $p2;
        } else {
          print "filtered\n";
          return undef();
        }
      }
    }
  }
}

sub report {
  my $data=shift();
  my $point=$data->{'point'};
  print join "|", map {defined $_?$_:''}
                  $data->{'type'},
                  $point->mode,
                  $point->time,
                  $point->lat,
                  $point->lon,
                  $point->alt,
                  $point->speed,
                  $point->heading,
                  "\n";
  if ("Success") {
    return $point;
  } else {
    return undef();
  }
}
