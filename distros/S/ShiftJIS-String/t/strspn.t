
BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::String qw(:all);

$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

print strspn ("", "") == 0
   && strcspn("", "") == 0
   && rspan  ("", "") == 0
   && rcspan ("", "") == 0
 ? "ok" : "not ok", " 2\n";

print strspn ("", "123") == 0
   && strcspn("", "123") == 0
   && rspan  ("", "123") == 0
   && rcspan ("", "123") == 0
 ? "ok" : "not ok", " 3\n";

print strspn ("あいうえお", "") == 0
   && strcspn("あいうえお", "") == 5
   && rspan  ("あいうえお", "") == 5
   && rcspan ("あいうえお", "") == 0
 ? "ok" : "not ok", " 4\n";

print strspn ("XZ\0Z\0Y", "\0X\0YZ") == 6
   && strcspn("XZ\0Z\0Y", "\0X\0YZ") == 0
   && rspan  ("XZ\0Z\0Y", "\0X\0YZ") == 0
   && rcspan ("XZ\0Z\0Y", "\0X\0YZ") == 6
 ? "ok" : "not ok", " 5\n";

print strspn ("Perlは面白い。", "XY\0r") == 0
   && strcspn("Perlは面白い。", "XY\0r") == 2
   && rspan  ("Perlは面白い。", "XY\0r") == 9
   && rcspan ("Perlは面白い。", "XY\0r") == 3
 ? "ok" : "not ok", " 6\n";

print strspn ("+0.12345*12", "+-.0123456789") == 8
   && strcspn("+0.12345*12", "+-.0123456789") == 0
   && rspan  ("+0.12345*12", "+-.0123456789") == 9
   && rcspan ("+0.12345*12", "+-.0123456789") == 11
 ? "ok" : "not ok", " 7\n";

print strspn ("Perlは面白い。", "赤青黄白黒") == 0
   && strcspn("Perlは面白い。", "赤青黄白黒") == 6
   && rspan  ("Perlは面白い。", "赤青黄白黒") == 9
   && rcspan ("Perlは面白い。", "赤青黄白黒") == 7
 ? "ok" : "not ok", " 8\n";

print strspn("あいうcえおnおえういあpあ", "あいうえお") == 3
   && rspan ("あいうcえおnおえういあpあ", "あいうえお") == 13
   && strspn("あいうcえおnおえういあpqr", "あいうえお") == 3
   && rspan ("あいうcえおnおえういあpqr", "あいうえお") == 15
 ? "ok" : "not ok", " 9\n";

#####

$string = '　　  　あい\nうAB　C えxお　 　';

print substr($string, strspn($string, ' 　'))
	eq 'あい\nうAB　C えxお　 　'
   && substr($string, 0, strspn($string, ' 　'))
	eq '　　  　'
   && substr($string, rspan($string, ' 　'))
	eq '　 　'
   && substr($string, 0, rspan($string, ' 　'))
	eq '　　  　あい\nうAB　C えxお'
   && substr(substr($string, 0, rspan($string, ' 　')),
	strspn($string, ' 　')) eq 'あい\nうAB　C えxお'
 ? "ok" : "not ok", " 10\n";

#####

$string = 'あい\nうAB　C えxお　 　';

print substr($string, strspn($string, ' 　'))
	eq 'あい\nうAB　C えxお　 　'
   && substr($string, 0, strspn($string, ' 　'))
	eq ''
   && substr($string, rspan($string, ' 　'))
	eq '　 　'
   && substr($string, 0, rspan($string, ' 　'))
	eq 'あい\nうAB　C えxお'
 ? "ok" : "not ok", " 11\n";

#####

$string = '　　  　あい\nうAB　C えxお';

print substr($string, strspn($string, ' 　'))
	eq 'あい\nうAB　C えxお'
   && substr($string, 0, strspn($string, ' 　'))
	eq '　　  　'
   && substr($string, rspan($string, ' 　'))
	eq ''
   && substr($string, 0, rspan($string, ' 　'))
	eq '　　  　あい\nうAB　C えxお'
 ? "ok" : "not ok", " 12\n";

#####

$string = 'あい\nうAB　C えxおa';

print substr($string, strspn($string, ' 　'))
	eq 'あい\nうAB　C えxおa'
   && substr($string, 0, strspn($string, ' 　'))
	eq ''
   && substr($string, rspan($string, ' 　'))
	eq ''
   && substr($string, 0, rspan($string, ' 　'))
	eq 'あい\nうAB　C えxおa'
 ? "ok" : "not ok", " 13\n";

#####

print rspan ('+0123456789*+!', '*+!#$%') == 11
   && rspan ('＋０１２３４５６７８９＊＋！', '＊＋！＃＄％') == 11
   && rspan ('あいうえあえうお', "あいうえお") == 0
   && rcspan('ABCあいうXYZ', "あいうえお") == 6
   && rcspan('ABCＰｅｒｌXYZ', "あいうえお") == 0
 ? "ok" : "not ok", " 14\n";

1;
__END__
