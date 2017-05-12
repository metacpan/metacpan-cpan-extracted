# /usr/bin/perl Makefile.PL; make; /usr/bin/perl -Iblib/lib t/SQLite-More.t


use Test::More tests => 54;
use DBI;
use strict;
use warnings;
BEGIN {
   use_ok('SQLite::More');
};
#-------------------------------------------------- initialize database

our $dbfile=":memory:";
unlink $dbfile if -e $dbfile;
die if -e $dbfile;

my $dbh=DBI->connect("dbi:SQLite:$dbfile",'','',
                       {RaiseError=>1, PrintError=>0, AutoCommit=>0});
$dbh->do(<<'');
  create table contestant (
    id             number,
    name           string,
    born           number,
    gender         string,
    score          number,
    country string
  )

$dbh->do('  create index i_contestant on contestant(id)  ');
my $sth=$dbh->prepare('insert into contestant values (?,?,?,?,?,?)');
$sth->execute(@$_) for map[map{$_ eq 'null'?undef:$_}split],(
    "1  Gisela   1970 Female 101 Germany",
    "2  Adam     1972 Male   106 Sweden",
    "3  Gretchen 1976 Female 108 Germany",
    "4  Ola      1977 Male   102 Norway",
    "5  Kari     1973 Female 103 Norway",
    "7  Per      1977 Male   114 Norway",
    "7  Paal     1978 Male   117 Norway",
    "8  Espen    1979 Male   122 Norway",
    "9  Julia    1963 Female 111 Sweden",
    "10 Linnea   1987 Female 123 Sweden",
    "11 Carl     1986 Male   105 Sweden",
    "12 Heinz    null Male   108 Germany",
  );
$dbh->commit;

#-------------------------------------------------- tests

my($v);
ok( ($v=$DBD::SQLite::VERSION) >= 1.27, "version $v");

#---------- test ok behaviour from sqlite
my($count,$sum,$avg,$max,$min);
ok( ($count=value("select sum(1)     from contestant")) ==   12, "count $count");
ok( ($sum=  value("select sum(score) from contestant")) == 1320, "sum $sum");
ok( ($avg=  value("select avg(score) from contestant")) ==  110, "avg $avg");
ok( ($max=  value("select max(score) from contestant")) ==  123, "max $max");
ok( ($min=  value("select min(score) from contestant")) ==  101, "min $min");

#---------- test variance not there
eval{value('select variance(score) from contestant')};
ok($@,'variance unknown --> ok');

#---------- add the new functions
sqlite_more($dbh);
my $val;
ok(  ($val=value("select greatest(score,122) from contestant where id=10")) == 123, "greatest $val" );
ok(  ($val=value("select greatest(score,null) from contestant where id=10")) == 123, "greatest $val" );
ok(  ($val=value("select greatest(score,null,124) from contestant where id=10")) == 124, "greatest $val" );
ok(  ($val=value("select least(score,102) from contestant where id=1")) == 101, "least $val" );
ok(  ($val=value("select least(score,null) from contestant where id=1")) == 101, "least $val" );
ok(  ($val=value("select least(score,null,100,".join(",",map$_%2?"null":100+$_,1..100).") from contestant where id=1")) == 100, "least $val" );

ok( value('select nvl(born,1970) from contestant where id=12') == 1970, "nvl");

ok( value('select sum(decode(born,1977,score,1970,score)) from contestant') == 101+102+114, "decode");

ok( value('select sum(decode(born,1977,score,1970,score)) from contestant group by gender order by gender desc') == 102+114, "decode");

my $rsum; $rsum+=value('select sum(random(1,6)) from contestant') for 1..100;
my $ravg=$rsum/(12*100);
ok( $ravg<=3.5 + 0.25 && $ravg >= 3.5 - 0.25, "random $ravg");

my $str="Kjetil S.";
ok(value("select upper('$str')") eq 'KJETIL S.', "upper");
ok(value("select lower('$str')") eq 'kjetil s.', "lower");

ok( eqf($v=value("select variance(score) from contestant"), 622/11),          "variance $v");
ok( eqf($v=value("select stddev(score)   from contestant"),7.51967117269462), "stddev $v");
ok( ($v=value("select median(score) from contestant"))        == 108,    "median $v");
ok( ($v=value("select percentile(50,score) from contestant")) == 108,    "percentile-50 $v");
ok( ($v=value("select percentile(75,score) from contestant")) == 116.25, "percentile-75 $v");

ok( ($v=value("select md5_hex(name) from contestant where name='Gretchen'"))          eq '00552e151f01a61ea28609d4450b6383', "md5_hex    $v");
ok( ($v=unpack("H*",value("select md5(name) from contestant where name='Gretchen'"))) eq '00552e151f01a61ea28609d4450b6383', "hex(md5()) $v");
ok( ($v=value("select md5_hex(md5_hex(name)) from contestant where name='Gretchen'")) eq '5b8adebf8b4662c8b321f99504bdb253', "md5_hex^2  $v");

my $pi=3.14159265358979323846264338327950288419716939937510;
my @oslo=(59.933983, 10.756037);
my @rio=(-22.97673,-43.19508);
my $distarg=join",",@oslo,@rio;

ok( eqf($v=value("select pi()"),                     $pi),                     "pi()       $v");
ok( eqf($v=value("select sin($pi/3)"),               sin($pi/3)),              "sin(pi/3)  $v");
ok( eqf($v=value("select cos($pi/3)"),               cos($pi/3)),              "cos(pi/3)  $v");
ok( eqf($v=value("select tan($pi/3)"),               sin($pi/3)/cos($pi/3)),   "tan(pi/3)  $v");
ok( eqf($v=value("select atan2(1,2)"),               atan2(1,2)),              "atan2(1,2) $v");
ok( eqf($v=value("select power($pi,$pi)"),           $pi**$pi),                "pi^pi      $v");
ok( eqf($v=value("select sqrt(2)"),                  sqrt(2)),                 "sqrt(2)    $v");
ok( eqf($v=value("select log10(1e6)"),               6),                       "log10(1e6) $v");
ok( eqf($v=value("select log2(power(1024,2))"),      20),                      "log2(1024) $v");
ok( eqf($v=value("select log2(power(1024,2))"),      20),                      "log2(1024) $v");
ok( eqf($v=value("select distance($distarg)/1000"),  10431476.6/1000, 2),      "oslo-rio   $v");
ok( eqf($v=value("select sprintf('\%0.2f',stddev(score)) from contestant"),7.52), "sprintf    $v");
ok( ($v=value("select sprintf('\%0.2f,%04d',stddev(score),sum(1)) from contestant")) eq '7.52,0012', "sprintf    $v");
ok( abs( ($v=value('select time()')) - time())       <=1,                      "time $v");

our %h=(1,11,2,22,3,33);
sub value{($dbh->selectrow_array(shift()))[0]}
sub eqf{my($a,$b,$p)=@_;$p||=9;sprintf("%.*f",$p,shift) == sprintf("%.*f",$p,shift)}

package brb;
our %h=(1,111,2,222,3,333);
sub brb::value{($dbh->selectrow_array(shift()))[0]}
main::ok( ($main::v=value("select perlhash('h',id) from contestant where id=3"))       == 333, "perlhash brb $main::v");
main::ok( ($main::v=main::value("select perlhash('h',id) from contestant where id=3")) == 333, "perlhash brb $main::v");
main::ok( ($main::v=value("select perlhash('main::h',id) from contestant where id=3")) ==  33, "perlhash brb $main::v");
main::ok( ($main::v=value("select perlhash('brb::h',id) from contestant where id=3"))  == 333, "perlhash brb $main::v");
1;
package main;
no warnings;
our %h; #redeclares but does not empty it
use warnings;
ok( ($v=value("select perlhash('h',id) from contestant where id=3"))                           ==  33, "perlhash value $v");
ok( ($v=($dbh->selectrow_array("select perlhash('h',id) from contestant where id=3"))[0])      ==  33, "perlhash $v");
ok( ($v=($dbh->selectrow_array("select perlhash('brb::h',id,id*id) from contestant where id=3"))[0]) == 333, "perlhash $v");
ok( ($v=($dbh->selectrow_array("select perlhash('brb::h',id) from contestant where id=3"))[0]) == 9, "perlhash $v");
ok( !defined(($dbh->selectrow_array("select perlhash('h',id) from contestant where id=4"))[0]), "not defined");
ok( !defined(($dbh->selectrow_array("select perlhash('h',id,55) from contestant where id=5"))[0]), "not defined");
ok( !exists $h{4},"not exists");
ok( $h{5}==55,"perlhash 55");
#warn join(",",values%h)."\n";
#warn __PACKAGE__;
1;
