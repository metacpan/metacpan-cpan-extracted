#!/usr/bin/perl
use lib '../lib';
use Novel::Robot;
use Test::More;
use Data::Dumper;
use FindBin;
use utf8;

my $xs = Novel::Robot->new(site => 'txt');

my $r = $xs->{parser}->get_novel_ref("$FindBin::RealBin/novel-cp936.txt");
my $c = $r->{item_list}[1]{content};
is($c=~/华夏/, 1, 'txt content cp936');

$r2 = $xs->{parser}->get_novel_ref("$FindBin::RealBin/novel-utf8.txt");
my $c2 = $r2->{item_list}->[2]->{content};
is($c2=~/中国/s , 1 , 'txt content utf8');

done_testing;
