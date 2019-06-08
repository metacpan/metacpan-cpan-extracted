#!/usr/bin/perl
use utf8;
use lib '../lib';
use Novel::Robot::Parser;
#use Test::More ;
use Data::Dumper;

my $u = 'https://www.lewen8.com/lw44153/';
my $xs = Novel::Robot::Parser->new(
#writer_path => 
#book_path => 
#content_path=>
#writer_regex => 
#book_regex => 
#content_regex=>
novel_list_path => '//ul[@class="chapterlist"]//a', 
    site => $u, type => 'html');
my ($r) = $xs->get_item_info($u);
print Dumper($xs, $r->{floor_list}[0]);
#is($r->{writer} , '顾漫', 'book writer');
#is($r->{book} , '怀璧公主', 'book name');

#done_testing;
