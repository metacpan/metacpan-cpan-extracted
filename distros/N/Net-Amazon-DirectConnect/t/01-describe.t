#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More;

plan skip_all => 'AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY not set' and exit unless (exists $ENV{AWS_ACCESS_KEY_ID} and exists $ENV{AWS_SECRET_ACCESS_KEY});
plan tests => 4;

use_ok( 'Net::Amazon::DirectConnect' );

my $dx = Net::Amazon::DirectConnect->new;
isa_ok($dx, 'Net::Amazon::DirectConnect', 'Net::Amazon::DirectConnect->new returns DirectConnect object');

my $connections;
eval {
    $connections = $dx->action('DescribeConnections');
};
ok(exists $connections->{connections}, 'DescribeConnections API call succeeded');
isa_ok($connections->{connections}, 'ARRAY', 'DescribeConnections returned a valid object');
