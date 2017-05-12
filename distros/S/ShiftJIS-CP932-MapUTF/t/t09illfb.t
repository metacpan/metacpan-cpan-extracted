
BEGIN { $| = 1; print "1..22\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::CP932::MapUTF qw(:all);

$loaded = 1;
print "ok 1\n";

sub fb {
    my ($char, $byte) = @_;
    defined $char ? sprintf("&#x%x;", $char) : sprintf("[%02x]", $byte);
}

##### 2..13

print "[00]" eq utf16le_to_cp932(\&fb, "\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "[00]" eq utf16be_to_cp932(\&fb, "\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x00" eq utf16le_to_cp932(\&fb, "\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x00" eq utf16be_to_cp932(\&fb, "\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "[00]" eq utf32le_to_cp932(\&fb, "\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "[00]" eq utf32be_to_cp932(\&fb, "\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "[00][00]" eq utf32le_to_cp932(\&fb, "\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "[00][00]" eq utf32be_to_cp932(\&fb, "\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "[00][00][00]" eq utf32le_to_cp932(\&fb, "\x00\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "[00][00][00]" eq utf32be_to_cp932(\&fb, "\x00\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x00" eq utf32be_to_cp932(\&fb, "\x00\x00\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x00" eq utf32le_to_cp932(\&fb, "\x00\x00\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

##### 14..20

print "\x82\xA0&#xac00;A[41]" eq
	utf16le_to_cp932(\&fb, "\x42\x30\x00\xAC\x41\x00\x41")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x82\xA0&#xac00;A[41]" eq
	utf16be_to_cp932(\&fb, "\x30\x42\xAC\x00\x00\x41\x41")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x82\xA0&#xac00;A[41]" eq
	utf32le_to_cp932(\&fb, "\x42\x30\0\0\x00\xAC\0\0\x41\x00\0\0\x41")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x82\xA0&#xac00;A[41]" eq
	utf32be_to_cp932(\&fb, "\0\0\x30\x42\0\0\xAC\x00\0\0\x00\x41\x41")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "&#xc0;[c0][80][c2]B&#x80;" eq
	utf8_to_cp932(\&fb, "\xC3\x80\xC0\x80\xC2\x42\xC2\x80")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "[e3][81]\x82\x9f" eq utf8_to_cp932(\&fb, "\xE3\x81\xE3\x81\x81")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "[ff][81][81]\x00" eq utf8_to_cp932(\&fb, "\xFF\x81\x81\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "&#x2acde;[f0]" eq utf8_to_cp932(\&fb, "\xF0\xAA\xB3\x9E\xF0")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "&#xc0;[c3]" eq utf8_to_cp932(\&fb, "\xC3\x80\xC3")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

1;
__END__

