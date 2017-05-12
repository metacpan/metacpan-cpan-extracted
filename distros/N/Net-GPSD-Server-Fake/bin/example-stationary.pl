#!/usr/bin/perl -w

=head1 NAME

example-stationary.pl - Net::GPSD::Server::Fake example with stationary provider

=cut

use strict;
use lib qw{./lib ../lib};
use Net::GPSD::Server::Fake;
use Net::GPSD::Server::Fake::Stationary;

my $filename="";
$filename="../doc/gps.tle" if -r "../doc/gps.tle";
$filename="./doc/gps.tle" if -r "./doc/gps.tle";
$filename="./gps.tle" if -r "./gps.tle";
$filename="../gps.tle" if -r "../gps.tle";
$filename="../../gps.tle" if -r "../../gps.tle";

my $port=shift()||2947;
my $server=Net::GPSD::Server::Fake->new(port=>$port, version=>2.99, debug=>99)
               || die("Error: Cannot create server object.");

my $provider=Net::GPSD::Server::Fake::Stationary->new(lat=>38.865826,
                                                      lon=>-77.108574,
                                                      alt=>25,
                                                      tlefile=>$filename);
$server->start($provider);
