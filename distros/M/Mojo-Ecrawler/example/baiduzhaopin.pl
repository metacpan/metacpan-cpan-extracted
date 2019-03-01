#!/usr/bin/perl

use Mojo::Ecrawler;
binmode( STDOUT, ':encoding(utf8)' );

=pod
使用方法 perl baiduzhaopin.pl php

=cut

my ( $lurl, $re1, $re2 );
my $language = shift;
$language //= "perl";
$lurl = 'https://zhaopin.baidu.com/quanzhi?query=' . $language;
$re1  = "div.listpage";
$re2  = "div";
my $pcontent = geturlcontent($lurl);

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

