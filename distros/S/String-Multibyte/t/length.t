
BEGIN { $| = 1; print "1..9\n"; }
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

print $bytes->length("") == 0
   && $euc  ->length("") == 0
   && $eucjp->length("") == 0
   && $sjis ->length("") == 0
   && $utf8 ->length("") == 0
   && $u16be->length("") == 0
   && $u16le->length("") == 0
   && $u32be->length("") == 0
   && $u32le->length("") == 0
  ? "ok" : "not ok", " 2\n";

print $bytes->length("\x00\x00") == 2
   && $euc  ->length("\x00\x00") == 2
   && $eucjp->length("\x00\x00") == 2
   && $sjis ->length("\x00\x00") == 2
   && $utf8 ->length("\x00\x00") == 2
   && $u16be->length("\x00\x00") == 1
   && $u16le->length("\x00\x00") == 1
   && $u16be->length("\x00\x00\x00\x00") == 2
   && $u16le->length("\x00\x00\x00\x00") == 2
   && $u32be->length("\x00\x00\x00\x00") == 1
   && $u32le->length("\x00\x00\x00\x00") == 1
  ? "ok" : "not ok", " 3\n";

print $sjis ->length("\x81\x40\xAD\x40") == 3
   && $sjis ->length("\xDF\xA1\xAD\xAE") == 4
   && $euc  ->length("\xDF\xA1\xAD\xAE") == 2
   && $euc  ->length("\xA1\xA1\x20\xBD\xBE") == 3
   && $eucjp->length("\xA1\xA1\x20\xBD\xBE") == 3
   && $eucjp->length("\x8F\xA1\xA1\x20\x8F\xBD\xBE") == 3
   && $eucjp->length("\x8E\xA1\x20\x8F\xBD\xBE") == 3
  ? "ok" : "not ok", " 4\n";

print $utf8 ->length("\xC2\xA0\xEF\xBD\xBF\x60") == 3
   && $utf8 ->length("\x41\xE2\x89\xA2\xCE\x91\x2E") == 4
   && $utf8 ->length("\xED\x95\x9C\xEA\xB5\xAD\xEC\x96\xB4") == 3
   && $utf8 ->length("\xE6\x97\xA5\xE6\x9C\xAC\xE8\xAA\x9E") == 3
  ? "ok" : "not ok", " 5\n";

print $u16be->length("\xD8\x08\xDF\x45\x00\x3D\x00\x52\x00\x61") == 4
   && $u16le->length("\x08\xD8\x45\xDF\x3D\x00\x52\x00\x61\x00") == 4
   && $u16be->length("\x08\xD8\x45\xDF\x3D\x00\x52\x00\x61\x00") == 5
   && $u16le->length("\xD8\x08\xDF\x45\x00\x3D\x00\x52\x00\x61") == 5
  ? "ok" : "not ok", " 6\n";

if ($] < 5.008) {
    print 1 ? "ok" : "not ok", " 7\n";
    print 1 ? "ok" : "not ok", " 8\n";
} else {
    $uni   = String::Multibyte->new('Unicode',1);
    $bytes = String::Multibyte->new('Bytes',1);

    print 0 == $uni->length("")
      &&  3 == $uni->length("abc")
      &&  5 == $uni->length(pack 'U*',
	0xFF71,0xFF72,0xFF73,0xFF74,0xFF75)
      &&  4 == $uni->length(pack 'U*', 0x3042,0x304B,0x3055,0x305F)
      &&  9 == $uni->length('AIUEO'.
	pack 'U*', 0x65E5, 0x672C,0x6F22,0x5B57)
      ? "ok" : "not ok", " 7\n";

    print 0 == $bytes->length("")
      &&  3 == $bytes->length("abc")
      &&  5 == $bytes->length(pack 'C*', 0xF1,0xF2,0xF3,0xF4,0xF5)
      &&  9 == $bytes->length('AIUEO'.pack 'C*', 0xE5, 0x2C,0x22,0x57)
      ? "ok" : "not ok", " 8\n";
}

# see perlfaq6
$martian  = String::Multibyte->new({
	charset => "martian",
	regexp => '[A-Z][A-Z]|[^A-Z]',
    },1);

print $martian->length("AAxBGy") == 4
   && $martian->length("") == 0
   && $martian->length("zzz") == 3
   && $martian->length("ZZZZ") == 2
  ? "ok" : "not ok", " 9\n";

1;
__END__

