
BEGIN { $| = 1; print "1..259\n"; }
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
    [ "\x81\x00", "&#x8100;" ], #  2.. 13
    [ "\x82\x01", "&#x8201;" ], # 14.. 25
    [ "\x83\x02", "&#x8302;" ], # 26.. 37
    [ "\x84\x7F", "&#x847F;" ], # 38.. 49
    [ "\x85\xFD", "&#x85FD;" ], # 50.. 61
    [ "\x86\xFE", "&#x86FE;" ], # 62.. 73
    [ "\x87\xFF", "&#x87FF;" ], # 74.. 85
    [ "\x80", "&#x80;" ],	# 86.. 97
    [ "\x81", "[81]" ], 	# 98..109
    [ "\x82", "[82]" ], 	#110..121
    [ "\x82\xF2", "&#x82F2;" ], #122..133
    [ "\x83", "[83]" ], 	#134..145
    [ "\x9F", "[9F]" ], 	#146..157
    [ "\x9F\x39", "&#x9F39;" ], #158..169
    [ "\xA0", "&#xA0;" ],	#170..181
    [ "\xE0", "[E0]" ], 	#182..193
    [ "\xFC", "[FC]" ], 	#194..205
    [ "\xFD", "&#xFD;" ],	#206..217
    [ "\xFE", "&#xFE;" ],	#218..229
    [ "\xFF", "&#xFF;" ]	#230..241
);

foreach $ary (@arys) {
    $string = $ary->[0];
    $return = $ary->[1];

    print cp932_to_utf16be($string, '') eq ""
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print cp932_to_utf16le($string, '') eq ""
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print cp932_to_utf32be($string, '') eq ""
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print cp932_to_utf32le($string, '') eq ""
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print cp932_to_utf8   ($string, '') eq ""
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print !$hasUnicode || cp932_to_unicode($string, '') eq ""
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print cp932_to_utf16be(\&h_fb, $string, '') eq $return
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print cp932_to_utf16le(\&h_fb, $string, '') eq $return
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print cp932_to_utf32be(\&h_fb, $string, '') eq $return
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print cp932_to_utf32le(\&h_fb, $string, '') eq $return
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print cp932_to_utf8   (\&h_fb, $string, '') eq $return
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print !$hasUnicode || cp932_to_unicode(\&h_fb, $string, '') eq $return
	? "ok" : "not ok" , " ", ++$loaded, "\n";
}

##### 242..247

$string = "\x81\x00";

print cp932_to_utf16be(\&h_fb, $string, 't') eq "[81]\x00\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16le(\&h_fb, $string, 't') eq "[81]\x00\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32be(\&h_fb, $string, 't') eq "[81]\x00\x00\x00\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32le(\&h_fb, $string, 't') eq "[81]\x00\x00\x00\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf8   (\&h_fb, $string, 't') eq "[81]\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode || cp932_to_unicode(\&h_fb, $string, 't') eq "[81]\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

##### 248..253

$string = "\x82\x39";

print cp932_to_utf16be(\&h_fb, $string, 't') eq "[82]\x00\x39"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16le(\&h_fb, $string, 't') eq "[82]\x39\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32be(\&h_fb, $string, 't') eq "[82]\x00\x00\x00\x39"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32le(\&h_fb, $string, 't') eq "[82]\x39\x00\x00\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf8   (\&h_fb, $string, 't') eq "[82]\x39"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode || cp932_to_unicode(\&h_fb, $string, 't') eq "[82]\x39"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

##### 254..259

$string = "\x82\xF2";

print cp932_to_utf16be(\&h_fb, $string, 't') eq "&#x82F2;"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf16le(\&h_fb, $string, 't') eq "&#x82F2;"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32be(\&h_fb, $string, 't') eq "&#x82F2;"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf32le(\&h_fb, $string, 't') eq "&#x82F2;"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print cp932_to_utf8   (\&h_fb, $string, 't') eq "&#x82F2;"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print !$hasUnicode || cp932_to_unicode(\&h_fb, $string, 't') eq "&#x82F2;"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

#####

1;
__END__
