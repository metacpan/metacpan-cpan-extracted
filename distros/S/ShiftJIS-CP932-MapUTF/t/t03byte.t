
BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::CP932::MapUTF qw(:all);
$loaded = 1;
print "ok 1\n";

$repeat = 1000;

$hasUnicode = defined &cp932_to_unicode;

print "\x71\xff\x72\xff\x73\xff\x74\xff\x75\xff"
	x $repeat eq cp932_to_utf16le("\xb1\xb2\xb3\xb4\xb5" x $repeat)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\xff\x71\xff\x72\xff\x73\xff\x74\xff\x75"
	x $repeat eq cp932_to_utf16be("\xb1\xb2\xb3\xb4\xb5" x $repeat)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x71\xff\0\0\x72\xff\0\0\x73\xff\0\0\x74\xff\0\0\x75\xff\0\0"
	x $repeat eq cp932_to_utf32le("\xb1\xb2\xb3\xb4\xb5" x $repeat)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\0\0\xff\x71\0\0\xff\x72\0\0\xff\x73\0\0\xff\x74\0\0\xff\x75"
	x $repeat eq cp932_to_utf32be("\xb1\xb2\xb3\xb4\xb5" x $repeat)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\xEF\xBD\xB1\xEF\xBD\xB2\xEF\xBD\xB3\xEF\xBD\xB4\xEF\xBD\xB5"
	x $repeat eq cp932_to_utf8("\xb1\xb2\xb3\xb4\xb5" x $repeat)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print ! $hasUnicode || pack('U*', 0xff71, 0xff72, 0xff73, 0xff74, 0xff75)
	x $repeat eq cp932_to_unicode("\xb1\xb2\xb3\xb4\xb5" x $repeat)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print ! $hasUnicode || "\x81\x7E\x00\x81\x80\0\x41" eq
	unicode_to_cp932("\xd7\x00\xf7\0\x41")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print ! $hasUnicode || "\x81\x4c\x81\x4e\x81\x7d\x81\x7e\x81\x80" x $repeat eq
	unicode_to_cp932("\xb4\xa8\xb1\xd7\xf7" x $repeat)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print ! $hasUnicode || "\x5C\x5C\x5C\x5C\x5C" x $repeat eq
	unicode_to_cp932("\x5c\x5c\x5c\x5c\x5c" x $repeat)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

1;
__END__
