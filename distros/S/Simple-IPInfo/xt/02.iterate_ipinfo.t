#!/usr/bin/perl
use lib '../lib';
use Simple::IPInfo;
use Data::Dumper;
use Test::More ;

$Simple::IPInfo::DEBUG =1 ;

my $f = '02.ip_raw.csv';
my $r = get_ipinfo(
    $f, 
    i => 0,
    write_file => '02.get_ipinfo.csv', 
    sep => ',', 
    charset         => 'utf8',
    return_arrayref => 1,
    ipinfo_file => $Simple::IPInfo::IPInfo_LOC_F, 
    ipinfo_names    => [qw/country area isp country_code area_code isp_code/],
    write_head => [qw/ip some country area isp country_code area_code isp_code/ ], 
);
#print Dumper($r);
is($r->[-1][-3],  'US', 'get_ipinfo return_arrayref');

my $r = iterate_ipinfo(
   '02.ip_inet.sort.csv', 
    id=>0,
    write_file => '02.iterate_ipinfo.csv', 
    sep => ',', 
    charset         => 'utf8',
    return_arrayref => 1,
    ipinfo_names    => [qw/country area isp country_code area_code isp_code/],
    write_head => [qw/inet some country area isp country_code area_code isp_code/ ], 
    #skip_head => 1, 
);
#print Dumper($r);
is($r->[-1][-3],  'CN', 'iterate_ipinfo return_arrayref');
    
done_testing;
