
BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}

use String::Multibyte;

$big5  = String::Multibyte->new('Big5',1);
$big5p = String::Multibyte->new('Big5Plus',1);
$bytes = String::Multibyte->new('ShiftJIS',1);
$euc   = String::Multibyte->new('EUC',1);
$eucjp = String::Multibyte->new('EUC_JP',1);
$euctw = String::Multibyte->new('EUC_TW',1);
$gbk   = String::Multibyte->new('GBK',1);
$gb18  = String::Multibyte->new('GB18030',1);
$johab = String::Multibyte->new('Johab',1);
$sjis  = String::Multibyte->new('ShiftJIS',1);
$uhc   = String::Multibyte->new('UHC',1);
$utf8  = String::Multibyte->new('UTF8',1);
$u16be = String::Multibyte->new('UTF16BE',1);
$u16le = String::Multibyte->new('UTF16LE',1);
$u32be = String::Multibyte->new('UTF32BE',1);
$u32le = String::Multibyte->new('UTF32LE',1);

$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

print $big5 ->islegal("")
   && $big5p->islegal("")
   && $bytes->islegal("")
   && $euc  ->islegal("")
   && $eucjp->islegal("")
   && $euctw->islegal("")
   && $gb18 ->islegal("")
   && $gbk  ->islegal("")
   && $johab->islegal("")
   && $sjis ->islegal("")
   && $utf8 ->islegal("")
   && $u16be->islegal("")
   && $u16le->islegal("")
   && $u32be->islegal("")
   && $u32le->islegal("")
   && $uhc  ->islegal("")
  ? "ok" : "not ok", " 2\n";


print $big5 ->islegal("\x00\x00")
   && $big5p->islegal("\x00\x00")
   && $bytes->islegal("\x00\x00")
   && $euc  ->islegal("\x00\x00")
   && $eucjp->islegal("\x00\x00")
   && $euctw->islegal("\x00\x00")
   && $gb18 ->islegal("\x00\x00")
   && $gbk  ->islegal("\x00\x00")
   && $johab->islegal("\x00\x00")
   && $sjis ->islegal("\x00\x00")
   && $utf8 ->islegal("\x00\x00")
   && $u16be->islegal("\x00\x00")
   && $u16le->islegal("\x00\x00")
   && !$u32be->islegal("\x00\x00")
   && !$u32le->islegal("\x00\x00")
   && $uhc  ->islegal("\x00\x00")
  ? "ok" : "not ok", " 3\n";

print $sjis ->islegal("\x81\x40\xAD\x40")
   && $euc  ->islegal("\xA1\xA1\x20\xBD\xBD")
   && $eucjp->islegal("\xA1\xA1\x20\xBD\xBD")
   && $utf8 ->islegal("\xC2\xA0\xEF\xBD\xBF\x60")
   && $u16be->islegal("\xD8\x08\xDF\x45\x00\x3D\x00\x52\x00\x61")
   && $u16le->islegal("\x08\xD8\x45\xDF\x3D\x00\x52\x00\x61\x00")
   && $u16be->islegal("\x08\xD8\x45\xDF\x3D\x00\x52\x00\x61\x00")
   && $u16le->islegal("\xD8\x08\xDF\x45\x00\x3D\x00\x52\x00\x61")
   && $utf8 ->islegal("\x41\xE2\x89\xA2\xCE\x91\x2E")
   && $utf8 ->islegal("\xED\x95\x9C\xEA\xB5\xAD\xEC\x96\xB4")
   && $utf8 ->islegal("\xE6\x97\xA5\xE6\x9C\xAC\xE8\xAA\x9E")
  ? "ok" : "not ok", " 4\n";

print   $big5 ->islegal("\x00\x00\x00")
   &&   $big5p->islegal("\x00\x00\x00")
   &&   $bytes->islegal("\x00\x00\x00")
   &&   $euc  ->islegal("\x00\x00\x00")
   &&   $eucjp->islegal("\x00\x00\x00")
   &&   $euctw->islegal("\x00\x00\x00")
   &&   $gb18 ->islegal("\x00\x00\x00")
   &&   $gbk  ->islegal("\x00\x00\x00")
   &&   $johab->islegal("\x00\x00\x00")
   &&   $sjis ->islegal("\x00\x00\x00")
   &&   $utf8 ->islegal("\x00\x00\x00")
   && ! $u16be->islegal("\x00\x00\x00")
   && ! $u16le->islegal("\x00\x00\x00")
   && ! $u32be->islegal("\x00\x00\x00")
   && ! $u32le->islegal("\x00\x00\x00")
   &&   $u32be->islegal("\x00\x00\x00\x00")
   &&   $u32le->islegal("\x00\x00\x00\x00")
   &&   $uhc  ->islegal("\x00\x00")
  ? "ok" : "not ok", " 5\n";

print ! $utf8 ->islegal("\x41\xC0\x80")
   && ! $u16be->islegal("\x41\xC0\x80")
   && ! $u16le->islegal("\x41\xC0\x80")
   &&   $u16be->islegal("\x00\xD8")
   && ! $u16le->islegal("\x00\xD8")
   && ! $u16be->islegal("\xD8\x80")
   &&   $u16le->islegal("\xD8\x80")
  ? "ok" : "not ok", " 6\n";

# see perlfaq6
$martian  = String::Multibyte->new({
	charset => "martian",
	regexp => '[A-Z][A-Z]|[^A-Z]',
    },1);

print   $martian->islegal("AAxBGy")
   &&   $martian->islegal("")
   &&   $martian->islegal("zzz")
   && ! $martian->islegal("zXzz")
   &&   $martian->islegal("ZZZZ")
   && ! $martian->islegal("ZZZ")
  ? "ok" : "not ok", " 7\n";

1;
__END__
