# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
# Time-stamp: "2001-02-22 16:48:25 MST"

use strict;
use Test;
BEGIN { plan tests => 129 };
use Number::Latin;
ok 1;
my($int,$lat);
for(qw(
  1=a   2=b   3=c  24=x  25=y  26=z  27=aa 28=ab 29=ac
 51=ay 52=az 53=ba 54=bb 77=by 78=bz 79=ca 80=cb
 701=zy 702=zz 703=aaa 704=aab 727=aay 728=aaz 729=aba 730=abb
 18278=zzz 18279=aaaa 475254=zzzz 475255=aaaaa
)) {
  die "bad format on \"$_\"" unless m/^(\d+)=([a-zA-Z]+)$/s;
  my($int,$lat) = ($1,$2);
  print "Now testing: $int => $lat, then $lat => $int\n";
  ok $lat eq int2latin($int);
  ok $int == latin2int($lat);
  $int = -$int;
  $lat = "-$lat";
  print "Now testing: $int => $lat, then $lat => $int\n";
  ok $lat eq int2latin($int);
  ok $int == latin2int($lat);
}
print "Testing variant capitalizations.\n";
ok 'ad' eq int2latin(30);
ok 'Ad' eq int2Latin(30);
ok 'AD' eq int2LATIN(30);
ok  30  == latin2int('ad');
ok  30  == latin2int('Ad');
ok  30  == latin2int('AD');
ok '-ad' eq int2latin(-30);
ok '-Ad' eq int2Latin(-30);
ok '-AD' eq int2LATIN(-30);
ok  -30  == latin2int('-ad');
ok  -30  == latin2int('-Ad');
ok  -30  == latin2int('-AD');
print "Tests done.\n";
