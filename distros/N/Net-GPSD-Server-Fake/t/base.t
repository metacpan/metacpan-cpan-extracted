#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: base.t,v 0.1 2006/02/21 eserte Exp $
# Author: Michael R. Davis
#

=head1 NAME

base.t - Good examples concerning how to use this module

=cut

use strict;
use lib q{lib};
use lib q{../lib};

sub near {
  my $x=shift();
  my $y=shift();
  my $p=shift()||7;
  if (($x-$y)/$y < 10**-$p) {
    return 1;
  } else {
    return 0;
  }
}


BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "1..0 # tests only works with installed Test module\n";
	exit;
    }
}

BEGIN { plan tests => 20 }

# just check that all modules can be compiled
ok(eval {require Net::GPSD::Server::Fake; 1}, 1, $@);

my $server = Net::GPSD::Server::Fake->new();

ok(ref $server, "Net::GPSD::Server::Fake");
ok($server->port, "2947");
ok($server->name, "GPSD");

ok(eval {require Net::GPSD::Server::Fake::Track; 1}, 1, $@);
my $track = Net::GPSD::Server::Fake::Track->new(lat=>39,
                                                lon=>-77,
                                                speed=>25,
                                                heading=>45);
ok(ref $track, "Net::GPSD::Server::Fake::Track");
my $p1=$track->get();
ok(ref $p1, "Net::GPSD::Point");
ok($p1->lat, 39);
ok($p1->lon, -77);
ok($p1->speed, 25);
ok($p1->heading, 45);

ok(eval {require Net::GPSD::Server::Fake::Stationary; 1}, 1, $@);
my $stationary = Net::GPSD::Server::Fake::Stationary->new(lat=>38,lon=>-78);
ok(ref $stationary, "Net::GPSD::Server::Fake::Stationary");
my $p2=$stationary->get();
ok(ref $p2, "Net::GPSD::Point");
ok($p2->lat, 38);
ok($p2->lon, -78);
ok($p2->speed, 0);

ok(eval {require Net::GPSD::Server::Fake::Circle; 1}, 1, $@);
my $circle = Net::GPSD::Server::Fake::Circle->new(lat=>38,
                                                  lon=>-78,
                                                  distance=>1000,
                                                  speed=>22.2,
                                                  heading=>33.3);
ok(ref $circle, "Net::GPSD::Server::Fake::Circle");
my $p3=$circle->get();
ok(ref $p3, "Net::GPSD::Point");
near($p3->lat, 38.0064366217834);
near($p3->lon, -77.9920334180003);
