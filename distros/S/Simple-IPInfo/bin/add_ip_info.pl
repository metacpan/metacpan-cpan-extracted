#!/usr/bin/perl 
use strict;
use warnings;
use utf8;
use Simple::IPInfo;

use Getopt::Std;
my %opt;
getopt( 'fditsH', \%opt );

$opt{d} ||= "$opt{f}.csv";
$opt{i} ||= 0;
$opt{s} ||= ',';
$opt{H} ||= 0; 
$opt{type} =  ($opt{t} and $opt{t} eq 'as') ? $Simple::IPInfo::IPINFO_AS_F : $Simple::IPInfo::IPINFO_LOC_F;
$opt{names} = ($opt{t} and $opt{t} eq 'as') ? [ 'as' ] : [ qw/country area isp country_code area_code isp_code/ ];

iterate_ipinfo(
    $opt{f}, #inet-sorted file
    i => $opt{i},
    write_file => $opt{d}, 
    sep => $opt{s}, 
    charset         => 'utf8',
    return_arrayref => 0,
    ipinfo_file => $opt{type}, 
    ipinfo_names => $opt{names}, 
    skip_head => $opt{H} ? 1 : 0, 
);
