#!/usr/bin/perl
use lib '../lib';
use Simple::IPInfo;
use Data::Dumper;
use Test::More ;
use utf8;

$Simple::IPInfo::DEBUG=1;

my $rr = get_ip_loc([ [ '202.38.64.10'], ['202.96.196.33'] ]);
#print Dumper($rr),"\n";
is($rr->[0][-3],  'CN', 'get_ip_loc ip country_code');
is($rr->[0][-2],  '34', 'get_ip_loc ip area_code');
is($rr->[0][-1],  'EDU', 'get_ip_loc ip isp_code');

my $rr = get_ip_loc([ ['3395339297'], ['3391504394'] ]);
#print Dumper($rr),"\n";
is($rr->[1][-3],  'CN', 'get_ip_loc inet country_code');
is($rr->[1][-2],  '34', 'get_ip_loc inet area_code');
is($rr->[1][-1],  'EDU', 'get_ip_loc inet isp_code');

my $rr = get_ipinfo([ [ '202.38.64.10'], ['202.96.196.33'] ], reserve_inet=>1);
#print Dumper($rr),"\n";
is($rr->[0][1],  '3391504394', 'get_ipinfo reserve_inet');

my $rr = get_ip_as([ ['8.8.8.8'], ['202.38.64.10'], ['202.96.196.33'] ]);
#print Dumper($rr),"\n";
is($rr->[1][1],  '4538', 'get_ip_as');

done_testing;
