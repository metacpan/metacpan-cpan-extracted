#!/usr/bin/perl -w

=head1 NAME

example-stationary-gpsd.pl - Net::GPSD::Server::Fake example with stationary provider from gpsd source

=cut

use strict;
use lib qw{./lib ../lib};
use Net::GPSD::Server::Fake;
use Net::GPSD::Server::Fake::Stationary;
use Net::GPSD;

my $host=shift()||"localhost";
my $port=shift()||2947;
my $lport=shift()||2999;

my $filename="";
$filename="../doc/gps.tle" if -r "../doc/gps.tle";
$filename="./doc/gps.tle" if -r "./doc/gps.tle";
$filename="./gps.tle" if -r "./gps.tle";
$filename="../gps.tle" if -r "../gps.tle";
$filename="../../gps.tle" if -r "../../gps.tle";

my $obj=Net::GPSD->new(host=>$host, port=>$port);
my $point=$obj->get;

print "Local Port: $lport\n";
my $server=Net::GPSD::Server::Fake->new(port=>$lport, version=>2.99)
               || die("Error: Cannot create server object.");

my $provider=Net::GPSD::Server::Fake::Stationary->new(lat=>$point->lat,
                                                      lon=>$point->lon,
                                                      alt=>$point->alt,
                                                      tlefile=>$filename);
$server->start($provider);
