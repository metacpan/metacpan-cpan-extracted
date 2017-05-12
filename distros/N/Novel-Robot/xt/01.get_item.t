#!/usr/bin/perl
use utf8;
use lib '../lib';
use Novel::Robot;
use Test::More ;
use Data::Dump qw/dump/;

my $u = 'http://www.jjwxc.net/onebook.php?novelid=2530';
my $xs = Novel::Robot->new(site => $u, type => 'html');
my ($html_ref, $r) = $xs->get_item($u, output_scalar=>1);
is($r->{writer} , '顾漫', 'book writer');
is($r->{book} , '怀璧公主', 'book name');

my $tu = "http://bbs.jjwxc.net/showmsg.php?board=153&id=57";
my $tz = Novel::Robot->new(site => $tu, type => 'html');
my ($html_ref, $r) = $tz->get_item($tu, output_scalar=>1);
is($r->{writer} , '施定柔', 'tiezi writer');
is($r->{title} =~/第一章/ ? 1 : 0 , 1, 'tiezi name');

my $file = '01.get_item.txt';
my $tz = Novel::Robot->new(site => 'txt', type => 'html');
my ($html_ref, $r) = $tz->get_item($file, 
    output_scalar=>1, 
    writer => 'test', 
    book => 'xxx', 
);
is($r->{writer} , 'test', 'txt writer');
is($r->{book} , 'xxx', 'txt name');

done_testing;
