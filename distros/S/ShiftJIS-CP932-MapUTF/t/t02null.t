
BEGIN { $| = 1; printf "1..%d\n", 1 + 20 * 18; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::CP932::MapUTF qw(:all);
$loaded = 1;
print "ok 1\n";

$hasUnicode = defined &cp932_to_unicode;

@arys = (
  [ "",   "",   "" ],
  [ "\n\n\0\n", "\n\n\0\n", "n:n:0:n" ],
  [ "ABC\0\0\0", "\x41\x42\x43\0\0\0", "41:42:43:0:0:0" ],
  [
    "\x82\xa0\x82\xa2\x82\xa4\x81\xe0\x82\xa6\x82\xa8",
    "\xE3\x81\x82\xE3\x81\x84\xE3\x81\x86\xE2\x89\x92\xE3\x81\x88\xE3\x81\x8A",
    "3042:3044:3046:2252:3048:304a",
  ],
  [
    "\x8a\xbf\x8e\x9a\n\x00\x41\xdf",
    "\xE6\xBC\xA2\xE5\xAD\x97\n\0\x41\xEF\xBE\x9F",
    "6f22:5b57:n:0:41:FF9F",
  ],
  [ "\x87\x90", "\xE2\x89\x92", "2252", "\x81\xE0" ],
  [ "\x87\x91", "\xE2\x89\xA1", "2261", "\x81\xDF" ],
  [ "\x87\x92", "\xE2\x88\xAB", "222B", "\x81\xE7" ],
  [ "\x87\x95", "\xE2\x88\x9A", "221A", "\x81\xE3" ],
  [ "\x87\x96", "\xE2\x8A\xA5", "22A5", "\x81\xDB" ],
  [ "\x87\x97", "\xE2\x88\xA0", "2220", "\x81\xDA" ],
  [ "\x87\x9A", "\xE2\x88\xB5", "2235", "\x81\xE6" ],
  [ "\x87\x9B", "\xE2\x88\xA9", "2229", "\x81\xBF" ],
  [ "\x87\x9C", "\xE2\x88\xAA", "222A", "\x81\xBE" ],
  [ "\xED\x56", "\xE4\xBE\x94", "4F94", "\xFA\x72" ],
  [ "\xEE\xF9", "\xEF\xBF\xA2", "FFE2", "\x81\xCA" ],
  [ "\xee\xfa", "\xEF\xBF\xA4", "ffe4", "\xfa\x55" ],
  [ "\xFA\x4A", "\xE2\x85\xA0", "2160", "\x87\x54" ],
  [ "\xFA\x54", "\xEF\xBF\xA2", "FFE2", "\x81\xCA" ],
  [ "\xFA\x5B", "\xE2\x88\xB5", "2235", "\x81\xE6" ],
);

for $ary (@arys) {
    my $cp932   = $ary->[0];
    my $cp932re = defined $ary->[3] ? $ary->[3] : $ary->[0];
    my $utf8    = $ary->[1];
    my @char    = map { $_ eq 'n' ? ord("\n") : hex $_ } split /:/, $ary->[2];
    my $unicode = !$hasUnicode ? '' : pack 'U*', @char;
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

    print !$hasUnicode || $unicode eq cp932_to_unicode(sub {""}, $cp932)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf8    eq cp932_to_utf8(sub {""}, $cp932)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf16le eq cp932_to_utf16le(sub {""}, $cp932)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf16be eq cp932_to_utf16be(sub {""}, $cp932)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf32le eq cp932_to_utf32le(sub {""}, $cp932)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf32be eq cp932_to_utf32be(sub {""}, $cp932)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print !$hasUnicode || $cp932re eq unicode_to_cp932(sub {""}, $unicode)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf8_to_cp932(sub {""}, $utf8)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16le_to_cp932(sub {""}, $utf16le)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16be_to_cp932(sub {""}, $utf16be)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32le_to_cp932(sub {""}, $utf32le)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32be_to_cp932(sub {""}, $utf32be)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932(sub {""}, $utf16_b)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932(sub {""}, $utf16_l)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932(sub {""}, $utf16_n)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932(sub {""}, $utf32_b)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932(sub {""}, $utf32_l)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932(sub {""}, $utf32_n)
	? "ok" : "not ok" , " ", ++$loaded, "\n";}

1;
__END__
