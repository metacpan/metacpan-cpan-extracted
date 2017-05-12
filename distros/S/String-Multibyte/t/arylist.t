
BEGIN { $| = 1; print "1..22\n"; }
END {print "not ok 1\n" unless $loaded;}
use String::Multibyte;
$^W = 1;
$loaded = 1;
print "ok 1\n";

$crlf  = String::Multibyte->new({
	charset => "CRLF",
	regexp => "\cM\cJ|[\x00-\xFF]",
    },1);

$n = "\cM\cJ";

$str = "[a1]\cM\cM[b2]\cM\cJ[c3]\cJ\cM[d4]\cJ\cJ[e5]\cJ\cM\cJ\cM";
$ret = "[a1]\cJ\cJ[b2]\cM\cJ[c3]\cM\cJ[d4]\cM\cM[e5]\cM\cM\cJ\cJ";

print $ret eq $crlf->strtr($str, "\cMa\cJ", "\cJa\cM")
    ? "ok" : "not ok", " 2\n";

print $ret eq $crlf->strtr($str, ["\cM", "\cJ"], ["\cJ", "\cM"])
    ? "ok" : "not ok", " 3\n";

print $ret eq $crlf->strtr($str, ["\cM", "\cJ"], "\cJ\cM")
    ? "ok" : "not ok", " 4\n";

$ret2 = "[a1]${n}${n}[b2]${n}[c3]${n}${n}[d4]${n}${n}[e5]${n}${n}${n}";
# \cJ to \cM\cJ and \cM to \cM\cJ

print $ret2 eq $crlf->strtr($str, "\cJ\cM", "\cM\cJ")
    ? "ok" : "not ok", " 5\n";

print $ret2 eq $crlf->strtr($str, ["\cM", "\cJ"], "\cM\cJ")
    ? "ok" : "not ok", " 6\n";

print $str eq $crlf->strtr($str, "\cM\cJ", "\cM\cJ")
    ? "ok" : "not ok", " 7\n";

$str = "\cM\cJ\cM\cJ\cM\cJ\cM";

print $crlf->strspn($str, "\cM\cJ") == 3
    ? "ok" : "not ok", " 8\n";

print $crlf->strspn($str, "\cJ\cM") == 0
    ? "ok" : "not ok", " 9\n";

$str = "\cM\cM\cM\cM\cM\cM\cJ";

print $crlf->strspn($str, "\cM") == 5
    ? "ok" : "not ok", " 10\n";

print $crlf->strspn($str, "\cM\cJ") == 0
    ? "ok" : "not ok", " 11\n";

print $crlf->strspn($str, "\cJ\cM") == 5
    ? "ok" : "not ok", " 12\n";

print $crlf->strspn($str, ["\cM","\cJ"]) == 5
    ? "ok" : "not ok", " 13\n";

$str = "\cJ\cM\cM\cM\cM\cM\cM";

print $crlf->strspn($str, "\cM") == 0
    ? "ok" : "not ok", " 14\n";

print $crlf->strspn($str, "\cM\cJ") == 0
    ? "ok" : "not ok", " 15\n";

print $crlf->strspn($str, "\cJ\cM") == 7
    ? "ok" : "not ok", " 16\n";

print $crlf->strspn($str, ["\cM","\cJ"]) == 7
    ? "ok" : "not ok", " 17\n";

print $crlf->strcspn($str, ["\cM\cJ"]) == 7
    ? "ok" : "not ok", " 18\n";

print $crlf->strcspn($str, ["\cJ\cM"]) == 0
    ? "ok" : "not ok", " 19\n";

$str = "\cM\cJ\cM\cJ\cM\cJ\cM\cJ\cM\cJ\cJ";

print $crlf->strcspn($str, ["\cM","\cJ"]) == 5
    ? "ok" : "not ok", " 20\n";


$sjis = String::Multibyte->new('ShiftJIS');

$str = 'あイＵｅおカ';

print $sjis->strtr($str,
    ['ぁ-ん', 'Ａ-Ｚ'],
    ['ァ-ン', 'A-Z']) eq 'アイUｅオカ'
    ? "ok" : "not ok", " 21\n";

print $sjis->strtr($str,
    ['ぁ-んＡ-Ｚ'],
    ['ァ-ンA-Z']) eq 'アイUｅオカ'
    ? "ok" : "not ok", " 22\n";


1;
__END__
