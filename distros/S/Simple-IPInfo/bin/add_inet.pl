#!/usr/bin/perl 
use strict;
use warnings;
use utf8;
use Simple::IPInfo;
use SimpleR::Reshape;

use Getopt::Std;
my %opt;
getopt( 'fditsH', \%opt );

$opt{d} ||= "$opt{f}.csv";
$opt{i} //= 0;
$opt{s} //= ',';
$opt{H} //= 0; 

read_table(
    $opt{f},
    conv_sub => sub {
        my ($r) = @_;
        my $ip = $r->[$opt{i}];
        my ($inet) = ip_to_inet($ip);
        push @$r, $inet;
        return $r;
    }, 
    write_file => $opt{d}, 
    sep => $opt{s}, 
    charset         => 'utf8',
    return_arrayref => 0,
    skip_head => $opt{H} ? 1 : 0, 
);
