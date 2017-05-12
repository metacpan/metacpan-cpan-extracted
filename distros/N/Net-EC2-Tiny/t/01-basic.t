#!/usr/bin/perl

use strict;
use Test::More;
use Net::EC2::Tiny;
use Data::Dumper;

BEGIN { 
    if (! $ENV{AWS_ACCESS_KEY} || ! $ENV{AWS_SECRET_KEY} ) {
        plan skip_all => "Set AWS_ACCESS_KEY and AWS_SECRET_KEY environment variables to run this test.";
    }
    else {
        plan tests => 8;
    }
};

my $ec2 = Net::EC2::Tiny->new(
        AWSAccessKey => $ENV{AWS_ACCESS_KEY},
        AWSSecretKey => $ENV{AWS_SECRET_KEY},
);

isa_ok($ec2, 'Net::EC2::Tiny');

is($ec2->region, 'us-east-1', 'Region default correct');
is($ec2->version, '2012-07-20', 'API version default correct');
is($ec2->base_url, 'https://ec2.us-east-1.amazonaws.com', 'Default base url correct');

my $xml = $ec2->send(
            Action => 'DescribeRegions',
    'RegionName.1' => 'us-east-1',
    'RegionName.2' => 'eu-west-1',
);

diag Dumper $xml;

is(scalar @{$xml->{regionInfo}->{item}}, 2, '2 regions retrieved');
is($xml->{regionInfo}->{item}->[0]->{regionName}, 'us-east-1', '1st regionName correct');
is($xml->{regionInfo}->{item}->[1]->{regionName}, 'eu-west-1', '2nd regionName correct');

eval { $ec2->send() };

like($@, qr/must be defined/, 'No Action is fatal');

