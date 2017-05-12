
BEGIN { $| = 1; printf "1..127\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::CP932::MapUTF qw(:all);
$loaded = 1;
print "ok 1\n";

$hasUnicode = defined &cp932_to_unicode;

sub h_fb {
    my ($char, $byte) = @_;
    defined $char
	? sprintf("&#x%s;", uc unpack 'H*', $char)
	: sprintf("[%02X]", $byte);
}

#####

@arys = (
  [ "\x80", "\xC2\x80",     "80" ],   #  2.. 19
  [ "\xA0", "\xEF\xA3\xB0", "F8F0" ], # 20.. 37
  [ "\xFD", "\xEF\xA3\xB1", "F8F1" ], # 38.. 55
  [ "\xFE", "\xEF\xA3\xB2", "F8F2" ], # 56.. 73
  [ "\xFF", "\xEF\xA3\xB3", "F8F3" ], # 74.. 91
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

    print !$hasUnicode || $unicode eq cp932_to_unicode($cp932, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf8    eq cp932_to_utf8($cp932, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf16le eq cp932_to_utf16le($cp932, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf16be eq cp932_to_utf16be($cp932, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf32le eq cp932_to_utf32le($cp932, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf32be eq cp932_to_utf32be($cp932, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print !$hasUnicode || $cp932re eq unicode_to_cp932($unicode, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf8_to_cp932($utf8, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16le_to_cp932($utf16le, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16be_to_cp932($utf16be, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32le_to_cp932($utf32le, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32be_to_cp932($utf32be, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932($utf16_b, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932($utf16_l, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932($utf16_n, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932($utf32_b, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932($utf32_l, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932($utf32_n, 's')
	? "ok" : "not ok" , " ", ++$loaded, "\n";
}

##### 92..109

$string = "\xF0\x7F\xF5\x39\xF9\xFD";
$return = "&#xF07F;&#xF539;&#xF9FD;";

print cp932_to_utf16be($string, 'sg') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16le($string, 'sg') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32be($string, 'sg') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32le($string, 'sg') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf8   ($string, 'sg') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode || cp932_to_unicode($string, 'sg') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16be(\&h_fb, $string, 'sg') eq $return
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16le(\&h_fb, $string, 'sg') eq $return
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32be(\&h_fb, $string, 'sg') eq $return
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32le(\&h_fb, $string, 'sg') eq $return
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf8   (\&h_fb, $string, 'sg') eq $return
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode ||
	cp932_to_unicode(\&h_fb, $string, 'sg') eq $return
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16be($string, 'st') eq "\x00\x7F\x00\x39\xF8\xF1"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16le($string, 'st') eq "\x7F\x00\x39\x00\xF1\xF8"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32be($string, 'st') eq "\0\0\0\x7F\0\0\0\x39\0\0\xF8\xF1"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32le($string, 'st') eq "\x7F\0\0\0\x39\0\0\0\xF1\xF8\0\0"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf8   ($string, 'st') eq "\x7F\x39\xEF\xA3\xB1"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode ||
	cp932_to_unicode($string, 'st') eq "\x7F\x39".chr(0xF8F1)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

##### 110..115

$string = "\xF9\xFD\xA0";

print cp932_to_utf16be(\&h_fb, $string, 'st') eq "[F9]\xF8\xF1\xF8\xF0"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16le(\&h_fb, $string, 'st') eq "[F9]\xF1\xF8\xF0\xF8"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32be(\&h_fb, $string, 'st') eq "[F9]\0\0\xF8\xF1\0\0\xF8\xF0"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32le(\&h_fb, $string, 'st') eq "[F9]\xF1\xF8\0\0\xF0\xF8\0\0"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf8   (\&h_fb, $string, 'st') eq "[F9]\xEF\xA3\xB1\xEF\xA3\xB0"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode || cp932_to_unicode(\&h_fb, $string, 'st')
	eq "[F9]".chr(0xF8F1).chr(0xF8F0)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

##### 116..127

$string = "\xF9\xA0\xFF";

print cp932_to_utf16be(\&h_fb, $string, 'st') eq "&#xF9A0;\xF8\xF3"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16le(\&h_fb, $string, 'st') eq "&#xF9A0;\xF3\xF8"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32be(\&h_fb, $string, 'st') eq "&#xF9A0;\0\0\xF8\xF3"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32le(\&h_fb, $string, 'st') eq "&#xF9A0;\xF3\xF8\0\0"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf8   (\&h_fb, $string, 'st') eq "&#xF9A0;\xEF\xA3\xB3"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode || cp932_to_unicode(\&h_fb, $string, 'st')
	eq "&#xF9A0;".chr(0xF8F3)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16be(\&h_fb, $string, 'gst') eq "\xE6\xFB\xF8\xF3"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16le(\&h_fb, $string, 'gst') eq "\xFB\xE6\xF3\xF8"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32be(\&h_fb, $string, 'gst') eq "\0\0\xE6\xFB\0\0\xF8\xF3"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32le(\&h_fb, $string, 'gst') eq "\xFB\xE6\0\0\xF3\xF8\0\0"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf8   (\&h_fb, $string, 'gst') eq "\xEE\x9B\xBB\xEF\xA3\xB3"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode || cp932_to_unicode(\&h_fb, $string, 'gst')
	eq chr(0xE6FB).chr(0xF8F3)
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

#####

1;
__END__

