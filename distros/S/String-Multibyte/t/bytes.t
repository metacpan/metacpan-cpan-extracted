
BEGIN { $| = 1; print "1..26\n"; }
END {print "not ok 1\n" unless $loaded;}
use String::Multibyte;
$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

$bytes = String::Multibyte->new('Bytes',1);

$NG = 0;

for ("漢字テスト", "abc", "ｱｲｳｴｵ", "ﾊﾟｰﾙ=Perl", "\001\002\003\000\n",
	"", " ", '　', "それもそうだ\xFF\xFF",
	"どうにもこうにも\x81\x39", "\x91\x00", "これは\xFFどうかな") {
    $NG++ unless $bytes->islegal($_);
}

print ! $NG ? "ok" : "not ok", " 2\n";
print $bytes->islegal("あ", "P", "", "ｶﾝｼﾞ test")
	? "ok" : "not ok", " 3\n";
print $bytes->islegal("日本","さkanji","\xA0","PERL")
	? "ok" : "not ok", " 4\n";

print 0 == $bytes->length("")
	? "ok" : "not ok", " 5\n";
print 3 == $bytes->length("abc")
	? "ok" : "not ok", " 6\n";
print 5 == $bytes->length("ｱｲｳｴｵ")
	? "ok" : "not ok", " 7\n";
print 20 == $bytes->length("あかさたなはまやらわ")
	? "ok" : "not ok", " 8\n";
print 13 == $bytes->length('AIUEO日本漢字')
	? "ok" : "not ok", " 9\n";

print $bytes->mkrange("ぁ-う") eq "う"
	? "ok" : "not ok", " 10\n";
print $bytes->mkrange("ぁ-う", 1) eq 'ぁ'.pack('C*', reverse 0x83..0x9E).'う'
	? "ok" : "not ok", " 11\n";
print $bytes->mkrange("0-9０-９") eq '0123456789０'.pack('C*', 0x50..0x81).'９'
	? "ok" : "not ok", " 12\n";
print $bytes->mkrange('表-') eq "\x95-"
	? "ok" : "not ok", " 13\n";

$ref = 'ｵｴｳｲｱOEUIAoeuia';
$str = 'aiueoAIUEOｱｲｳｴｵ';
print $ref eq $bytes->strrev($str)
	? "ok" : "not ok", " 14\n";

print $bytes->strspn("XZ\0Z\0Y", "\0X\0YZ") == 6
	? "ok" : "not ok", " 15\n";
print $bytes->strcspn("Perl5.6", "0123456789") == 4
	? "ok" : "not ok", " 16\n";
print $bytes->strspn ("+0.12345*12", "+-.0123456789") == 8
	? "ok" : "not ok", " 17\n";
print $bytes->strspn("", "123") == 0
	? "ok" : "not ok", " 18\n";
print $bytes->strcspn("", "123") == 0
	? "ok" : "not ok", " 19\n";
print $bytes->strspn("AIUEO", "") == 0
	? "ok" : "not ok", " 20\n";
print $bytes->strcspn("AIUEO", "") == 5
	? "ok" : "not ok", " 21\n";
print $bytes->strspn("", "") == 0
	? "ok" : "not ok", " 22\n";
print $bytes->strcspn("", "") == 0
	? "ok" : "not ok", " 23\n";

print $bytes->strtr("90 - 32 = 58", "0-9", "A-J") eq "JA - DC = FI"
	? "ok" : "not ok", " 24\n";
print $bytes->strtr("90 - 32 = 58", "0-9", "A-J", "R") eq "JA - 32 = 58"
	? "ok" : "not ok", " 25\n";

$digit_tr = $bytes->trclosure("1234567890-", "ABCDEFGHIJ=");

$frstr1 = "TEL：0124-45-6789\n";
$tostr1 = "TEL：JABD=DE=FGHI\n";
$frstr2 = "FAX：0124-51-5368\n";
$tostr2 = "FAX：JABD=EA=ECFH\n";

$restr1 = &$digit_tr($frstr1);
$restr2 = &$digit_tr($frstr2);

print $tostr1 eq $restr1 && $tostr2 eq $restr2
	? "ok" : "not ok", " 26\n";

1;
__END__

