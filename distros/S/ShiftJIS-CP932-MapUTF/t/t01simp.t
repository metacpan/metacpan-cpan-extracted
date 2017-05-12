
BEGIN { $| = 1; printf "1..361\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::CP932::MapUTF qw(:all);
$loaded = 1;
print "ok 1\n";

$hasUnicode = defined &cp932_to_unicode;

@arys = (
  [ "",   "",   "" ],						#  2.. 19
  [ "\n\n\0\n", "\n\n\0\n", "n:n:0:n" ],			# 20.. 37
  [ "ABC\0\0\0", "\x41\x42\x43\0\0\0", "41:42:43:0:0:0" ],	# 38.. 55
  [ "\x82\xa0\x82\xa2\x82\xa4\x81\xe0\x82\xa6\x82\xa8",
    "\xE3\x81\x82\xE3\x81\x84\xE3\x81\x86\xE2\x89\x92\xE3\x81\x88\xE3\x81\x8A",
    "3042:3044:3046:2252:3048:304a" ],				# 56.. 73
  [ "\x8a\xbf\x8e\x9a\n\x00\x41\xdf\x81\x40\x88\x9F",
    "\xE6\xBC\xA2\xE5\xAD\x97\n\0\x41\xEF\xBE\x9F\xE3\x80\x80\xE4\xBA\x9C",
    "6f22:5b57:n:0:41:FF9F:3000:4E9C" ],			# 74.. 91
  [ "\x87\x90", "\xE2\x89\x92", "2252", "\x81\xE0" ],		# 92..109
  [ "\x87\x91", "\xE2\x89\xA1", "2261", "\x81\xDF" ],		#110..127
  [ "\x87\x92", "\xE2\x88\xAB", "222B", "\x81\xE7" ],		#128..145
  [ "\x87\x95", "\xE2\x88\x9A", "221A", "\x81\xE3" ],		#146..163
  [ "\x87\x96", "\xE2\x8A\xA5", "22A5", "\x81\xDB" ],		#164..181
  [ "\x87\x97", "\xE2\x88\xA0", "2220", "\x81\xDA" ],		#182..199
  [ "\x87\x9A", "\xE2\x88\xB5", "2235", "\x81\xE6" ],		#200..217
  [ "\x87\x9B", "\xE2\x88\xA9", "2229", "\x81\xBF" ],		#218..235
  [ "\x87\x9C", "\xE2\x88\xAA", "222A", "\x81\xBE" ],		#236..253
  [ "\xED\x56", "\xE4\xBE\x94", "4F94", "\xFA\x72" ],		#254..271
  [ "\xEE\xF9", "\xEF\xBF\xA2", "FFE2", "\x81\xCA" ],		#272..289
  [ "\xee\xfa", "\xEF\xBF\xA4", "ffe4", "\xfa\x55" ],		#290..307
  [ "\xFA\x4A", "\xE2\x85\xA0", "2160", "\x87\x54" ],		#308..325
  [ "\xFA\x54", "\xEF\xBF\xA2", "FFE2", "\x81\xCA" ],		#326..343
  [ "\xFA\x5B", "\xE2\x88\xB5", "2235", "\x81\xE6" ],		#344..361
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

    print !$hasUnicode || $unicode eq cp932_to_unicode($cp932)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf8    eq cp932_to_utf8($cp932)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf16le eq cp932_to_utf16le($cp932)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf16be eq cp932_to_utf16be($cp932)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf32le eq cp932_to_utf32le($cp932)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf32be eq cp932_to_utf32be($cp932)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print !$hasUnicode || $cp932re eq unicode_to_cp932($unicode)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf8_to_cp932($utf8)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16le_to_cp932($utf16le)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16be_to_cp932($utf16be)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32le_to_cp932($utf32le)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32be_to_cp932($utf32be)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932($utf16_b)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932($utf16_l)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932($utf16_n)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932($utf32_b)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932($utf32_l)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932($utf32_n)
	? "ok" : "not ok" , " ", ++$loaded, "\n";
}

1;
__END__

