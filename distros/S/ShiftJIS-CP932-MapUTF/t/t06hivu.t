
BEGIN { $| = 1; print "1..25\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::CP932::MapUTF qw(:all);
$loaded = 1;
print "ok 1\n";

$repeat = 1000;

$hasUnicode = defined &cp932_to_unicode;

my $vuSjis = "abc\x82\xf2pqr\x82\xf2xyz";
my $vuUni  = $hasUnicode
	? "abc".pack('U', 0x3094)."pqr".pack('U', 0x3094)."xyz"
	: '';
my $vuUTF8 = "abc\xE3\x82\x94pqr\xE3\x82\x94xyz";
my $vuU16l = "a\x00b\x00c\x00\x94\x30p\x00q\x00r\x00\x94\x30x\x00y\x00z\x00";
my $vuU16b = "\x00a\x00b\x00c\x30\x94\x00p\x00q\x00r\x30\x94\x00x\x00y\x00z";
my $vuU32l = pack 'V*', unpack 'n*', $vuU16b;
my $vuU32b = pack 'N*', unpack 'n*', $vuU16b;
my $vuNCR  = "abc&#x3094;pqr&#x3094;xyz";

my $codeUni  = sub { $_[0] eq "\x82\xf2" ? pack('U', 0x3094) : "" };
my $codeUTF8 = sub { $_[0] eq "\x82\xf2" ? "\xE3\x82\x94"    : "" };
my $codeU16l = sub { $_[0] eq "\x82\xf2" ? pack('v', 0x3094) : "" };
my $codeU16b = sub { $_[0] eq "\x82\xf2" ? pack('n', 0x3094) : "" };
my $codeU32l = sub { $_[0] eq "\x82\xf2" ? pack('V', 0x3094) : "" };
my $codeU32b = sub { $_[0] eq "\x82\xf2" ? pack('N', 0x3094) : "" };

my $codeNCR  = sub { sprintf "&#x%04x;", shift };
my $codeSjis = sub { $_[0] == 0x3094 ? "\x82\xf2" : "" };

my $codeVnam = sub { $_[0] eq "\x82\xf2" ? "HIRAGANA LETTER VU" : "" };

print !$hasUnicode || $vuUni eq cp932_to_unicode($codeUni,  $vuSjis)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $vuUTF8 eq cp932_to_utf8($codeUTF8, $vuSjis)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $vuU16l eq cp932_to_utf16le($codeU16l, $vuSjis)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $vuU16b eq cp932_to_utf16be($codeU16b, $vuSjis)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $vuU32l eq cp932_to_utf32le($codeU32l, $vuSjis)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $vuU32b eq cp932_to_utf32be($codeU32b, $vuSjis)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode || $vuNCR eq unicode_to_cp932($codeNCR, $vuUni)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $vuNCR eq utf8_to_cp932($codeNCR, $vuUTF8)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $vuNCR eq utf16le_to_cp932($codeNCR, $vuU16l)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $vuNCR eq utf16be_to_cp932($codeNCR, $vuU16b)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $vuNCR eq utf32le_to_cp932($codeNCR, $vuU32l)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $vuNCR eq utf32be_to_cp932($codeNCR, $vuU32b)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode || $vuSjis eq unicode_to_cp932($codeSjis, $vuUni)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $vuSjis eq utf8_to_cp932($codeSjis, $vuUTF8)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $vuSjis eq utf16le_to_cp932($codeSjis, $vuU16l)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $vuSjis eq utf16be_to_cp932($codeSjis, $vuU16b)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $vuSjis eq utf32le_to_cp932($codeSjis, $vuU32l)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $vuSjis eq utf32be_to_cp932($codeSjis, $vuU32b)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode || "HIRAGANA LETTER VU" x $repeat eq
	cp932_to_unicode($codeVnam, "\x82\xf2" x $repeat)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "HIRAGANA LETTER VU" x $repeat eq
	cp932_to_utf8($codeVnam, "\x82\xf2" x $repeat)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

# "HI" is not ASCII 'H' and 'I'; This is UTF-16/32.
print "HIRAGANA LETTER VU" x $repeat eq
	cp932_to_utf16le($codeVnam, "\x82\xf2" x $repeat)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "HIRAGANA LETTER VU" x $repeat eq
	cp932_to_utf16be($codeVnam, "\x82\xf2" x $repeat)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "HIRAGANA LETTER VU" x $repeat eq
	cp932_to_utf32le($codeVnam, "\x82\xf2" x $repeat)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "HIRAGANA LETTER VU" x $repeat eq
	cp932_to_utf32be($codeVnam, "\x82\xf2" x $repeat)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

1;
__END__
