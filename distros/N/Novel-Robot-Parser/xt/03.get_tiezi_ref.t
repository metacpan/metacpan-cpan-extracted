#!/usr/bin/perl
use utf8;
use lib '../lib';
use Novel::Robot::Parser;
use Test::More ;
use Data::Dumper;
use Encode;

## {{ hjj
my $tz = Novel::Robot::Parser->new( site => 'hjj' );
my $url = 'http://bbs.jjwxc.net/showmsg.php?board=153&id=57';
my $r = $tz->get_tiezi_ref($url);
is($r->{writer},  '施定柔', 'tiezi writer_name');
is($r->{title}=~/迷侠/ ? 1 : 0, 1, 'tiezi title');
is($r->{floor_list}[0]{content}=~/沿江西行/ ? 1 : 0, 1, 'tiezi content');
is($r->{floor_list}[1]{content}=~/柔大/ ? 1 : 0, 1, 'tiezi content2');
## }}

done_testing;

exit;

## {{ tieba 
my $url = 'http://tieba.baidu.com/p/2902224541';
my $parser = Novel::Robot::Parser->new( site => 'tieba' );

my $r = $parser->get_tiezi_ref($url, 
    min_word_num => 100, 
    only_poster => 1, 
    max_floor_num => 3, 
    max_page_num => 1, 
);
#print "$_:$r->{$_}\n" for keys(%$r);
is($r->{writer}=~/飘/? 1 : 0 , 1, 'writer');
is($r->{title}=~/立/ ? 1 : 0, 1, 'title');
is($r->{floor_list}[0]{content}=~/随波浮沉/ ? 1 : 0, 1, 'content');
## }}

done_testing;

