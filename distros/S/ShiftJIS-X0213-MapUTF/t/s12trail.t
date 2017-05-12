
BEGIN { $| = 1; print "1..229\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::X0213::MapUTF qw(:all);

use strict;
$^W = 1;
our $loaded = 1;
print "ok 1\n";

sub h_fb {
    my ($char, $byte) = @_;
    defined $char
	? sprintf("&#x%s;", uc unpack 'H*', $char)
	: sprintf("[%02X]", $byte);
}

#####

our @arys = (
    [ "\x82\xFC", "&#x82FC;" ], #  2.. 13
    [ "\x84\xDD", "&#x84DD;" ], # 14.. 25
    [ "\x86\xF2", "&#x86F2;" ], # 26.. 37
    [ "\x87\x77", "&#x8777;" ], # 38.. 49
    [ "\x80", "[80]" ], 	# 50.. 61
    [ "\x81", "[81]" ], 	# 62.. 73
    [ "\x82", "[82]" ], 	# 74.. 85
    [ "\xFC\xF5", "&#xFCF5;" ], # 86.. 97
    [ "\x83", "[83]" ], 	# 98..109
    [ "\xFC\xFC", "&#xFCFC;" ], #110..121
    [ "\x9F", "[9F]" ], 	#122..133
    [ "\xA0", "[A0]" ], 	#134..145
    [ "\xE0", "[E0]" ], 	#146..157
    [ "\xFC", "[FC]" ], 	#158..169
    [ "\xFD", "[FD]" ], 	#170..181
    [ "\xFE", "[FE]" ], 	#182..193
    [ "\xFF", "[FF]" ]		#194..205
);

foreach my $ary (@arys) {
    our $str = $ary->[0];
    our $ret = $ary->[1];

    print sjis2004_to_utf16be($str) eq ""
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print sjis2004_to_utf16le($str) eq ""
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print sjis2004_to_utf32be($str) eq ""
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print sjis2004_to_utf32le($str) eq ""
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print sjis2004_to_utf8   ($str) eq ""
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print sjis2004_to_unicode($str) eq ""
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print sjis2004_to_utf16be(\&h_fb, $str) eq $ret
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print sjis2004_to_utf16le(\&h_fb, $str) eq $ret
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print sjis2004_to_utf32be(\&h_fb, $str) eq $ret
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print sjis2004_to_utf32le(\&h_fb, $str) eq $ret
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print sjis2004_to_utf8   (\&h_fb, $str) eq $ret
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print sjis2004_to_unicode(\&h_fb, $str) eq $ret
	? "ok" : "not ok" , " ", ++$loaded, "\n";
}

##### 206..211

our $string = "\x81\x00";

print sjis2004_to_utf16be(\&h_fb, $string) eq "[81]\x00\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_utf16le(\&h_fb, $string) eq "[81]\x00\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_utf32be(\&h_fb, $string) eq "[81]\x00\x00\x00\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_utf32le(\&h_fb, $string) eq "[81]\x00\x00\x00\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_utf8   (\&h_fb, $string) eq "[81]\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_unicode(\&h_fb, $string) eq "[81]\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

##### 212..217

$string = "\x82\x39";

print sjis2004_to_utf16be(\&h_fb, $string) eq "[82]\x00\x39"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_utf16le(\&h_fb, $string) eq "[82]\x39\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_utf32be(\&h_fb, $string) eq "[82]\x00\x00\x00\x39"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_utf32le(\&h_fb, $string) eq "[82]\x39\x00\x00\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_utf8   (\&h_fb, $string) eq "[82]\x39"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_unicode(\&h_fb, $string) eq "[82]\x39"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

##### 218..223

$string = "\xF0\x7F";

print sjis2004_to_utf16be(\&h_fb, $string) eq "[F0]\x00\x7F"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_utf16le(\&h_fb, $string) eq "[F0]\x7F\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_utf32be(\&h_fb, $string) eq "[F0]\x00\x00\x00\x7F"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_utf32le(\&h_fb, $string) eq "[F0]\x7F\x00\x00\x00"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_utf8   (\&h_fb, $string) eq "[F0]\x7F"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_unicode(\&h_fb, $string) eq "[F0]\x7F"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

##### 224..229

$string = "\xFC\xFF";

print sjis2004_to_utf16be(\&h_fb, $string) eq "[FC][FF]"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_utf16le(\&h_fb, $string) eq "[FC][FF]"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_utf32be(\&h_fb, $string) eq "[FC][FF]"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_utf32le(\&h_fb, $string) eq "[FC][FF]"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_utf8   (\&h_fb, $string) eq "[FC][FF]"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

print sjis2004_to_unicode(\&h_fb, $string) eq "[FC][FF]"
    ? "ok" : "not ok" , " ", ++$loaded, "\n";

1;
__END__
