#!/usr/bin/perl
# vim: ft=perl:fdm=marker:fmr=#<,#>:fen:et:sw=2:
use strict;
use vars     qw($VERSION);
use autodie  qw(:all);

my $APP  = 'dzen-uptime';
$VERSION = '0.001';

# $ while true; do perl dzen_uptime.pl; sleep 1; done | dzen2

use Number::RGB;
use Term::ExtendedColor::Dzen qw(fgd bgd);


open(my $fh, '<', '/proc/loadavg') or die $!;
chomp(my $uptime = <$fh>);
close $fh;

my @avg = $uptime =~ m/(\d+[.]\d+)/g;

$avg[0] = fgd(Number::RGB->new(rgb => randhex())->hex, $avg[0]);
$avg[1] = fgd(Number::RGB->new(rgb => randhex())->hex, $avg[1]);
$avg[2] = fgd(Number::RGB->new(rgb => randhex())->hex, $avg[2]);

my $bg = Number::RGB->new(rgb => randhex())->hex;

$avg[0] = bgd($bg, $avg[0]);
$avg[1] = bgd($bg, $avg[1]);
$avg[2] = bgd($bg, $avg[2]);

print join('', @avg), "\n";

sub randhex {
  return [
    int(rand(255)),
    int(rand(255)),
    int(rand(255)),
  ]
}
