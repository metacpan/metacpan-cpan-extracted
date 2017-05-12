
BEGIN { $| = 1; print "1..80\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::String qw(:all);

$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

$n = 5000;
$f = 10;
$len = $f * $n;

$sub = "0123456Ａあ亜";
$str = $sub x $n;
$rev = "亜あＡ6543210" x $n;

print issjis($str) ? "ok" : "not ok", " 2\n";

print !issjis($str."\xFF") ? "ok" : "not ok", " 3\n";

print length($str) == $len ? "ok" : "not ok", " 4\n";

print tolower($str) eq $str ? "ok" : "not ok", " 5\n";

print toupper($str."perl") eq $str."PERL" ? "ok" : "not ok", " 6\n";

print index($str, "perl") == -1 ? "ok" : "not ok", " 7\n";

print index($str.'Ｐｅｒｌ', 'ｅｒｌ') == $len + 1 ? "ok" : "not ok", " 8\n";

print rindex($str, "あ亜") == $len - 2 ? "ok" : "not ok", " 9\n";

print rindex($str, "perl") == -1 ? "ok" : "not ok", " 10\n";

print strspn($str, $sub) == $len ? "ok" : "not ok", " 11\n";

print strcspn($str, "A") == $len ? "ok" : "not ok", " 12\n";

print strrev($str) eq $rev ? "ok" : "not ok", " 13\n";

print substr($str,-1) eq '亜' ? "ok" : "not ok", " 14\n";

print substr($str,1000*$f,2000*$f) eq ($sub x 2000)
  ? "ok" : "not ok", " 15\n";

$try = "試試試試試" x 10000;

print $try.'　' eq spaceH2Z($try.' ')
  ? "ok" : "not ok", " 16\n";
print $try.' '  eq spaceZ2H($try.'　')
  ? "ok" : "not ok", " 17\n";
print $try."AA" eq toupper($try."aA")
  ? "ok" : "not ok", " 18\n";
print $try."aa" eq tolower($try."aA")
  ? "ok" : "not ok", " 19\n";

print rspan($str, $sub) == 0 ? "ok" : "not ok", " 20\n";
print rspan($str, "A") == $len ? "ok" : "not ok", " 21\n";
print rcspan($str, "A") == 0 ? "ok" : "not ok", " 22\n";

print trim ($str, $sub) eq "" ? "ok" : "not ok", " 23\n";
print ltrim($str, $sub) eq "" ? "ok" : "not ok", " 24\n";
print rtrim($str, $sub) eq "" ? "ok" : "not ok", " 25\n";

$vu = 'う゛';
print kataH2Z('ｱ'x$n)  eq 'ア'x$n ? "ok" : "not ok", " 26\n";
print kataH2Z('ｶﾞ'x$n) eq 'ガ'x$n ? "ok" : "not ok", " 27\n";
print kataH2Z('ﾊﾟ'x$n) eq 'パ'x$n ? "ok" : "not ok", " 28\n";
print kataH2Z('･'x$n)  eq '・'x$n ? "ok" : "not ok", " 29\n";
print kanaH2Z('ｳﾞ'x$n) eq 'ヴ'x$n ? "ok" : "not ok", " 30\n";

print kanaH2Z('ｱ'x$n)  eq 'ア'x$n ? "ok" : "not ok", " 31\n";
print kanaH2Z('ｶﾞ'x$n) eq 'ガ'x$n ? "ok" : "not ok", " 32\n";
print kanaH2Z('ﾊﾟ'x$n) eq 'パ'x$n ? "ok" : "not ok", " 33\n";
print kanaH2Z('･'x$n)  eq '・'x$n ? "ok" : "not ok", " 34\n";
print kanaH2Z('ｳﾞ'x$n) eq 'ヴ'x$n ? "ok" : "not ok", " 35\n";

print hiraH2Z('ｱ'x$n)  eq 'あ'x$n ? "ok" : "not ok", " 36\n";
print hiraH2Z('ｶﾞ'x$n) eq 'が'x$n ? "ok" : "not ok", " 37\n";
print hiraH2Z('ﾊﾟ'x$n) eq 'ぱ'x$n ? "ok" : "not ok", " 38\n";
print hiraH2Z('･'x$n)  eq '・'x$n ? "ok" : "not ok", " 39\n";
print hiraH2Z('ｳﾞ'x$n) eq $vu x$n ? "ok" : "not ok", " 40\n";

print kataZ2H('ア'x$n) eq 'ｱ' x$n ? "ok" : "not ok", " 41\n";
print kataZ2H('ガ'x$n) eq 'ｶﾞ'x$n ? "ok" : "not ok", " 42\n";
print kataZ2H('パ'x$n) eq 'ﾊﾟ'x$n ? "ok" : "not ok", " 43\n";
print kataZ2H('・'x$n) eq '･' x$n ? "ok" : "not ok", " 44\n";
print kanaZ2H('ヴ'x$n) eq 'ｳﾞ'x$n ? "ok" : "not ok", " 45\n";

print hiraZ2H('あ'x$n) eq 'ｱ' x$n ? "ok" : "not ok", " 46\n";
print hiraZ2H('が'x$n) eq 'ｶﾞ'x$n ? "ok" : "not ok", " 47\n";
print hiraZ2H('ぱ'x$n) eq 'ﾊﾟ'x$n ? "ok" : "not ok", " 48\n";
print hiraZ2H('・'x$n) eq '･' x$n ? "ok" : "not ok", " 49\n";
print hiraZ2H($vu x$n) eq 'ｳﾞ'x$n ? "ok" : "not ok", " 50\n";

print kanaZ2H('ア'x$n) eq 'ｱ' x$n ? "ok" : "not ok", " 51\n";
print kanaZ2H('ガ'x$n) eq 'ｶﾞ'x$n ? "ok" : "not ok", " 52\n";
print kanaZ2H('パ'x$n) eq 'ﾊﾟ'x$n ? "ok" : "not ok", " 53\n";
print kanaZ2H('・'x$n) eq '･' x$n ? "ok" : "not ok", " 54\n";
print kanaZ2H('ヴ'x$n) eq 'ｳﾞ'x$n ? "ok" : "not ok", " 55\n";

print kanaZ2H('あ'x$n) eq 'ｱ' x$n ? "ok" : "not ok", " 56\n";
print kanaZ2H('が'x$n) eq 'ｶﾞ'x$n ? "ok" : "not ok", " 57\n";
print kanaZ2H('ぱ'x$n) eq 'ﾊﾟ'x$n ? "ok" : "not ok", " 58\n";
print kanaZ2H('・'x$n) eq '･' x$n ? "ok" : "not ok", " 59\n";
print kanaZ2H($vu x$n) eq 'ｳﾞ'x$n ? "ok" : "not ok", " 60\n";

print ka2hi('ア'x$n) eq 'あ'x$n ? "ok" : "not ok", " 61\n";
print ka2hi('ガ'x$n) eq 'が'x$n ? "ok" : "not ok", " 62\n";
print ka2hi('パ'x$n) eq 'ぱ'x$n ? "ok" : "not ok", " 63\n";
print ka2hi('ヵ'x$n) eq 'か'x$n ? "ok" : "not ok", " 64\n";
print ka2hi('ヴ'x$n) eq $vu x$n ? "ok" : "not ok", " 65\n";

print hi2ka('あ'x$n) eq 'ア'x$n ? "ok" : "not ok", " 66\n";
print hi2ka('が'x$n) eq 'ガ'x$n ? "ok" : "not ok", " 67\n";
print hi2ka('ぱ'x$n) eq 'パ'x$n ? "ok" : "not ok", " 68\n";
print hi2ka('ゐ'x$n) eq 'ヰ'x$n ? "ok" : "not ok", " 69\n";
print hi2ka($vu x$n) eq 'ヴ'x$n ? "ok" : "not ok", " 70\n";

print hiXka('ア'x$n) eq 'あ'x$n ? "ok" : "not ok", " 71\n";
print hiXka('ガ'x$n) eq 'が'x$n ? "ok" : "not ok", " 72\n";
print hiXka('パ'x$n) eq 'ぱ'x$n ? "ok" : "not ok", " 73\n";
print hiXka('ヵ'x$n) eq 'か'x$n ? "ok" : "not ok", " 74\n";
print hiXka('ヴ'x$n) eq $vu x$n ? "ok" : "not ok", " 75\n";

print hiXka('あ'x$n) eq 'ア'x$n ? "ok" : "not ok", " 76\n";
print hiXka('が'x$n) eq 'ガ'x$n ? "ok" : "not ok", " 77\n";
print hiXka('ぱ'x$n) eq 'パ'x$n ? "ok" : "not ok", " 78\n";
print hiXka('ゐ'x$n) eq 'ヰ'x$n ? "ok" : "not ok", " 79\n";
print hiXka($vu x$n) eq 'ヴ'x$n ? "ok" : "not ok", " 80\n";

__END__
