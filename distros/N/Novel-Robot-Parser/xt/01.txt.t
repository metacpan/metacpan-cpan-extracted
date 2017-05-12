#!/usr/bin/perl
use lib '../lib';
use Novel::Robot::Parser;
use Test::More ;
use Data::Dumper;
use utf8;

my $xs = Novel::Robot::Parser->new(site => 'txt');

my $r = $xs->get_item_ref('01.txt-cp936.txt');
is($r->{floor_list}[-2]{content}=~/华夏/s , 1 , 'txt content cp936');

my $r = $xs->get_item_ref('01.txt-utf8.txt');
is($r->{floor_list}[-1]{content}=~/中国/s , 1 , 'txt content utf8');

done_testing;
