
BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}
use String::Multibyte;
$^W = 1;
$loaded = 1;
print "ok 1\n";

$mb = String::Multibyte->new({
	charset => 'sjis_grapheme',
	regexp => '[\xB3\xB6-\xC4]\xDE|[\xCA-\xCE][\xDE\xDF]|' .
	    '[\x00-\x7F\xA1-\xDF]|[\x81-\x9F\xE0-\xFC][\x40-\x7E\x80-\xFC]',
    }, 1);

$NG = 0;
for ("漢字テスト", "abc", "ｱｲｳｴｵ", "ﾊﾟｰﾙ=Perl",
	"\001\002\003\000\n", "", " ", '　') {
    $NG++ unless $mb->islegal($_);
}
print !$NG ? "ok" : "not ok", " 2\n";

for ("それもそうだ\xFF\xFF", "どうにもこうにも\x81\x39",
	"\x91\x00", "これは\xFFどうかな") {
    $NG++ unless ! $mb->islegal($_);
}
print !$NG ? "ok" : "not ok", " 3\n";

print $mb->islegal("あ", "P", "", "ｶﾝｼﾞ test")
    && ! $mb->islegal("日本","さkanji","\xA0","PERL")
  ? "ok" : "not ok", " 4\n";

print 0 eq $mb->length("")
  &&  3 eq $mb->length("abc")
  &&  4 eq $mb->length("abc\n")
  &&  5 eq $mb->length("ｱｲｳｴｵ")
  &&  3 eq $mb->length("ﾊﾟｰﾙ")
  &&  6 eq $mb->length("ｶﾞｷﾞｸﾞｹﾞｺﾞｳﾞ")
  && 10 eq $mb->length("あかさたなはまやらわ")
  && 14 eq $mb->length("あかさたな\n\nはまやらわ\n\n")
  &&  9 eq $mb->length('AIUEO日本漢字')
  ? "ok" : "not ok", " 5\n";

$ref = '字漢本日ｵｴｳｲｱOEUIAoeuiaおえういあ';
$str = 'あいうえおaiueoAIUEOｱｲｳｴｵ日本漢字';

print $ref eq $mb->strrev($str)
  ? "ok" : "not ok", " 6\n";

$ref = 'ﾊﾟｰﾙを使ってｱｿﾋﾞﾏｼｮｳ';
$str = 'ｳｮｼﾏﾋﾞｿｱてっ使をﾙｰﾊﾟ';

print $ref eq $mb->strrev($str)
  ? "ok" : "not ok", " 7\n";

print $mb->strspn ("XZ\0Z\0Y", "\0X\0YZ") == 6
   && $mb->strcspn("Perlは面白い。", "XY\0r") == 2
   && $mb->strspn ("+0.12345*12", "+-.0123456789") == 8
   && $mb->strcspn("Perlは面白い。", "赤青黄白黒") == 6
   && $mb->strspn ("", "123") == 0
   && $mb->strcspn("", "123") == 0
   && $mb->strspn ("あいうえお", "") == 0
   && $mb->strcspn("あいうえお", "") == 5
   && $mb->strspn ("ﾊﾟﾊﾟﾊﾍﾟﾎﾟ", "ﾊﾟﾋﾟﾌﾟﾍﾟﾎﾟ") == 2
   && $mb->strcspn("ｹｻﾉｺﾞﾊﾝﾊ", "ｶﾞｷﾞｸﾞｹﾞｺﾞ") == 3
   && $mb->strspn ("ﾊﾟﾊﾟﾊﾍﾟﾎﾟ", "ﾊﾋﾌﾍﾎ") == 0
   && $mb->strcspn("ﾊﾟﾊﾟﾊﾍﾟﾎﾟ", "ﾊﾋﾌﾍﾎ") == 2
   && $mb->strspn ("ｹｻﾉｺﾞﾊﾝﾊ", "ｶｷｸｹｺ") == 1
   && $mb->strcspn("ｹｻﾉｺﾞﾊﾝﾊ", "ｶｷｸｹｺ") == 0
   && $mb->strspn ("", "") == 0
   && $mb->strcspn("", "") == 0
 ? "ok" : "not ok", " 8\n";

$str = "なんといおうか";
print 3 eq $mb->strtr(\$str,"あいうえお", "アイウエオ")
    && $str eq "なんとイオウか"
    ? "ok" : "not ok", " 9\n";

$digit_tr = $mb->trclosure(
    "1234567890-", "一二三四五六七八九〇－");

$frstr1 = "TEL：0124-45-6789\n";
$tostr1 = "TEL：〇一二四－四五－六七八九\n";
$frstr2 = "FAX：0124-51-5368\n";
$tostr2 = "FAX：〇一二四－五一－五三六八\n";

$restr1 = &$digit_tr($frstr1);
$restr2 = &$digit_tr($frstr2);

print $tostr1 eq $restr1 && $tostr2 eq $restr2
    ? "ok" : "not ok", " 10\n";

print $mb->index("", "") == 0
   && $mb->index("", "a") == -1
   && $mb->index(" ", "") == 0
   && $mb->index(" ", "", 1) == 1
   && $mb->index("", " ", 1) == -1
   && $mb->index(" ", "a", -1) == -1
   && $mb->index("\x81\x81\x40\x81\x40", "\x81\x40") == 2
   && $mb->index("ｴﾄ､ｴﾄﾞ", "ｴﾄﾞ") == 3
   && $mb->index("ｴﾄ､ｴﾄ", "ｴﾄﾞ") == -1
   && $mb->index("ｴﾄ､ｴﾄﾞ", "ｴﾄ") == 0
   && $mb->index("ｴﾄﾞ､ｴﾄ", "ｴﾄ") == 3
   && $mb->index("ﾅｶﾀﾞ､ﾅｶﾀ", "ﾅｶﾀ") == 4
   && $mb->index("ﾅｶﾀﾞ､ﾅｶﾀ", "ﾅｶﾀﾞ") == 0
    ? "ok" : "not ok", " 11\n";

print $mb->rindex("", "") == 0
   && $mb->rindex("", "a") == -1
   && $mb->rindex(" ", "") == 1
   && $mb->rindex(" ", "", 1) == 1
   && $mb->rindex("", " ", 1) == -1
   && $mb->rindex(" ", "a", -1) == -1
   && $mb->rindex("\x81\x81\x40\x81\x40", "\x81\x40") == 2
   && $mb->rindex("ｴﾄ､ｴﾄﾞ", "ｴﾄﾞ") == 3
   && $mb->rindex("ｴﾄ､ｴﾄ", "ｴﾄﾞ") == -1
   && $mb->rindex("ｴﾄ､ｴﾄﾞ", "ｴﾄ") == 0
   && $mb->rindex("ｴﾄﾞ､ｴﾄ", "ｴﾄ") == 3
   && $mb->rindex("ﾅｶﾀﾞ､ﾅｶﾀ", "ﾅｶﾀ") == 4
   && $mb->rindex("ﾅｶﾀﾞ､ﾅｶﾀ", "ﾅｶﾀﾞ") == 0
    ? "ok" : "not ok", " 12\n";

print "ｶﾞｶﾞｶﾞｶﾞｶﾞ:ｶﾞｶﾞｶﾞｶﾞ:ｶﾞｶﾞｶﾞ" eq
	join(':', $mb->strsplit("ｶ", "ｶﾞｶﾞｶﾞｶﾞｶﾞｶｶﾞｶﾞｶﾞｶﾞｶｶﾞｶﾞｶﾞ"))
   && "ｶﾞｶﾞｶﾞｶﾞｶﾞｶｶﾞｶﾞｶﾞｶﾞｶｶﾞｶﾞｶﾞ" eq
	join(':', $mb->strsplit("ｶ", "ｶﾞｶﾞｶﾞｶﾞｶﾞｶｶﾞｶﾞｶﾞｶﾞｶｶﾞｶﾞｶﾞ", 1))
   && "ｶﾞｶﾞｶﾞｶﾞｶﾞ:ｶﾞｶﾞｶﾞｶﾞｶｶﾞｶﾞｶﾞ" eq
	join(':', $mb->strsplit("ｶ", "ｶﾞｶﾞｶﾞｶﾞｶﾞｶｶﾞｶﾞｶﾞｶﾞｶｶﾞｶﾞｶﾞ", 2))
   && "ｶﾞｶﾞｶﾞｶﾞｶﾞ:ｶﾞｶﾞｶﾞｶﾞ:ｶﾞｶﾞｶﾞ" eq
	join(':', $mb->strsplit("ｶ", "ｶﾞｶﾞｶﾞｶﾞｶﾞｶｶﾞｶﾞｶﾞｶﾞｶｶﾞｶﾞｶﾞ", 3))
   && "ｶﾞｶﾞｶﾞ:ｶﾞｶﾞ:ｶﾞｶﾞｶﾞ" eq
	join(':', $mb->strsplit("ｶﾞｶﾞｶ", "ｶﾞｶﾞｶﾞｶﾞｶﾞｶｶﾞｶﾞｶﾞｶﾞｶｶﾞｶﾞｶﾞ"))
   && "ｶﾞｶﾞｶﾞ::ｶﾞ:ｶﾞｶﾞ" eq
	join(':', $mb->strsplit("ｶﾞｶﾞｶ", "ｶﾞｶﾞｶﾞｶﾞｶﾞｶｶﾞｶﾞｶｶﾞｶﾞｶﾞｶｶﾞｶﾞ"))
   && "ｶﾞｶﾞ:ｶﾞｶﾞｶ:ｶﾞｶﾞ" eq
	join(':', $mb->strsplit("ｶﾞｶﾞｶﾞｶ", "ｶﾞｶﾞｶﾞｶﾞｶﾞｶｶﾞｶﾞｶｶﾞｶﾞｶﾞｶｶﾞｶﾞ"))
    ? "ok" : "not ok", " 13\n";

1;
__END__

