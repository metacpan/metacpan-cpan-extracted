
BEGIN { $| = 1; printf "1..243\n"; }
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
  [ "\x21",     "\xC2\xA1",     "A1"  ], #  2.. 23
  [ "\x5C",     "\xC2\xA5",     "A5"  ], # 24.. 45
  [ "\x7C",     "\xC2\xA6",     "A6"  ], # 46.. 67
  [ "\x61",     "\xC2\xAA",     "AA"  ], # 68.. 89
  [ "\x32",     "\xC2\xB2",     "B2"  ], # 90..111
  [ "\x83\xCA", "\xC2\xB5",     "B5"  ], #112..133
  [ "\x81\x45", "\xC2\xB7",     "B7"  ], #134..155
  [ "\x3F",     "\xC2\xBF",     "BF"  ], #156..177
  [ "\x41",     "\xC3\x85",     "C5"  ], #178..199
  [ "\x79",     "\xC3\xBF",     "FF"  ], #200..221
  [ "\x83\x94", "\xE3\x82\x94", "3094"], #222..243
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

    print $cp932re eq utf8_to_cp932($utf8, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16le_to_cp932($utf16le, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16be_to_cp932($utf16be, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32le_to_cp932($utf32le, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32be_to_cp932($utf32be, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932($utf16_b, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932($utf16_l, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932($utf16_n, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932($utf32_b, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932($utf32_l, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932($utf32_n, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf8_to_cp932(sub {""}, $utf8, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16le_to_cp932(sub {""}, $utf16le, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16be_to_cp932(sub {""}, $utf16be, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32le_to_cp932(sub {""}, $utf32le, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32be_to_cp932(sub {""}, $utf32be, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932(sub {""}, $utf16_b, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932(sub {""}, $utf16_l, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf16_to_cp932(sub {""}, $utf16_n, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932(sub {""}, $utf32_b, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932(sub {""}, $utf32_l, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";

    print $cp932re eq utf32_to_cp932(sub {""}, $utf32_n, 'f')
	? "ok" : "not ok" , " ", ++$loaded, "\n";
}

#####

1;
__END__

