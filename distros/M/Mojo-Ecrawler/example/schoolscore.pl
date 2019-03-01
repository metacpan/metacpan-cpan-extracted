#!/usr/bin/perl

use Mojo::Ecrawler;
my $key=shift;
open $collegeData,'<','collegeData';
my @schurl=<$collegeData>;

my $rschool;
my $schoolinfo;

for(@schurl) {
next if /#^/;
next if /^\s*$/;
my ($sname,$surl)=split;

#print "$sname:$surl\n";
#print "$sname:$surl\n" if $surl;
$rschool->{$sname}=$surl if $surl;

}

print Sseach($key);
#print $rschool->{$_},"$_ DDD\n" for(keys %{$rschool});
sub Sseach {

my $result;
my $key=shift;

if (exists $schoolinfo->{$key}) {
$result=$schoolinfo->{$key} 
} else {

if (exists $rschool->{$key}) {

$result= Sccore($rschool->{$key});
$schoolinfo->{$rschool->{$key}}=$result;

} else {

for(keys %{$rschool}) {

$result.=" $_" if /$key/;

 }
}

}
return $result;
}
sub Sccore {

use Encode qw(decode encode);
use utf8;

my $DUBEG=0;
my $lurl=shift;
my $WLI=1;
my $provinceset=1;
my $provinceCode="10003";

if($WLI){
 $lurl=~s#/10035/#/10034/#;

}

if($provinceset){

 my @url=split '/',$lurl;
 print "@url \n";
 $url[6]=$provinceCode if $provinceCode;
 my $llurl;
    $llurl.="$_/" for(@url);
    $llurl=~s#/$##;
    $lurl=$llurl;
}

print "DEBUG $lurl";
my $pcontent = geturlcontent($lurl);
print "DEBUG $pcontent" if $DUBEG;

my $result=getdiv($pcontent, 'div.li-collegeHome',"ul.li-collegeInfo li div div");
my $score=getdiv($pcontent, 'div.places-tab',"table tr td");

my @sscore=split /\n/sm,$score;

print "DDXX ",$sscore[1],"XXDD" if $DUBEG;

my $score1="年份|最高分|平均分|最低分|省控线|批次\n";
$result="招办电话|电子邮箱|通讯地址|招生网址\n\n".$result;

#print "DD $_\n" for(@sscore);

for(@sscore){
#chomp;
#print "$i $_\n";
next if /span/;
s#<span.*##;
s#</span.*##;
s#(20\d\d)#\n\1年#;
#print "$i $_\n";
$score1.="|$_";
#$i++;
}

$result=encode 'utf8',$result;
$score1=encode 'utf8',$score1;

return "$result\n$score1\n";

}

