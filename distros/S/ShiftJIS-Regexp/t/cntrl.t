###############

use strict;
use vars qw($loaded);

BEGIN { $| = 1; print "1..23\n"; }
END {print "not ok 1\n" unless $loaded;}
use ShiftJIS::Regexp qw(:re :op);
$loaded = 1;
print "ok 1\n";

my @CTRLTEST = (0x3f..0x5f, 0x61..0x7a);
#  ?@A-Z[\]^_ and a-z

###############
{
  my($ng,$re,$rg,$n);
  my @c = map chr, 0..127;

  $ng = 0;
  for $n (@CTRLTEST) {
    $re = '[\c' . chr($n) . ']';
    $rg = re($re);
    for(@c){
      $ng++ if /$re/ ne /$rg/;
    }
  }
  print !$ng ? "ok" : "not ok", " 2\n";

  $ng = 0;
  for $n (@CTRLTEST) {
    $re = '\c' . chr($n);
    $rg = re($re);
    for(@c){
      $ng++ if /$re/ ne /$rg/;
    }
  }
  print !$ng ? "ok" : "not ok", " 3\n";
}

{
  my($ng,$re,$n,$c);

  $ng = 0;
  for $n (0..127) {
    $c  = chr($n);
    $re = re("[[=$c=]]");
    $ng++ if $c !~ /^$re$/;
  }
  print !$ng ? "ok" : "not ok", " 4\n";

  $ng = 0;
  for $n (0..127) {
    $c  = chr($n);
    $re = re("[[=\Q$c\E=]]");
    $ng++ if $c !~ /^$re$/;
  }
  print !$ng ? "ok" : "not ok", " 5\n";

  $ng = 0;
  for $n (0..127) {
    $c  = chr($n);
    $re = re(sprintf '[[=\x%02x=]]', $n);
    $ng++ if $c !~ /^$re$/;
  }
  print !$ng ? "ok" : "not ok", " 6\n";
}

sub addcomma {
    my $str = shift;
    1 while replace(\$str, '(\pD)(\pD{3})(?!\pD)', '$1ÅC$2');
    return $str;
}

print addcomma('ã‡ÇOâ~') eq 'ã‡ÇOâ~'
  ? "ok" : "not ok", " 7\n";
print addcomma('ã‡ÇUÇVÇWâ~') eq 'ã‡ÇUÇVÇWâ~'
  ? "ok" : "not ok", " 8\n";
print addcomma('ã‡ÇPÇTÇRÇOÇOÇOÇOâ~') eq 'ã‡ÇPÅCÇTÇRÇOÅCÇOÇOÇOâ~'
  ? "ok" : "not ok", " 9\n";
print addcomma('ã‡ÇPÇQÇRÇSÇTÇUÇVÇWâ~') eq 'ã‡ÇPÇQÅCÇRÇSÇTÅCÇUÇVÇWâ~'
  ? "ok" : "not ok", " 10\n";
print addcomma('ã‡ÇPÇQÇRÇSÇTÇUÇVÇWÇXÇOâ~') eq 'ã‡ÇPÅCÇQÇRÇSÅCÇTÇUÇVÅCÇWÇXÇOâ~'
  ? "ok" : "not ok", " 11\n";


print match("x\177y", 'x\c?y') ? "ok" : "not ok", " 12\n";
print match("x\000y", 'x\c@y') ? "ok" : "not ok", " 13\n";
print match("x\001y", 'x\cAy') ? "ok" : "not ok", " 14\n";
print match("x\001y", 'x\cay') ? "ok" : "not ok", " 15\n";
print match("x\032y", 'x\cZy') ? "ok" : "not ok", " 16\n";
print match("x\032y", 'x\czy') ? "ok" : "not ok", " 17\n";
print match("x\033y", 'x\c[y') ? "ok" : "not ok", " 18\n";
print match("x\034y", 'x\c\y') ? "ok" : "not ok", " 19\n";
print match("x\035y", 'x\c]y') ? "ok" : "not ok", " 20\n";
print match("x\036y", 'x\c^y') ? "ok" : "not ok", " 21\n";
print match("x\037y", 'x\c_y') ? "ok" : "not ok", " 22\n";
print match("x\040y", 'x\c`y') ? "ok" : "not ok", " 23\n";
