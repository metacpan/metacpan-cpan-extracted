
BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::String qw(:all);

$^W = 1;
$loaded = 1;
print "ok 1\n";

if ($] < 5.005) {
  foreach(2..16) { print "ok $_\n"; }
  exit;
}

#####

print 'abcあＡＢＣxyz' eq tolower 'AbCあＡＢＣXYz'
  ? "ok" : "not ok", " 2\n";

print '' eq toupper ''
  ? "ok" : "not ok", " 3\n";

print length '' eq '0'
  ? "ok" : "not ok", " 4\n";

print 9 == length 'Perlのテスト.'
  ? "ok" : "not ok", " 5\n";

print '.トステのlreP' eq strrev 'Perlのテスト.'
  ? "ok" : "not ok", " 6\n";

print 'これはパールのテストです' eq kanaH2Z 'これはﾊﾟｰﾙのﾃスﾄです'
  ? "ok" : "not ok", " 7\n";

print kataZ2H 'これはパｰルのテストです' eq 'これはﾊﾟｰﾙのﾃｽﾄです'
  ? "ok" : "not ok", " 8\n";

print 'ｺﾚﾊﾊﾟｰﾙﾉﾃｽﾄﾃﾞｽ' eq kanaZ2H 'これはパｰルのテストです'
  ? "ok" : "not ok", " 9\n";

print 'コレハぱーるノてすとデス' eq hiXka 'これはパールのテストです'
  ? "ok" : "not ok", " 10\n";

print hi2ka 'これはパールのテストです' eq 'コレハパールノテストデス'
  ? "ok" : "not ok", " 11\n";

print ka2hi 'これはパールのﾃｽトです'   eq 'これはぱーるのﾃｽとです'
  ? "ok" : "not ok", " 12\n";

print spaceH2Z ' あ　 　い  ' eq '　あ　　　い　　'
  ? "ok" : "not ok", " 13\n";

print spaceZ2H ' あ　 　い  ' eq ' あ   い  '
  ? "ok" : "not ok", " 14\n";

print spaceH2Z 'あい' eq 'あい'
  ? "ok" : "not ok", " 15\n";

print spaceZ2H 'あい' eq 'あい'
  ? "ok" : "not ok", " 16\n";

1;
__END__
