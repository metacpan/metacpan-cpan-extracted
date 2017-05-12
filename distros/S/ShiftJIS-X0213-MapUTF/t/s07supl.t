
BEGIN { $| = 1; print "1..43\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::X0213::MapUTF qw(:all);
use ShiftJIS::X0213::MapUTF::Supplements;

use strict;
$^W = 1;
our $loaded = 1;
print "ok 1\n";

#####

our $uniStr = "ABC".pack('U*', 0xB5, 0x3042);

print "ABC\x82\xA0" eq unicode_to_sjis2004($uniStr)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x83\xCA\x82\xA0" eq
	unicode_to_sjis2004(\&to_sjis2004_supplements, $uniStr)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x82\xA0" eq utf8_to_sjis2004("ABC\xC2\xB5\xE3\x81\x82")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x83\xCA\x82\xA0" eq
	utf8_to_sjis2004(\&to_sjis2004_supplements, "ABC\xC2\xb5\xE3\x81\x82")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x82\xA0" eq utf16le_to_sjis2004("A\0B\0C\0\xb5\0\x42\x30")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x83\xCA\x82\xA0" eq utf16le_to_sjis2004(
	\&to_sjis2004_supplements, "A\0B\0C\0\xb5\0\x42\x30")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x83\xCA\x82\xA0" eq utf16le_to_sjis2004(
	\&to_sjis2004_supplements, "A\0B\0C\0\xb5\0\x42\x30\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x82\xA0" eq utf16be_to_sjis2004("\0A\0B\0C\0\xb5\x30\x42")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x83\xCA\x82\xA0" eq utf16be_to_sjis2004(
	\&to_sjis2004_supplements, "\0A\0B\0C\0\xb5\x30\x42")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x83\xCA\x82\xA0" eq utf16be_to_sjis2004(
	\&to_sjis2004_supplements, "\0A\0B\0C\0\xb5\x30\x42\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x82\xA0" eq utf32le_to_sjis2004
	("A\0\0\0B\0\0\0C\0\0\0\xb5\0\0\0\x42\x30\0\0")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x83\xCA\x82\xA0" eq utf32le_to_sjis2004(\&to_sjis2004_supplements,
	"A\0\0\0B\0\0\0C\0\0\0\xb5\0\0\0\x42\x30\0\0")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x83\xCA\x82\xA0" eq utf32le_to_sjis2004(\&to_sjis2004_supplements,
	"A\0\0\0B\0\0\0C\0\0\0\xb5\0\0\0\x42\x30\0\0\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x83\xCA\x82\xA0" eq utf32le_to_sjis2004(\&to_sjis2004_supplements,
	"A\0\0\0B\0\0\0C\0\0\0\xb5\0\0\0\x42\x30\0\0\x00\x01")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x82\xA0" eq utf32be_to_sjis2004(
	"\0\0\0A\0\0\0B\0\0\0C\0\0\0\xb5\0\0\x30\x42")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x83\xCA\x82\xA0" eq utf32be_to_sjis2004(\&to_sjis2004_supplements,
	"\0\0\0A\0\0\0B\0\0\0C\0\0\0\xb5\0\0\x30\x42")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x83\xCA\x82\xA0" eq utf32be_to_sjis2004(\&to_sjis2004_supplements,
	"\0\0\0A\0\0\0B\0\0\0C\0\0\0\xb5\0\0\x30\x42\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x83\xCA\x82\xA0" eq utf32be_to_sjis2004(\&to_sjis2004_supplements,
	"\0\0\0A\0\0\0B\0\0\0C\0\0\0\xb5\0\0\x30\x42\x00\x01")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

#####

our $unicode = "ABC".pack('U*', 0x2985, 0x2986, 0x9B1D, 0x3042);
our $utf8    = "ABC\xe2\xa6\x85\xe2\xa6\x86\xe9\xac\x9d\xe3\x81\x82";
our $utf16le = "A\00B\00C\00\x85\x29\x86\x29\x1D\x9B\x42\x30";
our $utf16be = "\00A\00B\00C\x29\x85\x29\x86\x9B\x1D\x30\x42";
our $utf32le = pack 'V*', unpack 'v*', $utf16le;
our $utf32be = pack 'N*', unpack 'n*', $utf16be;

our $utf16_l = "\xFF\xFE".$utf16le;
our $utf16_b = "\xFE\xFF".$utf16be;
our $utf16_n = $utf16be;
our $utf32_l = "\xFF\xFE\0\0".$utf32le;
our $utf32_b = "\0\0\xFE\xFF".$utf32be;
our $utf32_n = $utf32be;

our $sjis    = "ABC\x82\xA0";
our $sjisFB  = "ABC\x81\xD4\x81\xD5\xFC\x5A\x82\xA0";

print $sjis eq unicode_to_sjis2004($unicode)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjis eq utf8_to_sjis2004($utf8)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjis eq utf16le_to_sjis2004($utf16le)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjis eq utf16be_to_sjis2004($utf16be)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjis eq utf32le_to_sjis2004($utf32le)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjis eq utf32be_to_sjis2004($utf32be)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjis eq utf16_to_sjis2004($utf16_l)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjis eq utf16_to_sjis2004($utf16_b)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjis eq utf16_to_sjis2004($utf16_n)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjis eq utf32_to_sjis2004($utf32_l)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjis eq utf32_to_sjis2004($utf32_b)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjis eq utf32_to_sjis2004($utf32_n)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjisFB eq unicode_to_sjis2004(\&to_sjis2004_supplements, $unicode)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjisFB eq utf8_to_sjis2004   (\&to_sjis2004_supplements, $utf8)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjisFB eq utf16le_to_sjis2004(\&to_sjis2004_supplements, $utf16le)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjisFB eq utf16be_to_sjis2004(\&to_sjis2004_supplements, $utf16be)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjisFB eq utf32le_to_sjis2004(\&to_sjis2004_supplements, $utf32le)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjisFB eq utf32be_to_sjis2004(\&to_sjis2004_supplements, $utf32be)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjisFB eq utf16_to_sjis2004(\&to_sjis2004_supplements, $utf16_l)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjisFB eq utf16_to_sjis2004(\&to_sjis2004_supplements, $utf16_b)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjisFB eq utf16_to_sjis2004(\&to_sjis2004_supplements, $utf16_n)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjisFB eq utf32_to_sjis2004(\&to_sjis2004_supplements, $utf32_l)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjisFB eq utf32_to_sjis2004(\&to_sjis2004_supplements, $utf32_b)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print $sjisFB eq utf32_to_sjis2004(\&to_sjis2004_supplements, $utf32_n)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

