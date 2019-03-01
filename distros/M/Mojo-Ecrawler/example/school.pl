#!/usr/bin/perl

use Mojo::Ecrawler;
use utf8;
binmode( STDOUT, ':encoding(utf8)' );

=pod
使用方法 perl baiduzhaopin.pl php

=cut
open $collegeData,'>','collegeData';
for(30..2996) {
#my @id=qw(30..2996)
my ( $lurl, $re1, $re2 );
my $language = $_;
#$language //= "北京大学";

$lurl = 'https://gkcx.eol.cn/schoolhtm/schoolTemple/school' . $language.'.htm';
#print "$lurl\n";
$re1  = "div.s_nav";
$re2  = "a";
my $pcontent = geturlcontent($lurl);

my $name =getdiv( $pcontent, "head","title");
$name=~s/高考招生——高考志愿填报参考系统//;
my $urls=getdiv( $pcontent, $re1,"ul");
my @line=split '\n',$urls;
my $score_url;
for(@line){
$score_url=$_ if /schoolAreaPoint/;

}
$score_url=~s#\s+<li><a href="##;
$score_url=~s#">各省录取线</a></li>##;
$score_url=~s#^\s+#https://gkcx.eol.cn#;
chomp($score_url);
print $collegeData "$name$score_url\n\n";

}

close $collegeData;
=pod
my $urls=getdiv( $pcontent, $re1,"a",1),"\n";
my @nurl=split /\n/ms,$urls;
my @source;
for(@nurl) {
s/^\s+// if /szzw/;
 push @source,"http://zhaopin.baidu.com$_ \n" if /szzw/;
}

my @tile        = split /\n/ms, getdiv( $pcontent, $re1, "a div.left div span");
#print "@tile","\n";
#my @source      = split /\n/ms, getdiv( $pcontent, $re1, "div.'right time' p" );
my @time        = split /\n/ms, getdiv( $pcontent, $re1, "a div.right p" );
my @city        = split /\n/ms, getdiv( $pcontent, $re1, "a div.title p" );
my @company     = split /\n/ms, getdiv( $pcontent, $re1, "a div.left p" );
my @salary      = split /\n/ms, getdiv( $pcontent, $re1, "a div.right p.salary" );
#my @discription = split /\n/ms, getdiv( $pcontent, $re1, "a div.right p" );

#print $pcout1;
for ( 0 .. scalar(@tile) - 1 ) {
    print $tile[$_],    "\n";
    print $source[$_]  ;
    print $time[$_]    ;
    print $city[$_],    "\n";
    print $company[$_], "\n";
    print $salary[$_],  "\n";
    print "\n=================\n";
 #   print $discription[ 2 * $_ ], "\n";
 #   print $discription[ 2 * $_ + 1 ], "\n\n";
}
print "get $lurl  ok \n";

