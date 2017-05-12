
BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}

use String::Multibyte;
$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

$mb = String::Multibyte->new('EUC',1);

$NG = 0;
for ("漢字テスト", "abc", "\001\002\003\000\n", "", " ", '　') {
    $NG++ unless $mb->islegal($_);
}
print !$NG ? "ok" : "not ok", " 2\n";

$NG = 0;
for ("それもそうだ\xFF\xFF", "どうにもこうにも\x81\x39", "\xA1\x21",
    "ｱｲｳｴｵ", "ﾊﾟｰﾙ=Perl", "\x91\x00", "これは\xFFどうかな") {
    $NG++ unless ! $mb->islegal($_);
}
print !$NG ? "ok" : "not ok", " 3\n";

print $mb->islegal("あ", "P", "", "漢字test")
  && ! $mb->islegal("日本","さkanji","\xA0","PERL")
    ? "ok" : "not ok", " 4\n";

print 0 eq $mb->length("")
  &&  3 eq $mb->length("abc")
  &&  4 eq $mb->length("abc\n")
  &&  5 eq $mb->length("アイウエオ")
  && 10 eq $mb->length("あかさたなはまやらわ")
  && 14 eq $mb->length("あかさたな\n\nはまやらわ\n\n")
  &&  9 eq $mb->length('AIUEO日本漢字')
  ? "ok" : "not ok", " 5\n";

print $mb->mkrange("ぁ-う") eq "ぁあぃいぅう"
  &&  $mb->mkrange("0-9０-９") eq "0123456789０１２３４５６７８９"
  &&  $mb->mkrange('表-') eq '表-'
    ? "ok" : "not ok", " 6\n";

$ref = '字漢本日 OEUIAoeuiaおえういあ';
$str = 'あいうえおaiueoAIUEO 日本漢字';

print $ref eq $mb->strrev($str)
    ? "ok" : "not ok", " 7\n";

print $mb->strspn("XZ\0Z\0Y", "\0X\0YZ") == 6
   && $mb->strcspn("Perlは面白い。", "XY\0r") == 2
   && $mb->strspn("+0.12345*12", "+-.0123456789") == 8
   && $mb->strcspn("Perlは面白い。", "赤青黄白黒") == 6
   && $mb->strspn("", "123") == 0
   && $mb->strcspn("", "123") == 0
   && $mb->strspn("あいうえお", "") == 0
   && $mb->strcspn("あいうえお", "") == 5
   && $mb->strspn("", "") == 0
   && $mb->strcspn("", "") == 0
 ? "ok" : "not ok", " 8\n";

$str = "なんといおうか";
print $mb->strtr(\$str,"あいうえお", "アイウエオ") == 3
    && $str eq "なんとイオウか"
  ? "ok" : "not ok", " 9\n";

print $mb->strtr('おかかうめぼし　ちちとはは', 'ぁ-ん', '', 's')
	eq 'おかうめぼし　ちとは'
   && $mb->strtr("条件演算子の使いすぎは見苦しい", 'ぁ-ん', '＃', 'cs')
	eq '＃の＃いすぎは＃しい'
   && $mb->strtr("90 - 32 = 58", "0-9", "A-J") eq "JA - DC = FI"
   && $mb->strtr("90 - 32 = 58", "0-9", "A-J", "R") eq "JA - 32 = 58"
    ? "ok" : "not ok", " 10\n";

$digit_tr = $mb->trclosure("1234567890-", "一二三四五六七八九〇−");

$frstr1 = "TEL：0124-45-6789\n";
$tostr1 = "TEL：〇一二四−四五−六七八九\n";
$frstr2 = "FAX：0124-51-5368\n";
$tostr2 = "FAX：〇一二四−五一−五三六八\n";

$restr1 = &$digit_tr($frstr1);
$restr2 = &$digit_tr($frstr2);

print $tostr1 eq $restr1 && $tostr2 eq $restr2
    ? "ok" : "not ok", " 11\n";

1;
__END__
