
BEGIN { $| = 1; print "1..28\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::X0213::MapUTF qw(:all);

use strict;
$^W = 1;
our $loaded = 1;
print "ok 1\n";

#####

print "" eq utf16le_to_sjis0213("\x00")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf16be_to_sjis0213("\x00")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x00" eq utf16le_to_sjis0213("\x00\x00")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x00" eq utf16be_to_sjis0213("\x00\x00")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf32le_to_sjis0213("\x00")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf32be_to_sjis0213("\x00")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf32le_to_sjis0213("\x00\x00")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf32be_to_sjis0213("\x00\x00")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf32le_to_sjis0213("\x00\x00\x00")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf32be_to_sjis0213("\x00\x00\x00")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x00" eq utf32be_to_sjis0213("\x00\x00\x00\x00")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x00" eq utf32le_to_sjis0213("\x00\x00\x00\x00")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x82\xA0\x41" eq utf16le_to_sjis0213("\x42\x30\x00\xAC\x41\x00\x41")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x82\xA0\x41" eq utf16be_to_sjis0213("\x30\x42\xAC\x00\x00\x41\x41")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x82\xA0\x41" eq
	utf32le_to_sjis0213("\x42\x30\0\0\x00\xAC\0\0\x41\x00\0\0\x41")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x82\xA0\x41" eq
	utf32be_to_sjis0213("\0\0\x30\x42\0\0\xAC\x00\0\0\x00\x41\x41")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x85\x56\x42" eq utf8_to_sjis0213("\xC3\x80\xC0\x80\xC2\x42\xC2\x80")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x82\x9f" eq utf8_to_sjis0213("\xE3\x81\xE3\x81\x81")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x00" eq utf8_to_sjis0213("\xFF\x81\x81\x00")
   ? "ok" : "not ok" , " ", ++$loaded, "\n";

#####

print "\x85\x7B\x85\x7B" eq
    utf8_to_sjis0213("\xc3\xa6\xc3\xa6\xcc")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x85\x7B\x85\x7B" eq
    utf16le_to_sjis0213("\xE6\x00\xE6\x00\x03")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x85\x7B\x85\x7B" eq
    utf16be_to_sjis0213("\x00\xE6\x00\xE6\x03")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x85\x7B\x85\x7B" eq
    utf32le_to_sjis0213("\xE6\0\0\0\xE6\0\0\0\x00\x03")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x85\x7B\x85\x7B" eq
    utf32be_to_sjis0213("\0\0\0\xE6\0\0\0\xE6\0\x03\0")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x85\x7B\x85\x7B\x85\x7B" eq
    utf8_to_sjis0213("\xc3\xa6\xc3\xa6\xcc\xc3\xa6")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf8_to_sjis0213("\xF0\xAA\xB3\x9E\xF0")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "" eq utf8_to_sjis0213("\xC2\xB5\xC3")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

