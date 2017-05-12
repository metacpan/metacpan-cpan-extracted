#!/usr/bin/perl -w

=head1 NAME

example-tracker-http.pl - Net::GPSD::Report::http example

=cut

use strict;
use lib qw{./lib ../lib};
use Getopt::Std;
use Net::GPSD;
use Net::GPSD::Report::http;

my $opt={};
getopts('i:s:d:t:', $opt);

my ($host,$port)=split(q{:}, shift()||'');
$host||=q{localhost};
$port||=q{2947};

$opt->{'i'}||=int(2 ** 15 + rand(2 ** 15));  #integer
$opt->{'s'}||=1200;   #seconds  50
$opt->{'d'}||=2000; #meters   1000
$opt->{'t'}||=500;  #meters   200

print "Device:", $opt->{'i'}, " - $host:$port\n";

my $gps=Net::GPSD->new(host=>$host, port=>$port) || die("Error: Cannot connect to the gpsd server");

print join("|", qw{Type Status Time Lat Lon Alt Speed Heading}), "\n";
my $config={
            time=>$opt->{'s'},     #seconds
            distance=>$opt->{'d'}, #meters
            track=>$opt->{'t'},    #meters
            device=>$opt->{'i'},   #device id
           };

$gps->subscribe(handler=>\&gpsd_handler,
                config=>$config);

sub report {
  my $point=shift();
  my $config=shift();
  print join "|", map {defined $_?$_:''} 
                  $config->{'type'},
                  $point->mode,
                  $point->time,
                  $point->lat,
                  $point->lon,
                  $point->alt,
                  $point->speed,
                  $point->heading,
                  "\n";
   my $rpt=Net::GPSD::Report::http->new();
   my $return=$rpt->send({device=>$config->{'device'},
                          lat=>$point->lat,
                          lon=>$point->lon,
                          speed=>$point->speed,
                          heading=>$point->heading,
                          dtg=>$point->datetime,  #should use time here
                          type=>$config->{'type'}});
  return $return ? $point : undef();
}

sub gpsd_handler {
  my $p1=shift(); #last true return or undef if first
  my $p2=shift(); #current fix
  my $config=shift();
  unless (defined($p1)) {
    $config->{'type'}="first";
    return report($p2, $config);
  } else {
    if ($gps->time($p1, $p2) > $config->{'time'}) {
      $config->{'type'}="time";
      return report($p2, $config);
    } else {
      if ($gps->distance($p1, $p2) > $config->{'distance'}) {
        $config->{'type'}="distance";
        return report($p2, $config);
      } else {
        if ($gps->distance($gps->track($p1, $gps->time($p1,$p2)), $p2)
              > $config->{'track'}) {
          $config->{'type'}="track";
          return report($p2, $config);
        } else {
          return undef();
        }
      }
    }
  }
}
