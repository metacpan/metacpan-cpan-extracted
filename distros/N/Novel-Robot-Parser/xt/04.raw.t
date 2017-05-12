#!/usr/bin/perl
use lib '../lib';
use utf8;
use Novel::Robot::Parser;
use Test::More ;
use Encode::Locale;
use Encode;
use Data::MessagePack;
use Data::Dumper;
use Novel::Robot;

my $xs = Novel::Robot->new( site=> 'jjwxc', type=>'raw' );
my $index_url = 'http://www.jjwxc.net/onebook.php?novelid=22742';
my $index_ref = $xs->get_item($index_url, min_item_num=>3, max_item_num=>3, output=>'04.test.raw');

my $rxs = Novel::Robot::Parser->new( site=> 'raw' );
my $r = $rxs->parse_novel('04.test.raw');
#print Dumper($r);

is($r->{writer}, '牵机', 'raw writer');
is($r->{floor_list}[-1]{content}=~/萦后情怀/s, 1, 'raw content');

done_testing;
