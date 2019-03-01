#!/usr/bin/perl


use Mojo::Ecrawler;
binmode STDOUT, ":utf8";

my @ur=(0..1);

open my $ZFD,'>',"cnvdUrl" or die;

#=pod
for(@ur){

  getUrl($_);
  print "get $_  ok \n";

}

sub getUrl {

my $url = shift;

$url *= 20;
my $lurl = 'http://www.cnvd.org.cn/flaw/list.htm?max=20&offset='.$url;
my $re1  = "table.tlist";
my $re2  = "div#flawList";

my $pcontent = geturlcontent($lurl);
my @date,@urls,@title;
#my $pcout1 = getdiv( $pcontent, $re1, $re2);
my $surl =getdiv( $pcontent, $re1, "tr td a",1);
my @surl=(split /\n/sm,$surl);
#   @title=(split /\n/sm,$pcout1);
for(@surl) {
s/\s+//g;
if (/flaw/){
print $ZFD " http://www.cnvd.org.cn",$_,"\n";
} else {
print $ZFD "$_" ;
}
}

}

