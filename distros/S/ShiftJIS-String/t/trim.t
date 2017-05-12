
BEGIN { $| = 1; print "1..64\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::String qw(:all);

$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

print '' eq ltrim('')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq rtrim('')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq trim ('')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq ltrim('', '')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq rtrim('', '')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq trim ('', '')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq ltrim('', '', 1)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq rtrim('', '', 1)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq trim ('', '', 1)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq ltrim('', 'Perl')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq rtrim('', 'Perl')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq trim ('', 'Perl')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq ltrim('', 'Perl', 1)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq rtrim('', 'Perl', 1)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq trim ('', 'Perl', 1)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print 'Perl' eq ltrim('Perl', '')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print 'Perl' eq rtrim('Perl', '')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print 'Perl' eq trim ('Perl', '')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq ltrim('Perl', '', 1)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq rtrim('Perl', '', 1)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq trim ('Perl', '', 1)
   ? "ok" : "not ok", " ", ++$loaded, "\n";

#####

print ltrim('あい　う　えお') eq 'あい　う　えお'
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print rtrim('あい　う　えお') eq 'あい　う　えお'
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print trim ('あい　う　えお') eq 'あい　う　えお'
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print ltrim('　 あい　う　えお　  　') eq 'あい　う　えお　  　'
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print rtrim('　 あい　う　えお　  　') eq '　 あい　う　えお'
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print trim ('　 あい　う　えお　  　') eq 'あい　う　えお'
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print ltrim('abcvca012abc345xayz', 'abcdevwxyz') eq '012abc345xayz'
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print rtrim('abcvca012abc345xayz', 'abcdevwxyz') eq 'abcvca012abc345'
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print trim('abcvca012abc345xayz', 'abcdevwxyz') eq '012abc345'
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq ltrim('あいうあいえおうえおあいうえお', 'あいうえお')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq rtrim('あいうあいえおうえおあいうえお', 'あいうえお')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq trim ('あいうあいえおうえおあいうえお', 'あいうえお')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print ltrim('　　Perl 　　', '　　') eq 'Perl 　　'
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print rtrim('　　Perl 　　', '　　') eq '　　Perl '
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print trim ('　　Perl 　　', '　　') eq 'Perl '
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq ltrim('日本語Perl' x 5, 'P日e本r語l')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq rtrim('日本語Perl' x 5, 'P日e本r語l')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print '' eq trim ('日本語Perl' x 5, 'P日e本r語l')
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print ltrim("\c@\cA\c@\cB\c@\cA\c@\c@", "\x00") eq "\cA\c@\cB\c@\cA\c@\c@"
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print rtrim("\c@\cA\c@\cB\c@\cA\c@\c@", "\x00") eq "\c@\cA\c@\cB\c@\cA"
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print trim ("\c@\cA\c@\cB\c@\cA\c@\c@", "\x00") eq "\cA\c@\cB\c@\cA"
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print trim ("\n\f\r\t\t") eq ""
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print ltrim("\n\f\r\t\t") eq ""
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print rtrim("\n\f\r\t\t") eq ""
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print trim ("abc012xyz345def", "0123456789", 1) eq "012xyz345"
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print ltrim("abc012xyz345def", "0123456789", 1) eq "012xyz345def"
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print rtrim("abc012xyz345def", "0123456789", 1) eq "abc012xyz345"
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print trim ("abcxyzdef", "0123456789", 1) eq ""
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print ltrim("abcxyzdef", "0123456789", 1) eq ""
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print rtrim("abcxyzdef", "0123456789", 1) eq ""
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print trim ("314159265358979", "0123456789", 1) eq "314159265358979"
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print ltrim("314159265358979", "0123456789", 1) eq "314159265358979"
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print rtrim("314159265358979", "0123456789", 1) eq "314159265358979"
   ? "ok" : "not ok", " ", ++$loaded, "\n";

$string = "\x02\x00\x01Pe\x00rl\x03\x1F\x1e";

print trim ($string, mkrange("\x00-\x20")) eq "Pe\x00rl"
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print ltrim($string, mkrange("\x00-\x20")) eq "Pe\x00rl\x03\x1F\x1e"
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print rtrim($string, mkrange("\x00-\x20")) eq "\x02\x00\x01Pe\x00rl"
   ? "ok" : "not ok", " ", ++$loaded, "\n";

$string = 'ABCDEアイPQRウエオXYZ';

print trim ($string, mkrange("A-Z")) eq 'アイPQRウエオ'
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print ltrim($string, mkrange("A-Z")) eq 'アイPQRウエオXYZ'
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print rtrim($string, mkrange("A-Z")) eq 'ABCDEアイPQRウエオ'
   ? "ok" : "not ok", " ", ++$loaded, "\n";

$string = 'ABCDEｱｲPQRｳｴｵXYZ';

print trim ($string, mkrange("A-Z")) eq 'ｱｲPQRｳｴｵ'
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print ltrim($string, mkrange("A-Z")) eq 'ｱｲPQRｳｴｵXYZ'
   ? "ok" : "not ok", " ", ++$loaded, "\n";

print rtrim($string, mkrange("A-Z")) eq 'ABCDEｱｲPQRｳｴｵ'
   ? "ok" : "not ok", " ", ++$loaded, "\n";

1;
__END__
