#!/usr/bin/perl

use Mojo::Ecrawler;
binmode STDOUT, ":utf8";


my ( $lurl, $re1, $re2 ) = @ARGV;

$lurl = 'https://segmentfault.com/news';
$re1  = "div.news__list";
$re2  = "h4.news__item-title a";
my $pcontent = geturlcontent($lurl);
my $pcout1 = getdiv( $pcontent, $re1, $re2, 1 );
print $pcout1;
print "get $lurl  ok \n";

