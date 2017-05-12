#!/usr/bin/perl -w

=head1 NAME

example-track.pl - Net::GPSD::Server::Fake example with linear provider

=cut

use strict;
use lib qw{./lib ../lib};
use Net::GPSD::Server::Fake;
use Net::GPSD::Server::Fake::Track;

my $filename="";
$filename="../doc/gps.tle" if -r "../doc/gps.tle";
$filename="./doc/gps.tle" if -r "./doc/gps.tle";
$filename="./gps.tle" if -r "./gps.tle";
$filename="../gps.tle" if -r "../gps.tle";
$filename="../../gps.tle" if -r "../../gps.tle";
die unless -r $filename;

my $port=shift()||2947;
my $server=Net::GPSD::Server::Fake->new(port=>$port, version=>2.99, debug=>0)
               || die("Error: Cannot create server object.");

my $provider=Net::GPSD::Server::Fake::Track->new(lat=>38.865826,
                                                 lon=>-77.108574,
                                                 alt=>23.45,
                                                 speed=>20, #m/s
                                                 heading=>60, #CW from N
                                                 tlefile=>$filename);

$server->start($provider);
