#!/usr/bin/perl -w

=head1 NAME

example-circle.pl - Net::GPSD::Server::Fake example with circle provider

=head1 SAMPLE OUTPUT

L<http://search.cpan.org/src/MRDVT/Net-GPSD-Server-Fake-0.13/doc/track-circle.png>

=cut

use strict;
use lib qw{./lib ../lib};
use Net::GPSD::Server::Fake;
use Net::GPSD::Server::Fake::Circle;

my $filename="";
$filename="../doc/gps.tle" if -r "../doc/gps.tle";
$filename="./doc/gps.tle" if -r "./doc/gps.tle";
$filename="./gps.tle" if -r "./gps.tle";
$filename="../gps.tle" if -r "../gps.tle";
$filename="../../gps.tle" if -r "../../gps.tle";

my $port=shift()||2947;
my $server=Net::GPSD::Server::Fake->new(port=>$port, version=>2.99)
               || die("Error: Cannot create server object.");

my $provider=Net::GPSD::Server::Fake::Circle->new(lat=>38.865826,  #center
                                                  lon=>-77.108574, #center
                                                  speed=>25,       #const
                                                  heading=>45.3,   #start
                                                  distance=>-200, #-=CW,+=CCW
                                                  tlefile=>$filename);

$server->start($provider);
