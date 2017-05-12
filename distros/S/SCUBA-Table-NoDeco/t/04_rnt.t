#!/usr/bin/perl -w

use strict;
use Test::More tests => 6;

BEGIN { use_ok('SCUBA::Table::NoDeco') };

my $sdt = SCUBA::Table::NoDeco->new();

$sdt->dive(metres => 10.5, minutes => 3);
is($sdt->group,"A");
is($sdt->rnt(metres => 3),39);
is($sdt->rnt(metres => 6),18);
is($sdt->rnt(metres => 9),12);
is($sdt->rnt(metres => 39),3);
