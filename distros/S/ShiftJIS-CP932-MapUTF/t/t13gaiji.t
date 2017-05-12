
BEGIN { $| = 1; printf "1..205\n"; }
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
  [ "\xF0\x40", "\xEE\x80\x80", "E000" ], #  2.. 19
  [ "\xF0\x41", "\xEE\x80\x81", "E001" ], # 20.. 37
  [ "\xF0\x7E", "\xEE\x80\xBE", "E03E" ], # 38.. 55
  [ "\xF0\x80", "\xEE\x80\xBF", "E03F" ], # 56.. 73
  [ "\xF0\x81", "\xEE\x81\x80", "E040" ], # 74.. 91
  [ "\xF0\xFC", "\xEE\x82\xBB", "E0BB" ], # 92..109
  [ "\xF1\x40", "\xEE\x82\xBC", "E0BC" ], #110..127
  [ "\xF5\x95", "\xEE\x90\x80", "E400" ], #128..145
  [ "\xF9\x40", "\xEE\x9A\x9C", "E69C" ], #146..163
  [ "\xF9\xFC", "\xEE\x9D\x97", "E757" ], #164..181
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

    print !$hasUnicode || $unicode eq cp932_to_unicode($cp932, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf8    eq cp932_to_utf8($cp932, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf16le eq cp932_to_utf16le($cp932, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf16be eq cp932_to_utf16be($cp932, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf32le eq cp932_to_utf32le($cp932, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $utf32be eq cp932_to_utf32be($cp932, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print !$hasUnicode || $cp932re eq unicode_to_cp932($unicode, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf8_to_cp932($utf8, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16le_to_cp932($utf16le, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16be_to_cp932($utf16be, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32le_to_cp932($utf32le, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32be_to_cp932($utf32be, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932($utf16_b, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932($utf16_l, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932($utf16_n, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932($utf32_b, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932($utf32_l, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932($utf32_n, 'g')
	? "ok" : "not ok" , " ", ++$loaded, "\n";
}

##### 182..187

$string = "\xF0\x40\xF0\x41\xF0\x7E\xF1\x80\xF5\x95\xF9\xFC";

print cp932_to_utf16be($string, 't') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16le($string, 't') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32be($string, 't') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32le($string, 't') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf8   ($string, 't') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode || cp932_to_unicode($string, 't') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

##### 188..205

$string = "\xF0\x7F\xF0\xFD\xF5\x39\xF9\xFD";
$return = "&#xF07F;&#xF0FD;&#xF539;&#xF9FD;";

print cp932_to_utf16be($string, 'g') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16le($string, 'g') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32be($string, 'g') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32le($string, 'g') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf8   ($string, 'g') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode || cp932_to_unicode($string, 'g') eq ""
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16be(\&h_fb, $string, 'g') eq $return
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16le(\&h_fb, $string, 'g') eq $return
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32be(\&h_fb, $string, 'g') eq $return
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32le(\&h_fb, $string, 'g') eq $return
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf8   (\&h_fb, $string, 'g') eq $return
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode || cp932_to_unicode(\&h_fb, $string, 'g') eq $return
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16be($string, 'gt') eq "\x00\x7F\x00\x39"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16le($string, 'gt') eq "\x7F\x00\x39\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32be($string, 'gt') eq "\0\0\x00\x7F\0\0\x00\x39"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32le($string, 'gt') eq "\x7F\x00\0\0\x39\x00\0\0"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf8   ($string, 'gt') eq "\x7F\x39"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode || cp932_to_unicode($string, 'gt') eq "\x7F\x39"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

#####

1;
__END__

