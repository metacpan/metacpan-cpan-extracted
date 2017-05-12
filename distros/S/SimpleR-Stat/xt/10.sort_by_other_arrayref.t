#!/usr/bin/perl
use utf8;
use lib '../lib';
use SimpleR::Stat;
use Test::More ;
use Data::Dump qw/dump/;

my $label = [ qw/x y z/ ];
my $data = [ [qw/3 2 1 4/],  [ qw/2 3 5 6/ ], [qw/4 5 1 6/] ];

my ($new_label, $new_data) = sort_by_other_arrayref(
    $label, $data, 
     sub { # data line
        my ($r) = @_; 
        my ($g, $n, $b, $f) = @$r;
        my $all = $g+$n+$b+$f;
        return [ $f/$all, $b/$all ] }, 
     sub {
        my ($x, $y) = @_;
        ($x->[0] <=> $y->[0]) or ($x->[1] <=> $y->[1]) },
);
dump($new_label, $new_data);
#$new_label ["z", "y", "x"]
#$new_data  [[4, 5, 1, 6], [2, 3, 5, 6], [3, 2, 1, 4]]

done_testing;
