#!/usr/bin/perl

use Mojo::Ecrawler;
binmode STDOUT, ":utf8";
=pod

采集数据入库
my @ur=(1..302);
#my @ur=(150..152);

#open my $ZFD,'>',"DATA" or die;

#=pod
for(@ur){

 #print $ZFD $pcontent;
 print $pcontent;
  print "get $lurl  ok \n";

}

=cut

my ( $lurl, $re1, $re2 ) = @ARGV;

$lurl = 'http://www.cert.org.cn/publish/main/9/index.html';
$re1  = "div.con_list";
$re2  = "ul li a";
my $pcontent = geturlcontent($lurl);
my @date,@urls,@title;
my $pcout1 = getdiv( $pcontent, $re1, $re2);
my $surl =getdiv( $pcontent, $re1, "ul li");
my @surl=(split /\n/sm,$surl);
   @title=(split /\n/sm,$pcout1);
for(@surl) {

push @date,$1 if /\<span\>\[(.*)\]\<\/span\>/;
push @urls,$1 if /open\(&quot;(.*)&quot;\)/;

}

for(0..$#title) {

  print "$date[$_] $title[$_] ",'http://www.cert.org.cn',$urls[$_],"\n";

}
print "get $lurl  ok \n";

