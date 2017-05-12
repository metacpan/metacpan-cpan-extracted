
BEGIN { $| = 1; print "1..181\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::X0213::MapUTF qw(:all);

use strict;
$^W = 1;
our $loaded = 1;
print "ok 1\n";

#####

our @arys = (
  [ "",   "",   "" ],						#  2.. 19
  [ "\n\n\0\n", "\n\n\0\n", "n:n:0:n" ],			# 20.. 37
  [ "ABC\0\0\0", "\x41\x42\x43\0\0\0", "41:42:43:0:0:0" ],	# 38.. 55
  [ "ABC\n\n", "\x41\x42\x43\n\n", "41:42:43:n:n" ],		# 56.. 73
  [
    "\x82\xa0\x82\xa2\x82\xa4\x81\xe0\x82\xa6\x82\xa8",		# 74.. 91
    "\xE3\x81\x82\xE3\x81\x84\xE3\x81\x86\xE2\x89\x92\xE3\x81\x88\xE3\x81\x8A",
    "3042:3044:3046:2252:3048:304a",
  ],
  [
    "\x8a\xbf\x8e\x9a\n\x00\x41\xdf\x81\x40\x88\x9F",		# 92..109
    "\xE6\xBC\xA2\xE5\xAD\x97\n\0\x41\xEF\xBE\x9F\xE3\x80\x80\xE4\xBA\x9C",
    "6f22:5b57:n:0:41:FF9F:3000:4E9C",
  ],
  [
    "abc\x82\xf2pqr\x82\xf2xyz",				#110..127
    "abc\xE3\x82\x94pqr\xE3\x82\x94xyz",
    "61:62:63:3094:70:71:72:3094:78:79:7a",
  ],
  [
    "\xFB\x55\x84\x47\xFB\x5C",					#128..145
    "\xf0\xa8\xaa\x99\xd0\x96\xf0\xa8\xab\xa4",
    "28A99:416:28AE4",
  ],
  [
    "\x82\xF5\x82\xA9",						#146..163
    "\xe3\x81\x8b\xe3\x82\x9a\xe3\x81\x8b",
    "304B:309A:304B",
  ],
  [
    "\x41\x86\x85\x41\x86\x86\x41\x86\x84",			#164..181
    "\x41\xcb\xa9\xcb\xa5\x41\xcb\xa5\xcb\xa9\x41\xcb\xa9",
    "41:02E9:02E5:41:02E5:02E9:41:02E9",
  ],
);

sub uv_to_utf16 {
    my $u = shift;
    return $u if $u <= 0xFFFF;
    return    if $u > 0x10FFFF;
    $u -= 0x10000;
    my $hi = ($u >> 10) + 0xD800;
    my $lo = ($u & 0x3FF) + 0xDC00;
    return $hi, $lo;
}

for my $ary (@arys) {
    my $sjis    = $ary->[0];
    my $sjisre  = defined $ary->[3] ? $ary->[3] : $ary->[0];
    my $utf8    = $ary->[1];
    my @char    = map { $_ eq 'n' ? ord("\n") : hex $_ } split /:/, $ary->[2];
    my $unicode = pack 'U*', @char;
    my $utf16le = pack 'v*', map uv_to_utf16($_), @char;
    my $utf16be = pack 'n*', map uv_to_utf16($_), @char;
    my $utf32le = pack 'V*', @char;
    my $utf32be = pack 'N*', @char;
    my $utf16_l = pack 'v*', 0xFEFF, map uv_to_utf16($_), @char;
    my $utf16_b = pack 'n*', 0xFEFF, map uv_to_utf16($_), @char;
    my $utf16_n = pack 'n*', map uv_to_utf16($_), @char;
    my $utf32_l = pack 'V*', 0xFEFF, @char;
    my $utf32_b = pack 'N*', 0xFEFF, @char;
    my $utf32_n = pack 'N*', @char;

    print $unicode eq sjis2004_to_unicode(sub {""}, $sjis)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf8    eq sjis2004_to_utf8(sub {""}, $sjis)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf16le eq sjis2004_to_utf16le(sub {""}, $sjis)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf16be eq sjis2004_to_utf16be(sub {""}, $sjis)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf32le eq sjis2004_to_utf32le(sub {""}, $sjis)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf32be eq sjis2004_to_utf32be(sub {""}, $sjis)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $sjisre eq unicode_to_sjis2004(sub {""}, $unicode)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $sjisre eq utf8_to_sjis2004(sub {""}, $utf8)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $sjisre eq utf16le_to_sjis2004(sub {""}, $utf16le)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $sjisre eq utf16be_to_sjis2004(sub {""}, $utf16be)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $sjisre eq utf32le_to_sjis2004(sub {""}, $utf32le)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $sjisre eq utf32be_to_sjis2004(sub {""}, $utf32be)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $sjisre eq utf16_to_sjis2004(sub {""}, $utf16_b)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $sjisre eq utf16_to_sjis2004(sub {""}, $utf16_l)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $sjisre eq utf16_to_sjis2004(sub {""}, $utf16_n)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $sjisre eq utf32_to_sjis2004(sub {""}, $utf32_b)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $sjisre eq utf32_to_sjis2004(sub {""}, $utf32_l)
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $sjisre eq utf32_to_sjis2004(sub {""}, $utf32_n)
	? "ok" : "not ok" , " ", ++$loaded, "\n";
}

