
BEGIN { $| = 1; print "1..8\n"; }
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

print $bytes->strrev("") eq ""
   && $euc  ->strrev("") eq ""
   && $eucjp->strrev("") eq ""
   && $sjis ->strrev("") eq ""
   && $utf8 ->strrev("") eq ""
   && $u16be->strrev("") eq ""
   && $u16le->strrev("") eq ""
   && $u32be->strrev("") eq ""
   && $u32le->strrev("") eq ""
  ? "ok" : "not ok", " 2\n";

print $bytes ->strrev("\x00\x00") eq "\x00\x00"
   && $euc  ->strrev("\x00\x00") eq "\x00\x00"
   && $eucjp->strrev("\x00\x00") eq "\x00\x00"
   && $sjis ->strrev("\x00\x00") eq "\x00\x00"
   && $utf8 ->strrev("\x00\x00") eq "\x00\x00"
   && $u16be->strrev("\x00\x00") eq "\x00\x00"
   && $u16le->strrev("\x00\x00") eq "\x00\x00"
  ? "ok" : "not ok", " 3\n";

print $sjis ->strrev("\x81\x40\xAD\x40")
	eq "\x40\xAD\x81\x40"
   && $sjis ->strrev("\xDF\xA1\xAD\xAE")
	eq "\xAE\xAD\xA1\xDF"
   && $euc ->strrev("\xDF\xA1\xAD\xAE")
	eq "\xAD\xAE\xDF\xA1"
   && $euc  ->strrev("\xA1\xA1\x20\xBD\xBE")
	eq "\xBD\xBE\x20\xA1\xA1"
   && $eucjp->strrev("\xA1\xA1\x20\xBD\xBE")
	eq "\xBD\xBE\x20\xA1\xA1"
   && $eucjp->strrev("\x8F\xA1\xA1\x20\x8F\xBD\xBE")
	eq "\x8F\xBD\xBE\x20\x8F\xA1\xA1"
   && $eucjp->strrev("\x8E\xA1\x20\x8F\xBD\xBE")
	eq "\x8F\xBD\xBE\x20\x8E\xA1"
    ? "ok" : "not ok", " 4\n";

print $u16be->strrev("\xD8\x08\xDF\x45\x00\x3D\x00\x52\x00\x61")
	eq "\x00\x61\x00\x52\x00\x3D\xD8\x08\xDF\x45"
   && $u16le->strrev("\x08\xD8\x45\xDF\x3D\x00\x52\x00\x61\x00")
	eq "\x61\x00\x52\x00\x3D\x00\x08\xD8\x45\xDF"
   && $u16be->strrev("\x08\xD8\x45\xDF\x3D\x00\x52\x00\x61\x00")
	eq "\x61\x00\x52\x00\x3D\x00\x45\xDF\x08\xD8"
   && $u16le->strrev("\xD8\x08\xDF\x45\x00\x3D\x00\x52\x00\x61")
	eq "\x00\x61\x00\x52\x00\x3D\xDF\x45\xD8\x08"
    ? "ok" : "not ok", " 5\n";

print $utf8 ->strrev("\xC2\xA0\xEF\xBD\xBF\x60")
	eq "\x60\xEF\xBD\xBF\xC2\xA0"
   && $utf8 ->strrev("\x41\xE2\x89\xA2\xCE\x91\x2E")
	eq "\x2E\xCE\x91\xE2\x89\xA2\x41"
   && $utf8 ->strrev("\xED\x95\x9C\xEA\xB5\xAD\xEC\x96\xB4")
	eq "\xEC\x96\xB4\xEA\xB5\xAD\xED\x95\x9C"
   && $utf8 ->strrev("\xE6\x97\xA5\xE6\x9C\xAC\xE8\xAA\x9E")
	eq "\xE8\xAA\x9E\xE6\x9C\xAC\xE6\x97\xA5"
    ? "ok" : "not ok", " 6\n";

print $u32be->strrev("\0\0\x30\x42\x00\x01\xFF\xFE\0\0\x00\x41")
	eq "\0\0\x00\x41\x00\x01\xFF\xFE\0\0\x30\x42"
   && $u32le->strrev("\x42\x30\0\0\xFE\xFF\x01\x00\x41\x00\0\0")
	eq "\x41\x00\0\0\xFE\xFF\x01\x00\x42\x30\0\0"
   && $u32be->strrev("\0\0\x30\x00\x00\x01\x00\x00\0\0\x00\x41")
	eq "\0\0\x00\x41\x00\x01\x00\x00\0\0\x30\x00"
   && $u32le->strrev("\x00\x30\0\0\x00\x00\x01\x00\x41\x00\0\0")
	eq "\x41\x00\0\0\x00\x00\x01\x00\x00\x30\0\0"
    ? "ok" : "not ok", " 7\n";

# see perlfaq6
$martian  = String::Multibyte->new({
	charset => "martian",
	regexp => '[A-Z][A-Z]|[^A-Z]',
    },1);

print $martian->strrev("AAxBGy") eq "yBGxAA"
   && $martian->strrev("") eq ""
   && $martian->strrev("xyz") eq "zyx"
   && $martian->strrev("zXZq") eq "qXZz"
   && $martian->strrev("ZZZZ") eq "ZZZZ"
   && $martian->strrev("zzz") eq "zzz"
  ? "ok" : "not ok", " 8\n";

1;
__END__
