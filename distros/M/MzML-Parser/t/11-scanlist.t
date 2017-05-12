#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'lib';
use MzML::Parser;

plan tests => 2;

my $p = MzML::Parser->new();
my $res = $p->parse("t/miape_sample.mzML");

cmp_ok( $res->scanSettingsList->scanSettings->[0]->targetList->target->[0]->userParam->[0]->value, '==', "123.456", "scanlist userparam value" );

cmp_ok( $res->scanSettingsList->scanSettings->[0]->targetList->target->[1]->userParam->[0]->value, '==', "231.673", "scanlist userparam value" );
