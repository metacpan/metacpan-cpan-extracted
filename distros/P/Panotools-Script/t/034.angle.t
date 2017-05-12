#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';

use Panotools::Script;
use Panotools::Script::Line::Image;
use Panotools::Script::Line::Control;

my $p = new Panotools::Script;
$p->Read ('t/data/cemetery/hugin.pto');

ok ($p->AngularDistance (0, 1) == $p->AngularDistance (0, 1));
ok ($p->AngularDistance (1, 2) == $p->AngularDistance (2, 1));
ok ($p->AngularDistance (0, 1) != $p->AngularDistance (1, 2));

ok ($p->AngularDistance (0, 1) < 40 and $p->AngularDistance (2, 3) > 25);
ok ($p->AngularDistance (1, 2) < 40 and $p->AngularDistance (2, 3) > 25);
ok ($p->AngularDistance (2, 3) < 40 and $p->AngularDistance (2, 3) > 25);
ok ($p->AngularDistance (0, 4) < 40 and $p->AngularDistance (2, 3) > 25);

ok ($p->Connections (0, 1) == 12);
ok ($p->Connections (1, 2) == 7);
ok ($p->Connections (2, 3) == 12);
ok ($p->Connections (0, 4) == 10);

ok ($p->Connections (0, 2) == 0);
ok ($p->Connections (0, 3) == 0);
ok ($p->Connections (1, 3) == 0);
ok ($p->Connections (1, 4) == 0);
ok ($p->Connections (4, 2) == 0);
ok ($p->Connections (4, 3) == 0);

ok ($p->Connections (0, 0) == 0);
ok ($p->Connections (1, 1) == 0);
ok ($p->Connections (2, 2) == 0);
ok ($p->Connections (3, 3) == 0);
ok ($p->Connections (4, 4) == 0);

ok (scalar @{$p->ConnectedGroups} == 1);
ok (scalar @{$p->ConnectedGroups->[0]} == 5);

push @{$p->Image}, new Panotools::Script::Line::Image;

ok (scalar @{$p->ConnectedGroups} == 2);
ok (scalar @{$p->ConnectedGroups->[0]} == 5);
ok (scalar @{$p->ConnectedGroups->[1]} == 1);

push @{$p->Image}, new Panotools::Script::Line::Image;

ok (scalar @{$p->ConnectedGroups} == 3);
ok (scalar @{$p->ConnectedGroups->[0]} == 5);
ok (scalar @{$p->ConnectedGroups->[1]} == 1);
ok (scalar @{$p->ConnectedGroups->[2]} == 1);

push @{$p->Control}, new Panotools::Script::Line::Control;

%{$p->Control->[-1]} = (n => 5, N => 6, x => 1, X => 2, y => 3, Y => 4, t => 0);

ok (scalar @{$p->ConnectedGroups} == 2);
ok (scalar @{$p->ConnectedGroups->[0]} == 5);
ok (scalar @{$p->ConnectedGroups->[1]} == 2);

