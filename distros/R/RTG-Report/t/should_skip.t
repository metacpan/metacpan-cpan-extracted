#!/usr/bin/perl
use strict;
use warnings;

use lib ".";
use lib "lib";

use Test::More 'no_plan';

BEGIN { use_ok('RTG::Report'); };
require_ok('RTG::Report');

my $reporter = RTG::Report->new();

my $if_desc = "CUST01-45-987";
my $if_name = "POD1-B2-C3-P47";
my @skip_desc = qw( free );
my @skip_name = qw( vlan port-channel );

ok( !$reporter->should_i_skip_it($if_desc, $if_name, \@skip_desc, \@skip_name), 'should_i_skip_it');

$if_name = "vlan";
ok( $reporter->should_i_skip_it($if_desc, $if_name, \@skip_desc, \@skip_name), 'should_i_skip_it');

