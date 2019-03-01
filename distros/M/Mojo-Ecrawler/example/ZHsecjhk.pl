#!/usr/bin/perl

use LWP::Simple;
use JSON qw/encode_json decode_json from_json/;
use utf8;

my @ur=<DATA>;



for(@ur){
next if /^#/;
my $lurl=$_;
my $pcontent = get($lurl);
my $hash = decode_json($pcontent);
my $pcout1 = $hash->{"content"};
$pcout1=~s/\<br\>/\n/g;
$pcout1=~s/\<p\>/\n/g;
$pcout1=~s/\<\/p\>//g;
$pcout1=~s#https://link\.zhihu\.com/\?target=##g;
$pcout1=~s#<a href="https://link\.zhihu\.com/\?target=([^\s].*)#\1#g;
$pcout1=~s#%3A##g;
$pcout1=~s#<a href="##g;
$pcout1=~s#class=" wrap external.*##g;
$pcout1=~s#^$##g;

print $pcout1,"\n\n";


}

__DATA__
https://zhuanlan.zhihu.com/api/posts/25104414?refer=dashijian
https://zhuanlan.zhihu.com/api/posts/22684414?refer=dashijian
https://zhuanlan.zhihu.com/api/posts/22110538?refer=dashijian
https://zhuanlan.zhihu.com/api/posts/21380662
