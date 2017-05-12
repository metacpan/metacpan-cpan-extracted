
BEGIN { $| = 1; print "1..168\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::CP932::MapUTF qw(:all);
use ShiftJIS::CP932::MapUTF::Supplements;

$hasUnicode = defined &cp932_to_unicode;

$loaded = 1;
print "ok 1\n";

#####

@arys = (
  [ "\x81\x91", "\xC2\xA2",     "A2"  ], #  2.. 12
  [ "\x81\x92", "\xC2\xA3",     "A3"  ], # 13.. 23
  [ "\x5C",     "\xC2\xA5",     "A5"  ], # 24.. 34
  [ "\xFA\x55", "\xC2\xA6",     "A6"  ], # 35.. 45
  [ "\x81\x50", "\xC2\xAF",     "AF"  ], # 46.. 56
  [ "\x83\xCA", "\xC2\xB5",     "B5"  ], # 57.. 67
  [ "\x81\x45", "\xC2\xB7",     "B7"  ], # 68.. 78
  [ "\x81\x5C", "\xE2\x80\x94", "2014"], # 79.. 89
  [ "\x81\x61", "\xE2\x80\x96", "2016"], # 90..100
  [ "\x7E",     "\xE2\x80\xBE", "203E"], #101..111
  [ "\x81\x7C", "\xE2\x88\x92", "2212"], #112..122
  [ "\x81\x60", "\xE3\x80\x9C", "301C"], #123..133
  [ "\x83\x94", "\xE3\x82\x94", "3094"], #134..144
);

for $ary (@arys) {
    my $cp932   = $ary->[0];
    my $cp932re = defined $ary->[3] ? $ary->[3] : $ary->[0];
    my $utf8    = $ary->[1];
    my @char    = map { $_ eq 'n' ? ord("\n") : hex $_ } split /:/, $ary->[2];
    my $unicode = $hasUnicode ? pack 'U*', @char : "";
    my $utf16le = pack 'v*', @char;
    my $utf16be = pack 'n*', @char;
    my $utf32le = pack 'V*', @char;
    my $utf32be = pack 'N*', @char;
    my $utf16_l = pack 'v*', 0xFEFF, @char;
    my $utf16_b = pack 'n*', 0xFEFF, @char;
    my $utf16_n = pack 'n*', @char;
    my $utf32_l = pack 'V*', 0xFEFF, @char;
    my $utf32_b = pack 'N*', 0xFEFF, @char;
    my $utf32_n = pack 'N*', @char;

    print $cp932re eq utf8_to_cp932(\&to_cp932_supplements, $utf8)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16le_to_cp932(\&to_cp932_supplements, $utf16le)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16be_to_cp932(\&to_cp932_supplements, $utf16be)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32le_to_cp932(\&to_cp932_supplements, $utf32le)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32be_to_cp932(\&to_cp932_supplements, $utf32be)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932(\&to_cp932_supplements, $utf16_b)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932(\&to_cp932_supplements, $utf16_l)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932(\&to_cp932_supplements, $utf16_n)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932(\&to_cp932_supplements, $utf32_b)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932(\&to_cp932_supplements, $utf32_l)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932(\&to_cp932_supplements, $utf32_n)
	? "ok" : "not ok" , " ", ++$loaded, "\n";
}

##### 145..168

$uniStr = $hasUnicode ? "ABC".pack('U*', 0xA3, 0x3042) : "";

print !$hasUnicode || "ABC\x82\xA0" eq unicode_to_cp932($uniStr)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode || "ABC\x81\x92\x82\xA0" eq
	unicode_to_cp932(\&to_cp932_supplements, $uniStr)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x82\xA0" eq utf8_to_cp932("ABC\xC2\xA3\xE3\x81\x82")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x81\x92\x82\xA0" eq
	utf8_to_cp932(\&to_cp932_supplements, "ABC\xC2\xA3\xE3\x81\x82")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x82\xA0" eq utf16le_to_cp932("A\0B\0C\0\xA3\0\x42\x30")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x81\x92\x82\xA0" eq
	utf16le_to_cp932(\&to_cp932_supplements, "A\0B\0C\0\xA3\0\x42\x30")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x81\x92\x82\xA0" eq
	utf16le_to_cp932(\&to_cp932_supplements, "A\0B\0C\0\xA3\0\x42\x30\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x82\xA0" eq utf16be_to_cp932("\0A\0B\0C\0\xA3\x30\x42")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x81\x92\x82\xA0" eq
	utf16be_to_cp932(\&to_cp932_supplements, "\0A\0B\0C\0\xA3\x30\x42")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x81\x92\x82\xA0" eq
	utf16be_to_cp932(\&to_cp932_supplements, "\0A\0B\0C\0\xA3\x30\x42\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x82\xA0" eq
	utf32le_to_cp932("A\0\0\0B\0\0\0C\0\0\0\xA3\0\0\0\x42\x30\0\0")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x81\x92\x82\xA0" eq utf32le_to_cp932(\&to_cp932_supplements,
	"A\0\0\0B\0\0\0C\0\0\0\xA3\0\0\0\x42\x30\0\0")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x81\x92\x82\xA0" eq utf32le_to_cp932(\&to_cp932_supplements,
	"A\0\0\0B\0\0\0C\0\0\0\xA3\0\0\0\x42\x30\0\0\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x81\x92\x82\xA0" eq utf32le_to_cp932(\&to_cp932_supplements,
	"A\0\0\0B\0\0\0C\0\0\0\xA3\0\0\0\x42\x30\0\0\x00\x01")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x82\xA0" eq
	utf32be_to_cp932("\0\0\0A\0\0\0B\0\0\0C\0\0\0\xA3\0\0\x30\x42")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x81\x92\x82\xA0" eq utf32be_to_cp932(\&to_cp932_supplements,
	"\0\0\0A\0\0\0B\0\0\0C\0\0\0\xA3\0\0\x30\x42")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x81\x92\x82\xA0" eq utf32be_to_cp932(\&to_cp932_supplements,
	"\0\0\0A\0\0\0B\0\0\0C\0\0\0\xA3\0\0\x30\x42\x00")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x81\x92\x82\xA0" eq utf32be_to_cp932(\&to_cp932_supplements,
	"\0\0\0A\0\0\0B\0\0\0C\0\0\0\xA3\0\0\x30\x42\x00\x01")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x81\x92\x82\xA0" eq utf16_to_cp932(\&to_cp932_supplements,
	"\0A\0B\0C\0\xA3\x30\x42")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x81\x92\x82\xA0" eq utf16_to_cp932(\&to_cp932_supplements,
	"\xFF\xFEA\0B\0C\0\xA3\0\x42\x30")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x81\x92\x82\xA0" eq utf16_to_cp932(\&to_cp932_supplements,
	"\xFE\xFF\0A\0B\0C\0\xA3\x30\x42")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x81\x92\x82\xA0" eq utf32_to_cp932(\&to_cp932_supplements,
	"\0\0\0A\0\0\0B\0\0\0C\0\0\0\xA3\0\0\x30\x42")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x81\x92\x82\xA0" eq utf32_to_cp932(\&to_cp932_supplements,
	"\xFF\xFE\0\0A\0\0\0B\0\0\0C\0\0\0\xA3\0\0\0\x42\x30\0\0")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print "ABC\x81\x92\x82\xA0" eq utf32_to_cp932(\&to_cp932_supplements,
	"\0\0\xFE\xFF\0\0\0A\0\0\0B\0\0\0C\0\0\0\xA3\0\0\x30\x42")
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

#####

1;
__END__

