#!/usr/bin/perl
use strict;
use warnings;
$|=1;

=head1 NAME

perl-Net-GPSD3-Example.pl - Net::GPSD3 Watcher Example

=cut

use Net::GPSD3;
my $host=shift || undef;
my $port=shift || undef;

my $gpsd=Net::GPSD3->new(host=>$host, port=>$port); #default host port as undef
$gpsd->watch;             #default handler

=head1 EXAMPLE OUTPUT

  2011-04-05T05:39:05: VERSION, GPSD: 2.96~dev (2011-03-17T02:51:23), Net::GPSD3: 0.15
  2011-04-05T05:39:05: DEVICES, Devices: /dev/cuaU0 (9600 bps uBlox UBX binary-none)
  2011-04-05T05:39:05: WATCH, Enabled: 1
  2011-04-05T05:39:05: TPV, Time: 2011-04-05T05:39:05.00Z, Lat: 37.371420332, Lon: -122.015185689, Speed: 0, Heading: 0
  2011-04-05T05:39:06: TPV, Time: 2011-04-05T05:39:06.00Z, Lat: 37.371420332, Lon: -122.015185689, Speed: 0, Heading: 0
  2011-04-05T05:39:07: TPV, Time: 2011-04-05T05:39:07.00Z, Lat: 37.371420332, Lon: -122.015185689, Speed: 0, Heading: 0
  2011-04-05T05:39:08: TPV, Time: 2011-04-05T05:39:08.00Z, Lat: 37.371420332, Lon: -122.015185689, Speed: 0, Heading: 0
  2011-04-05T05:39:08: SKY, Satellites: 11, Used: 6, PRNs: 28,24,8,15,26,135
  2011-04-05T05:39:09: TPV, Time: 2011-04-05T05:39:09.00Z, Lat: 37.371420332, Lon: -122.015185689, Speed: 0, Heading: 0
  2011-04-05T05:39:10: TPV, Time: 2011-04-05T05:39:10.00Z, Lat: 37.371420332, Lon: -122.015185689, Speed: 0, Heading: 0

=cut
