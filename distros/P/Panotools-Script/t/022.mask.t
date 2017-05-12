#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';

use Panotools::Script;
use Panotools::Script::Line::Mask;

my $p = new Panotools::Script;
$p->Read ('t/data/cemetery/hugin.pto');

ok (scalar @{$p->Mask} == 1);

ok ($p->Mask->[0]->{i} == 2);
ok ($p->Mask->[0]->{t} == 0);
ok ($p->Mask->[0]->{p} =~ /^"[ 0-9.-]+"$/);

ok ($p->Mask->[0]->Report);
