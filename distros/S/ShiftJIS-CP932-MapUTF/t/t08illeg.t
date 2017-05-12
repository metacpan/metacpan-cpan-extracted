
BEGIN { $| = 1; print "1..22\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::CP932::MapUTF qw(:all);

$loaded = 1;
print "ok 1\n";

##### 2..13

print "" eq utf16le_to_cp932("\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf16be_to_cp932("\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x00" eq utf16le_to_cp932("\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x00" eq utf16be_to_cp932("\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf32le_to_cp932("\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf32be_to_cp932("\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf32le_to_cp932("\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf32be_to_cp932("\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf32le_to_cp932("\x00\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf32be_to_cp932("\x00\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x00" eq utf32be_to_cp932("\x00\x00\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x00" eq utf32le_to_cp932("\x00\x00\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

##### 14..20

print "\x82\xA0\x41" eq utf16le_to_cp932("\x42\x30\x00\xAC\x41\x00\x41")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x82\xA0\x41" eq utf16be_to_cp932("\x30\x42\xAC\x00\x00\x41\x41")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x82\xA0\x41" eq
	utf32le_to_cp932("\x42\x30\0\0\x00\xAC\0\0\x41\x00\0\0\x41")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x82\xA0\x41" eq
	utf32be_to_cp932("\0\0\x30\x42\0\0\xAC\x00\0\0\x00\x41\x41")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "B" eq utf8_to_cp932("\xC3\x80\xC0\x80\xC2\x42\xC2\x80")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x82\x9f" eq utf8_to_cp932("\xE3\x81\xE3\x81\x81")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x00" eq utf8_to_cp932("\xFF\x81\x81\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf8_to_cp932("\xF0\xAA\xB3\x9E\xF0")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf8_to_cp932("\xC3\x80\xC3")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";


#####

1;
__END__
