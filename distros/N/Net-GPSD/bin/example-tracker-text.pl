#!/usr/bin/perl -w

=head1 NAME

example-tracker-text.pl - Net::GPSD example

=cut

use strict;
use lib qw{./lib ../lib};
use Getopt::Std;
use Net::GPSD;

my $opt={};
getopts('s:d:t:D:z:P:', $opt);

my ($host,$port)=split(q{:}, shift()||'');
$host||=q{localhost};
$port||=q{2947};

$opt->{'s'}||=1200; #seconds  50
$opt->{'d'}||=1000; #meters   1000
$opt->{'t'}||=200;  #meters   200
$opt->{'D'}||=0;    #debug    0=off
$opt->{'z'}||=0.75; #m/s      zero speed threshold
$opt->{'P'}||='';   #filename pid filename

if ($opt->{'P'}) {
  open(PID, ">".$opt->{'P'}) || die;
  print PID "$$\n";
  close(PID);
}

my $gps=Net::GPSD->new(host=>$host, port=>$port) || die("Error: Cannot connect to the gpsd server");

print join("|", qw{Report Type Data Status Time Lat Lon Alt Speed Heading}), "\n";
my $config={
            time=>$opt->{'s'},     #seconds
            distance=>$opt->{'d'}, #meters
            track=>$opt->{'t'},    #meters
            debug=>$opt->{'D'},    #debug
            zero=>$opt->{'z'},     #zero speed threshold
           };

$gps->subscribe(handler=>\&gpsd_handler,
                config=>$config);

sub report {
  my $lastpoint=shift();
  my $point=shift();
  my $config=shift();
  my $g=Net::GPSD->new(do_not_init=>1);
  my $debug=$config->{'debug'};
  if ($config->{'report'} and $config->{'type'} ne "first" and $debug>4) {
    my @point=$g->interpolate($lastpoint, $point);
    foreach (@point) {
      print join "|", map {defined $_?$_:''} 
                      '0',
                      'interpolate',
                      '',
                      $_->mode,
                      $_->time,
                      $_->lat,
                      $_->lon,
                      $_->alt,
                      $_->speed,
                      $_->heading,
                      "\n";

    }
  }
  print join "|", map {defined $_?$_:''} 
                  $config->{'report'},
                  $config->{'type'},
                  $config->{'data'},
                  $point->mode,
                  $point->time,
                  $point->lat,
                  $point->lon,
                  $point->alt,
                  $point->speed,
                  $point->heading,
                  "\n";
  local $|=1;
  return 1;
}

sub gpsd_handler {
  my $p1=shift(); #last true return or undef if first
  my $p2=shift(); #current fix
  my $config=shift();
  $p2->speed(0) if ($p2->speed < $config->{'zero'});
  my $debug=$config->{'debug'};
  unless (defined($p1)) {
    $config->{'type'}="first";
    $config->{'report'}="1";
    $config->{'data'}="0";
    report($p1, $p2, $config);
    return $p2;
  } else {
    my $dt=$gps->time($p1, $p2);
    if ($dt > $config->{'time'}) {
      $config->{'type'}="time";
      $config->{'report'}="1";
      $config->{'data'}=$gps->distance($p1, $p2);;
      report($p1, $p2, $config);
      return $p2;
    } else {
      my $dd=$gps->distance($p1, $p2);
      if ($dd > $config->{'distance'}) {
        $config->{'type'}="distance";
        $config->{'report'}="1";
        $config->{'data'}=$dd;
        report($p1, $p2, $config);
        return $p2;
      } else {
        my $p3=$gps->track($p1, $dt);
        my $dt=$gps->distance($p3, $p2);
        if ($debug>2) {
          $config->{'type'}="predicted";
          $config->{'report'}="0";
          $config->{'data'}=$dt;
          report($p1, $p3, $config);
        }
        if ($dt > $config->{'track'}) {
          $config->{'type'}="track";
          $config->{'report'}="1";
          $config->{'data'}=$dd;
          report($p1, $p2, $config);
          return $p2;
        } else {
          if ($debug>1) {
            $config->{'type'}="filtered";
            $config->{'report'}="0";
            $config->{'data'}='';
            report($p1, $p2, $config);
          }
          return undef();
        }
      }
    }
  }
}
