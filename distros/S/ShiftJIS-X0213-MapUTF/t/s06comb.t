
BEGIN { $| = 1; print "1..19\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::X0213::MapUTF qw(:all);

use strict;
$^W = 1;
our $loaded = 1;
print "ok 1\n";

our $repeat = 1000;

# SJIS 1 char from Unicode 2 chars

sub hexNCR { sprintf "&#x%04x;", shift }

#####

print "\x86\x63\x86\x63" x $repeat eq unicode_to_sjis2004(
    sjis2004_to_unicode("\x85\x7B\x86\x7B\x86\x63" x $repeat))
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x86\x63\x86\x63" x $repeat eq utf8_to_sjis2004(
    sjis2004_to_utf8("\x85\x7B\x86\x7B\x86\x63" x $repeat))
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x86\x63\x86\x63" x $repeat eq utf16le_to_sjis2004(
    sjis2004_to_utf16le("\x85\x7B\x86\x7B\x86\x63" x $repeat))
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x86\x63\x86\x63" x $repeat eq utf16be_to_sjis2004(
    sjis2004_to_utf16be("\x85\x7B\x86\x7B\x86\x63" x $repeat))
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x86\x63\x86\x63" x $repeat eq utf32le_to_sjis2004(
    sjis2004_to_utf32le("\x85\x7B\x86\x7B\x86\x63" x $repeat))
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x86\x63\x86\x63" x $repeat eq utf32be_to_sjis2004(
    sjis2004_to_utf32be("\x85\x7B\x86\x7B\x86\x63" x $repeat))
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

#####

print "\x85\x7B\x00\x86\x63\x00" eq
    unicode_to_sjis2004("\x{E6}\x00\x{E6}\x{300}\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x85\x7B\x00\x86\x63\x00" eq
    utf8_to_sjis2004("\xc3\xa6\x00\xc3\xa6\xcc\x80\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x85\x7B\x00\x86\x63\x00" eq
    utf16le_to_sjis2004("\xE6\x00\x00\x00\xE6\x00\x00\x03\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x85\x7B\x00\x86\x63\x00" eq
    utf16be_to_sjis2004("\x00\xE6\x00\x00\x00\xE6\x03\x00\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x85\x7B\x00\x86\x63\x00" eq
    utf32le_to_sjis2004("\xE6\0\0\0\x00\0\0\0\xE6\0\0\0\x00\x03\0\0\x00\0\0\0")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x85\x7B\x00\x86\x63\x00" eq
    utf32be_to_sjis2004("\0\0\0\xE6\0\0\0\x00\0\0\0\xE6\0\0\x03\x00\0\0\0\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

#####

print "\x85\x7B\x00\x86\x63\x00" eq
    unicode_to_sjis2004(sub {""}, "\x{E6}\x00\x{E6}\x{300}\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x85\x7B\x00\x86\x63\x00" eq
    utf8_to_sjis2004(sub {""}, "\xc3\xa6\x00\xc3\xa6\xcc\x80\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x85\x7B\x00\x86\x63\x00" eq
    utf16le_to_sjis2004(sub {""}, "\xE6\x00\x00\x00\xE6\x00\x00\x03\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x85\x7B\x00\x86\x63\x00" eq
    utf16be_to_sjis2004(sub {""}, "\x00\xE6\x00\x00\x00\xE6\x03\x00\x00\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x85\x7B\x00\x86\x63\x00" eq utf32le_to_sjis2004(sub {""},
	"\xE6\0\0\0\x00\0\0\0\xE6\0\0\0\x00\x03\0\0\x00\0\0\0")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "\x85\x7B\x00\x86\x63\x00" eq utf32be_to_sjis2004(sub {""},
	"\0\0\0\xE6\0\0\0\x00\0\0\0\xE6\0\0\x03\x00\0\0\0\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

