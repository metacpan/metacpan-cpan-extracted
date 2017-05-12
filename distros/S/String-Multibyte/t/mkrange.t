
BEGIN { $| = 1; print "1..33\n"; }
END {print "not ok 1\n" unless $loaded;}

use String::Multibyte;

$bytes = String::Multibyte->new('Bytes',1);
$euc   = String::Multibyte->new('EUC',1);
$eucjp = String::Multibyte->new('EUC_JP',1);
$sjis  = String::Multibyte->new('ShiftJIS',1);
$utf8  = String::Multibyte->new('UTF8',1);
$u16be = String::Multibyte->new('UTF16BE',1);
$u16le = String::Multibyte->new('UTF16LE',1);
$u32be = String::Multibyte->new('UTF32BE',1);
$u32le = String::Multibyte->new('UTF32LE',1);

$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

sub asc2str ($$) {
   my($cs, $str) = @_;
   my $tmp =  {
      UTF16LE => 'v',   UTF32LE => 'V',
      UTF16BE => 'n',   UTF32BE => 'N',
   }->{$cs};
   $tmp and $str =~ s/([\x00-\xFF])/pack $tmp, ord $1/ge;
   return $str;
}
sub str2asc ($$) {
   my($cs, $str) = @_;
   my $re = {
      UTF16LE => '([\0-\xFF])\0',  UTF32LE => '([\0-\xFF])\0\0\0',
      UTF16BE => '\0([\0-\xFF])',  UTF32BE => '\0\0\0([\0-\xFF])',
   }->{$cs};
   $re and $str =~ s/$re/$1/g;
   return $str;
}

#####

for (["A-D", "ABCD"],
     ["-0",  "-0"],
     ["ab-", "ab-"],
     ['-+\-XYZ-', "-+-XYZ-"],
     ['-+\\-XYZ-', "-+-XYZ-"],
     ['-+\\\\-`', "-+\\]^_`"],
     ['\\\-^',  '\\]^' ],
     ['\\\\-]', '\\]' ],
     ['\\\\\-]', '\-]' ],
     ['\a-c', '\abc'],
     ['abZ-\\', 'abZ[\\'],
     ["0-9", "0123456789"],
     ["0-9", "0123456789", 1],
     ["9-0", "9876543210", 1],
     ["0-9-5", "01234567898765", 1],
     ["0-9-5-7", "0123456789876567", 1],
     ["", ""] ) { #17
    $NG = 0;
    $NG++ unless $bytes->mkrange($_->[0], $_->[2]) eq $_->[1];
    $NG++ unless $euc  ->mkrange($_->[0], $_->[2]) eq $_->[1];
    $NG++ unless $eucjp->mkrange($_->[0], $_->[2]) eq $_->[1];
    $NG++ unless $sjis ->mkrange($_->[0], $_->[2]) eq $_->[1];
    $NG++ unless $utf8 ->mkrange($_->[0], $_->[2]) eq $_->[1];
    $NG++ unless asc2str('UTF16BE', $_->[1]) eq
	$u16be->mkrange(asc2str('UTF16BE', $_->[0]), $_->[2]);
    $NG++ unless asc2str('UTF16LE', $_->[1]) eq
	$u16le->mkrange(asc2str('UTF16LE', $_->[0]), $_->[2]);
    $NG++ unless asc2str('UTF32BE', $_->[1]) eq
	$u32be->mkrange(asc2str('UTF32BE', $_->[0]), $_->[2]);
    $NG++ unless asc2str('UTF32LE', $_->[1]) eq
	$u32le->mkrange(asc2str('UTF32LE', $_->[0]), $_->[2]);
    print ! $NG ? "ok" : "not ok", " ", ++$loaded, "\n";
}

#####

print $sjis->mkrange("\xDE-\x81\x42")
	eq "\xDE\xDF\x81\x40\x81\x41\x81\x42"
   && $sjis->mkrange("\x9F\xFC-\xE0\x41")
	eq "\x9F\xFC\xE0\x40\xE0\x41"
   && $sjis->mkrange("\x7D-\xA1\xA3")
	eq "\x7D\x7E\x7F\xA1\xA3"
   && $sjis->mkrange("\x81\x7D-\x81\x81")
	eq "\x81\x7D\x81\x7E\x81\x80\x81\x81"
   && $sjis->mkrange("\x86\xF9-\x87\x42")
	eq "\x86\xF9\x86\xFA\x86\xFB\x86\xFC\x87\x40\x87\x41\x87\x42"
    ? "ok" : "not ok", " ", ++$loaded, "\n";

print $euc->mkrange("\x7E-\xA1\xA2")
	eq "\x7E\x7F\xA1\xA1\xA1\xA2"
   && $euc->mkrange("\xA1\xFC-\xA2\xA2")
	eq "\xA1\xFC\xA1\xFD\xA1\xFE\xA2\xA1\xA2\xA2"
    ? "ok" : "not ok", " ", ++$loaded, "\n";

print $eucjp->mkrange("\x7E-\x8E\xA2")
	eq "\x7E\x7F\x8E\xA1\x8E\xA2"
   && $eucjp->mkrange("\x8E\xDF-\xA1\xA2")
	eq join('', map "\x8E".chr, 0xDF..0xFE)."\xA1\xA1\xA1\xA2"
   && $eucjp->mkrange("\x8E\xFD-\xA1\xA2")
	eq "\x8E\xFD\x8E\xFE\xA1\xA1\xA1\xA2"
   && $eucjp->mkrange("\xA1\xFC-\xA2\xA2")
	eq "\xA1\xFC\xA1\xFD\xA1\xFE\xA2\xA1\xA2\xA2"
   && $eucjp->mkrange("\xFD\xFD-\xFE\xA2")
	eq "\xFD\xFD\xFD\xFE\xFE\xA1\xFE\xA2"
   && $eucjp->mkrange("\xFE\xFE-\x8F\xA1\xA2")
	eq "\xFE\xFE\x8F\xA1\xA1\x8F\xA1\xA2"
   && $eucjp->mkrange("\x8F\xA3\xB1-\x8F\xA3\xB2")
	eq "\x8F\xA3\xB1\x8F\xA3\xB2"
   && $eucjp->mkrange("\x8F\xA1\xFC-\x8F\xA2\xA2")
	eq "\x8F\xA1\xFC\x8F\xA1\xFD\x8F\xA1\xFE\x8F\xA2\xA1\x8F\xA2\xA2"
    ? "ok" : "not ok", " ", ++$loaded, "\n";

#####

# U+D7FE..U+E002
print $utf8->mkrange("\xed\x9f\xbe-\xee\x80\x82") eq
	"\xed\x9f\xbe\xed\x9f\xbf\xee\x80\x80\xee\x80\x81\xee\x80\x82"
   && $u16be->mkrange("\xD7\xFE\0-\xE0\x02")
	eq "\xD7\xFE\xD7\xFF\xE0\x00\xE0\x01\xE0\x02"
   && $u16le->mkrange("\xFE\xD7-\0\x02\xE0")
	eq "\xFE\xD7\xFF\xD7\x00\xE0\x01\xE0\x02\xE0"
   && $u32be->mkrange("\0\0\xD7\xFE\0\0\0-\0\0\xE0\x02") eq
	"\0\0\xD7\xFE\0\0\xD7\xFF\0\0\xE0\x00\0\0\xE0\x01\0\0\xE0\x02"
   && $u32le->mkrange("\xFE\xD7\0\0-\0\0\0\x02\xE0\0\0") eq
	"\xFE\xD7\0\0\xFF\xD7\0\0\x00\xE0\0\0\x01\xE0\0\0\x02\xE0\0\0"
    ? "ok" : "not ok", " ", ++$loaded, "\n";

# U+FFFD..U+10001
print $utf8->mkrange("\xef\xbf\xbd-\xf0\x90\x80\x81")
	eq pack('H*', "efbfbdefbfbeefbfbff0908080f0908081")
   && $u16be->mkrange("\xFF\xFD\0-\xD8\x00\xDC\x01")
	eq pack('H*', "fffdfffeffffd800dc00d800dc01")
   && $u16le->mkrange("\xFD\xFF-\0\x00\xD8\x01\xDC")
	eq pack('H*', "fdfffeffffff00d800dc00d801dc")
   && $u32be->mkrange("\0\0\xFF\xFD\0\0\0-\x00\x01\x00\x01")
	eq pack('H*', "0000fffd0000fffe0000ffff0001000000010001")
   && $u32le->mkrange("\xFD\xFF\0\0-\0\0\0\x01\x00\x01\x00")
	eq pack('H*', "fdff0000feff0000ffff00000000010001000100")
    ? "ok" : "not ok", " ", ++$loaded, "\n";

# U+2FFFE..U+30001
print $utf8->mkrange("\xf0\xaf\xbf\xbe-\xf0\xb0\x80\x81")
	eq pack('H*', "f0afbfbef0afbfbff0b08080f0b08081")
   && $u16be->mkrange("\xd8\x7f\xdf\xfe\0-\xd8\x80\xdc\x01")
	eq pack('H*', "d87fdffed87fdfffd880dc00d880dc01")
   && $u16le->mkrange("\x7f\xd8\xfe\xdf-\0\x80\xd8\x01\xdc")
	eq pack('H*', "7fd8fedf7fd8ffdf80d800dc80d801dc")
   && $u32be->mkrange("\x00\x02\xFF\xFE\0\0\0-\x00\x03\x00\x01")
	eq pack('H*', "0002fffe0002ffff0003000000030001")
   && $u32le->mkrange("\xFE\xFF\x02\x00-\0\0\0\x01\x00\x03\x00")
	eq pack('H*', "feff0200ffff02000000030001000300")
    ? "ok" : "not ok", " ", ++$loaded, "\n";

# U+7FFFE..U+80001
print $utf8->mkrange("\xf1\xbf\xbf\xbe-\xf2\x80\x80\x81")
	eq pack('H*', "f1bfbfbef1bfbfbff2808080f2808081")
   && $u16be->mkrange("\xd9\xbf\xdf\xfe\0-\xd9\xc0\xdc\x01")
	eq pack('H*', "d9bfdffed9bfdfffd9c0dc00d9c0dc01")
   && $u16le->mkrange("\xbf\xd9\xfe\xdf-\0\xc0\xd9\x01\xdc")
	eq pack('H*', "bfd9fedfbfd9ffdfc0d900dcc0d901dc")
   && $u32be->mkrange("\x00\x07\xFF\xFE\0\0\0-\x00\x08\x00\x01")
	eq pack('H*', "0007fffe0007ffff0008000000080001")
   && $u32le->mkrange("\xFE\xFF\x07\x00-\0\0\0\x01\x00\x08\x00")
	eq pack('H*', "feff0700ffff07000000080001000800")
    ? "ok" : "not ok", " ", ++$loaded, "\n";

# U+8FFFE..U+90001
print $utf8->mkrange("\xf2\x8f\xbf\xbe-\xf2\x90\x80\x81")
	eq pack('H*', "f28fbfbef28fbfbff2908080f2908081")
   && $u16be->mkrange("\xd9\xff\xdf\xfe\0-\xda\x00\xdc\x01")
	eq pack('H*', "d9ffdffed9ffdfffda00dc00da00dc01")
   && $u16le->mkrange("\xff\xd9\xfe\xdf-\0\x00\xda\x01\xdc")
	eq pack('H*', "ffd9fedfffd9ffdf00da00dc00da01dc")
   && $u32be->mkrange("\x00\x08\xFF\xFE\0\0\0-\x00\x09\x00\x01")
	eq pack('H*', "0008fffe0008ffff0009000000090001")
   && $u32le->mkrange("\xFE\xFF\x08\x00-\0\0\0\x01\x00\x09\x00")
	eq pack('H*', "feff0800ffff08000000090001000900")
    ? "ok" : "not ok", " ", ++$loaded, "\n";

#####

# U+E002..U+D7FE
print $utf8->mkrange("\xee\x80\x82-\xed\x9f\xbe", 1)
	eq pack('H*', "ee8082ee8081ee8080ed9fbfed9fbe")
   && $u16be->mkrange("\xE0\x02\0-\xD7\xFE", 1)
	eq pack('H*', "e002e001e000d7ffd7fe")
   && $u16le->mkrange("\x02\xE0-\0\xFE\xD7", 1)
	eq pack('H*', "02e001e000e0ffd7fed7")
   && $u32be->mkrange("\0\0\xE0\x02\0\0\0-\0\0\xD7\xFE", 1)
	eq pack('H*', "0000e0020000e0010000e0000000d7ff0000d7fe")
   && $u32le->mkrange("\x02\xE0\0\0-\0\0\0\xFE\xD7\0\0", 1)
	eq pack('H*', "02e0000001e0000000e00000ffd70000fed70000")
    ? "ok" : "not ok", " ", ++$loaded, "\n";

# U+10001..U+FFFD
print $utf8->mkrange("\xf0\x90\x80\x81-\xef\xbf\xbd", 1)
	eq pack('H*', "f0908081f0908080efbfbfefbfbeefbfbd")
   && $u16be->mkrange("\xD8\x00\xDC\x01\0-\xFF\xFD", 1)
	eq "\xD8\x00\xDC\x01\xD8\x00\xDC\x00\xFF\xFF\xFF\xFE\xFF\xFD"
   && $u16le->mkrange("\x00\xD8\x01\xDC-\0\xFD\xFF", 1)
	eq "\x00\xD8\x01\xDC\x00\xD8\x00\xDC\xFF\xFF\xFE\xFF\xFD\xFF"
   && $u32be->mkrange("\x00\x01\x00\x01\0\0\0-\0\0\xFF\xFD", 1)
	eq "\0\1\0\1\0\1\0\0\0\0\xFF\xFF\0\0\xFF\xFE\0\0\xFF\xFD"
   && $u32le->mkrange("\x01\x00\x01\x00-\0\0\0\xFD\xFF\0\0", 1)
	eq "\1\0\1\0\0\0\1\0\xFF\xFF\0\0\xFE\xFF\0\0\xFD\xFF\0\0"
    ? "ok" : "not ok", " ", ++$loaded, "\n";

# U+30001..U+2FFFE
print $utf8->mkrange("\xf0\xb0\x80\x81-\xf0\xaf\xbf\xbe", 1)
	eq pack('H*', "f0b08081f0b08080f0afbfbff0afbfbe")
   && $u16be->mkrange("\xd8\x80\xdc\x01\0-\xd8\x7f\xdf\xfe", 1)
	eq pack('H*', "d880dc01d880dc00d87fdfffd87fdffe")
   && $u16le->mkrange("\x80\xd8\x01\xdc-\0\x7f\xd8\xfe\xdf", 1)
	eq pack('H*', "80d801dc80d800dc7fd8ffdf7fd8fedf")
   && $u32be->mkrange("\x00\x03\x00\x01\0\0\0-\x00\x02\xFF\xFE", 1)
	eq pack('H*', "00030001000300000002ffff0002fffe")
   && $u32le->mkrange("\x01\x00\x03\x00-\0\0\0\xFE\xFF\x02\x00", 1)
	eq pack('H*', "0100030000000300ffff0200feff0200")
    ? "ok" : "not ok", " ", ++$loaded, "\n";

# U+80001..U+7FFFE
print $utf8->mkrange("\xf2\x80\x80\x81-\xf1\xbf\xbf\xbe", 1)
	eq pack('H*', "f2808081f2808080f1bfbfbff1bfbfbe")
   && $u16be->mkrange("\xd9\xc0\xdc\x01\0-\xd9\xbf\xdf\xfe", 1)
	eq pack('H*', "d9c0dc01d9c0dc00d9bfdfffd9bfdffe")
   && $u16le->mkrange("\xc0\xd9\x01\xdc-\0\xbf\xd9\xfe\xdf", 1)
	eq pack('H*', "c0d901dcc0d900dcbfd9ffdfbfd9fedf")
   && $u32be->mkrange("\x00\x08\x00\x01\0\0\0-\x00\x07\xFF\xFE", 1)
	eq pack('H*', "00080001000800000007ffff0007fffe")
   && $u32le->mkrange("\xFE\xFF\x07\x00-\0\0\0\x01\x00\x08\x00")
	eq pack('H*', "feff0700ffff07000000080001000800")
    ? "ok" : "not ok", " ", ++$loaded, "\n";

# U+90001..U+8FFFE
print $utf8->mkrange("\xf2\x90\x80\x81-\xf2\x8f\xbf\xbe", 1)
	eq pack('H*', "f2908081f2908080f28fbfbff28fbfbe")
   && $u16be->mkrange("\xda\x00\xdc\x01\0-\xd9\xff\xdf\xfe", 1)
	eq pack('H*', "da00dc01da00dc00d9ffdfffd9ffdffe")
   && $u16le->mkrange("\x00\xda\x01\xdc-\0\xff\xd9\xfe\xdf", 1)
	eq pack('H*', "00da01dc00da00dcffd9ffdfffd9fedf")
    ? "ok" : "not ok", " ", ++$loaded, "\n";

# U+D7FF..U+E000, U+10000..U+FFFF
print $utf8->mkrange(
	"\xed\x9f\xbf-\xee\x80\x80\xf0\x90\x80\x80-\xef\xbf\xbf", 1)
	eq "\xed\x9f\xbf\xee\x80\x80\xf0\x90\x80\x80\xef\xbf\xbf"
   && $u16be->mkrange("\xD7\xFF\0-\xE0\x00\xD8\x00\xDC\x00\0-\xFF\xFF", 1)
	eq "\xD7\xFF\xE0\x00\xD8\x00\xDC\x00\xFF\xFF"
   && $u16le->mkrange("\xFF\xD7-\0\x00\xE0\x00\xD8\x00\xDC-\0\xFF\xFF", 1)
	eq "\xFF\xD7\x00\xE0\x00\xD8\x00\xDC\xFF\xFF"
    ? "ok" : "not ok", " ", ++$loaded, "\n";

# U+D7FF..U+E000, U+10000..U+FFFF, U+7F
print $utf8->mkrange(
	"\xed\x9f\xbf-\xee\x80\x80\xf0\x90\x80\x80-\xef\xbf\xbf\x7F")
	eq "\xed\x9f\xbf\xee\x80\x80\x7F"
   && $u16be->mkrange("\xD7\xFF\0-\xE0\x00\xD8\x00\xDC\x00\0-\xFF\xFF\0\x7F")
	eq "\xD7\xFF\xE0\x00\0\x7F"
   && $u16le->mkrange("\xFF\xD7-\0\x00\xE0\x00\xD8\x00\xDC-\0\xFF\xFF\x7F\0")
	eq "\xFF\xD7\x00\xE0\x7F\0"
    ? "ok" : "not ok", " ", ++$loaded, "\n";

1;
__END__

