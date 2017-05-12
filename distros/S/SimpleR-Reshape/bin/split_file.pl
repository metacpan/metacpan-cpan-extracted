#!/usr/bin/perl
use utf8;
use strict;
use warnings;
use SimpleR::Reshape;
use Getopt::Std;

my %opt;
getopt('fistl', \%opt);

if($opt{l}){
    print "$opt{f}, $opt{l}\n";
    split_file($opt{f}, 
        line_cnt => $opt{l},
        split_file => $opt{t}, 
    );
}else{
    $opt{s} ||= ',';
    $opt{i} //= 0;
    split_file($opt{f}, id => $opt{i},
        sep => $opt{s}, 
        split_file => $opt{t}, 
    );
}
