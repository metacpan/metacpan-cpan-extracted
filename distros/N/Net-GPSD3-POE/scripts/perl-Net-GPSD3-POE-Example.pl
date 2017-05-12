#!/usr/bin/perl
use strict;
use warnings;
$|=1;

=head1 NAME

perl-Net-GPSD3-POE-Example.pl - Net::GPSD3::POE Example

=cut

use POE;
use Net::GPSD3::POE;
my $host=shift || undef;
my $port=shift || undef;

my $gpsd=Net::GPSD3::POE->new(host=>$host, port=>$port); #default host port as undef
$gpsd->session;           #default handler
POE::Kernel->run;

=head1 EXAMPLE OUTPUT

  2011-04-05T05:18:42: VERSION, GPSD: 2.96 (2011-03-17T02:51:23), Net::GPSD3::POE: 0.15
  2011-04-05T05:18:43: DEVICES, Devices: /dev/cuaU0 (9600 bps uBlox UBX binary-none)
  2011-04-05T05:18:43: WATCH, Enabled: 1
  2011-04-05T05:18:43: TPV, Time: 2011-04-05T05:18:43.00Z, Lat: 37.371417341, Lon: -122.015183283, Speed: 0, Heading: 0
  2011-04-05T05:18:44: TPV, Time: 2011-04-05T05:18:44.00Z, Lat: 37.371417341, Lon: -122.015183283, Speed: 0, Heading: 0
  2011-04-05T05:18:45: TPV, Time: 2011-04-05T05:18:45.00Z, Lat: 37.371417341, Lon: -122.015183283, Speed: 0, Heading: 0
  2011-04-05T05:18:46: TPV, Time: 2011-04-05T05:18:45.00Z, Lat: 37.371417387, Lon: -122.015183342, Speed: 0, Heading: 0
  2011-04-05T05:18:47: TPV, Time: 2011-04-05T05:18:46.00Z, Lat: 37.371417387, Lon: -122.015183342, Speed: 0, Heading: 0
  2011-04-05T05:18:48: TPV, Time: 2011-04-05T05:18:47.00Z, Lat: 37.371417387, Lon: -122.015183342, Speed: 0, Heading: 0
  2011-04-05T05:18:48: SKY, Satellites: 12, Used: 7, PRNs: 28,8,15,27,26,17,135
  2011-04-05T05:18:49: TPV, Time: 2011-04-05T05:18:48.00Z, Lat: 37.371417387, Lon: -122.015183342, Speed: 0, Heading: 0
  2011-04-05T05:18:50: TPV, Time: 2011-04-05T05:18:49.00Z, Lat: 37.371417387, Lon: -122.015183342, Speed: 0, Heading: 0
  2011-04-05T05:18:51: TPV, Time: 2011-04-05T05:18:50.00Z, Lat: 37.371417387, Lon: -122.015183342, Speed: 0, Heading: 0

=cut
