
BEGIN { $| = 1; print "1..23\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::CP932::MapUTF qw(:all);
$loaded = 1;
print "ok 1\n";

$hasUnicode = defined &cp932_to_unicode;

$hasPackU = $] >= 5.008 && pack('U', 0xFF) eq pack('C', 0xFF); # ASCII-Latin1
# Failed Pure Perl on Perl 5.6.0 && 5.6.1.

##### 2..7

$string = $hasPackU
	? pack('U*', 0x81, 0x40, 0x42, 0x82, 0xA0)
	: "\x81\x40\x42\x82\xA0";

print cp932_to_utf16be($string) eq "\x30\x00\x00\x42\x30\x42"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16le($string) eq "\x00\x30\x42\x00\x42\x30"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32be($string) eq "\0\0\x30\x00\0\0\x00\x42\0\0\x30\x42"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32le($string) eq "\x00\x30\0\0\x42\x00\0\0\x42\x30\0\0"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf8   ($string) eq "\xE3\x80\x80\x42\xE3\x81\x82"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode ||
	cp932_to_unicode($string) eq pack('U*', 0x3000, 0x42, 0x3042)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

##### 8..11

print !$hasUnicode ||
	unicode_to_cp932(pack 'C*', 0xD7, 0xF7) eq "\x81\x7E\x81\x80"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode ||
	unicode_to_cp932(pack 'C*', 0x41, 0xF7) eq "\x41\x81\x80"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode ||
	unicode_to_cp932(pack 'C*', 0x41, 0x80) eq "\x41"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode ||
	unicode_to_cp932(pack('C*', 0x41, 0x80), 's') eq "\x41\x80"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

##### 12..23

print !$hasPackU ||
	"\xFF\x9D" eq pack('U*', 0xFF, 0x9D)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasPackU ||
	utf16be_to_cp932(pack 'U*', 0xFF,0x9D) eq "\xDD"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasPackU ||
	utf16le_to_cp932(pack 'U*', 0x9D,0xFF) eq "\xDD"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasPackU ||
	utf32be_to_cp932(pack 'U*', 0,0,0xFF,0x9D) eq "\xDD"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasPackU ||
	utf32le_to_cp932(pack 'U*', 0x9D,0xFF,0,0) eq "\xDD"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasPackU ||
	utf8_to_cp932(pack 'U*', 0xEF,0xBE,0x9D) eq "\xDD"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasPackU ||
	utf16_to_cp932(pack 'U*', 0xFF,0x9D) eq "\xDD"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasPackU ||
	utf16_to_cp932(pack 'U*', 0xFE,0xFF, 0xFF,0x9D) eq "\xDD"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasPackU ||
	utf16_to_cp932(pack 'U*', 0xFF,0xFE, 0x9D,0xFF) eq "\xDD"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasPackU ||
	utf32_to_cp932(pack 'U*', 0,0,0xFF,0x9D) eq "\xDD"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasPackU ||
	utf32_to_cp932(pack 'U*', 0,0,0xFE,0xFF, 0,0,0xFF,0x9D) eq "\xDD"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasPackU ||
	utf32_to_cp932(pack 'U*', 0xFF,0xFE,0,0, 0x9D,0xFF,0,0) eq "\xDD"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

#####

1;
__END__
