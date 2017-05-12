#!/usr/bin/perl -w

use strict;
use Test::More tests => 12;

BEGIN { use_ok('SCUBA::Table::NoDeco') };

my $sdt = SCUBA::Table::NoDeco->new();

$sdt->dive(metres => 9, minutes => 60);
is($sdt->group,"D","60 minutes at 9 m is group D");
is($sdt->surface(minutes => 5),5,"5 minutes surface interval");
is($sdt->group,"D","5 minutes out of water, still D");
is($sdt->surface(minutes => 65),70,"70 minutes surface interval");
is($sdt->group,"C","1:10 out of water, group C");
is($sdt->surface(minutes => 110),180,"180 minutes surface interval");
is($sdt->group,"B","3:00 out of water, group B");
is($sdt->surface(minutes => 180),360,"360 minutes surface interval");
is($sdt->group,"A","6:00 out of water, group A");
is($sdt->surface(minutes => 361),721,"721 minutes surface interval");
is($sdt->group,"","12:01 out of water, no group");
