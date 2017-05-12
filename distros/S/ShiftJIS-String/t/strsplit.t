
BEGIN { $| = 1; print "1..24\n"; }
END {print "not ok 1\n" unless $loaded;}
use ShiftJIS::String qw(mkrange trclosure strsplit);
$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

sub listtostr {
  my @a = @_;
  return @a ? join('', map "<$_>", @a) : '';
}

{
  my $printZ2H = trclosure(
    '０-９Ａ-Ｚａ-ｚ　／＝＋－．，：；？！＃＄％＆＠＊＜＞（）［］｛｝',
    '0-9A-Za-z /=+\-.,:;?!#$%&@*<>()[]{}',
  );

  my $str = '  This  is   a  TEST =@ ';
  my $zen = '　 Tｈiｓ　 is　 　a  ＴＥST　＝@ ';

  my($n, $NG);

# splitchar in scalar context
  $NG = 0;
  for ($n = -1; $n <= 20; $n++) {
    my $core = @{[ split(//, $str, $n) ]};
    my $sjis = strsplit('',$zen,$n);
    ++$NG unless $core == $sjis;
  }
  print !$NG ? "ok" : "not ok", " 2\n";

# splitchar in list context
  $NG = 0;
  for ($n = -1; $n <= 20; $n++) {
    my $core = listtostr( split //, $str, $n );
    my $sjis = listtostr( strsplit('',$zen,$n) );
    ++$NG unless $core eq &$printZ2H($sjis);
  }
  print !$NG ? "ok" : "not ok", " 3\n";

# splitspace in scalar context
  $NG = 0;
  for ($n = -1; $n <= 5; $n++) {
    my $core = @{[ split ' ', $str, $n ]};
    my $sjis = strsplit(undef,$zen,$n);
    ++$NG unless $core eq &$printZ2H($sjis);
  }
  print !$NG ? "ok" : "not ok", " 4\n";

# splitspace in list context
  $NG = 0;
  for ($n = -1; $n <= 5; $n++) {
    my $core = listtostr( split(' ', $str, $n) );
    my $sjis = listtostr( strsplit(undef,$zen,$n) );
    ++$NG unless $core eq &$printZ2H($sjis);
  }
  print !$NG ? "ok" : "not ok", " 5\n";

# split / / in scalar context
  $NG = 0;
  for ($n = -1; $n <= 5; $n++) {
    my $core = @{ [ split(/ /, $str, $n) ] };
    my $sjis = strsplit(' ',$str,$n);
    ++$NG unless $core == $sjis;
  }
  print !$NG ? "ok" : "not ok", " 6\n";

# split / / in list context
  $NG = 0;
  for ($n = -1; $n <= 5; $n++) {
    my $core = listtostr( split(/ /, $str, $n) );
    my $sjis = listtostr( strsplit(' ',$str,$n) );
    ++$NG unless $core eq &$printZ2H($sjis);
  }
  print !$NG ? "ok" : "not ok", " 7\n";

# splitchar '' in scalar context
  $NG = 0;
  for ($n = -1; $n <= 20; $n++) {
    my $core = @{[ split(//, '', $n) ]};
    my $sjis = strsplit('','',$n);
    ++$NG unless $core == $sjis;
  }
  print !$NG ? "ok" : "not ok", " 8\n";

# splitchar '' in list context
  $NG = 0;
  for ($n = -1; $n <= 20; $n++) {
    my $core = listtostr split //, '', $n;
    my $sjis = listtostr strsplit '','',$n;
    ++$NG unless $core eq $sjis;
  }
  print !$NG ? "ok" : "not ok", " 9\n";

# splitspace '' in scalar context
  $NG = 0;
  for ($n = -1; $n <= 20; $n++) {
    my $core = @{[ split(' ', '', $n) ]};
    my $sjis = strsplit(undef,'',$n);
    ++$NG unless $core == $sjis;
  }
  print !$NG ? "ok" : "not ok", " 10\n";

# splitspace '' in list context
  $NG = 0;
  for ($n = -1; $n <= 20; $n++) {
    my $core = listtostr split ' ', '', $n;
    my $sjis = listtostr strsplit undef,'',$n;
    ++$NG unless $core eq $sjis;
  }
  print !$NG ? "ok" : "not ok", " 11\n";

# split / /, '' in scalar context
  $NG = 0;
  for ($n = -1; $n <= 5; $n++) {
    my $core = @{ [ split(/ /, '', $n) ] };
    my $sjis = strsplit(' ', '', $n);
    ++$NG unless $core == $sjis;
  }
  print !$NG ? "ok" : "not ok", " 12\n";

# split / /, '' in list context
  $NG = 0;
  for ($n = -1; $n <= 5; $n++) {
    my $core = listtostr split / /, '', $n;
    my $sjis = listtostr strsplit ' ', '', $n;
    ++$NG unless $core eq $sjis;
  }
  print !$NG ? "ok" : "not ok", " 13\n";

# end by non-SPACE
  $str = "\t\n\r\f\n".'  This  is   a  TEST =@';
  $zen = "\t\n\r\f\n".'　 Tｈiｓ　 is　 　a  ＴＥST　＝@';

# splitspace in scalar context
  $NG = 0;
  for ($n = -1; $n <= 5; $n++) {
    my $core = @{[ split ' ', $str, $n ]};
    my $sjis = strsplit(undef,$zen,$n);
    ++$NG unless $core eq &$printZ2H($sjis);
  }
  print !$NG ? "ok" : "not ok", " 14\n";

# splitspace in list context
  $NG = 0;
  for ($n = -1; $n <= 5; $n++) {
    my $core = listtostr( split(' ', $str, $n) );
    my $sjis = listtostr( strsplit(undef,$zen,$n) );
    ++$NG unless $core eq &$printZ2H($sjis);
  }
  print !$NG ? "ok" : "not ok", " 15\n";
}


print 1
  && 'Perl:駱駝:Camel' eq join(":", strsplit('／', 'Perl／駱駝／Camel'))
  && 'あ:いう:えおメ^' eq join(':', strsplit('／', 'あ／いう／えおメ^'))
  && join(':', strsplit(undef, '　　　あ  いう＝@　えお　メ^', 3))
     eq 'あ:いう＝@:えお　メ^'
  && join(':', strsplit undef, ' 　 This  is 　 Perl.')
     eq 'This:is:Perl.'
  && join('-;-', strsplit('|', '頭にポマード；キャ|ポポロ||ン アポロ'))
     eq '頭にポマード；キャ-;-ポポロ-;--;-ン アポロ'
  && join('/', strsplit('あ', 'かきくあいうえおあお'))
     eq 'かきく/いうえお/お'
  && join('/', strsplit 'ポポ', 'ポパポピああポポポ|ああポ|ポポカあ|あ', 4)
     eq 'ポパポピああ/ポ|ああポ|/カあ|あ'
  && join('/', strsplit('||', 'あいうえお||パピプペポ||01234||', -5))
     eq 'あいうえお/パピプペポ/01234/'
  && join('/', strsplit('||', 'あいうえお||パピプペポ||01234||'))
     eq 'あいうえお/パピプペポ/01234'
  && join('/', strsplit('||', 'あいうえお||パピプペポ||01234||', 2))
     eq 'あいうえお/パピプペポ||01234||'
  && join('/', strsplit('||', '||あいうえお||パピプペポ||01234||||'))
     eq '/あいうえお/パピプペポ/01234'
  && join('/', strsplit('||', '||あいうえお||パピプペポ||01234||||', -10))
     eq '/あいうえお/パピプペポ/01234//'
  && join('-:-', strsplit('／', 'Perl／プログラム／パスワード'))
     eq 'Perl-:-プログラム-:-パスワード'
  ? "ok" : "not ok", " 16\n";


{
  my($n, $NG, $ary);
  for $ary (
    ["AA", "AAAA", 3 ],
    ["AA", "AAAA", 0 ],
    ["AA", "AAAA", -1 ],
    ["AA", "AA", 3 ],
    ["AA", "AA", 0 ],
    ["AA", "AA", -1 ],
    ["AB", "AB", 3 ],
    ["AB", "AB", 0 ],
    ["AB", "AB", -1 ],
    ["AB", "AC", 3 ],
    ["AB", "AC", 0 ],
    ["AB", "AC", -1 ],
    ["AA", "AAAAAAAAA", 3 ],
    ["AA", "AAAAAAAAA", 0 ],
    ["AA", "AAAAAAAAA", -1 ],
    ["AA", "AAAAAAAAAA", 3 ],
    ["AA", "AAAAAAAAAA", 0 ],
    ["AA", "AAAAAAAAAA", -1 ],
    ["AA", "AAABBAABBAA", 4 ],
    ["AA", "AAABBAABBAAAA", 7 ],
  )
  {
     my $core_s = @{[ split($ary->[0], $ary->[1], $ary->[2]) ]};
     my $sjis_s = strsplit($ary->[0], $ary->[1], $ary->[2]);
     my $core_l = listtostr split($ary->[0], $ary->[1], $ary->[2]);
     my $sjis_l = listtostr strsplit($ary->[0], $ary->[1], $ary->[2]);
     ++$NG unless $core_s == $sjis_s && $core_l eq $sjis_l;
  }
  print !$NG ? "ok" : "not ok", " 17\n";
}

print 1
  && 'Perl:駱駝:Camel' eq join(":", strsplit(undef, 'Perl　駱駝　Camel'))
  && 'Perl:駱駝　Camel' eq join(":", strsplit(undef, 'Perl　駱駝　Camel',2))
  && 'Perl:駱駝:Camel' eq join(":", strsplit(undef, 'Perl　駱駝　Camel　'))
  && 'Perl:駱駝:Camel:' eq join(":", strsplit(undef, 'Perl　駱駝　Camel　',-2))
  ? "ok" : "not ok", " 18\n";

print 1
    && "\x00:\x42\x00" eq
	join(':', strsplit("\x30\x00", "\x00\x30\x00\x42\x00"))
    && "\x00\x30\x00\x42\x00" eq
	join(':', strsplit("\x30\x01", "\x00\x30\x00\x42\x00"))
    && ":\x00\x42\x00" eq
	join(':', strsplit("\x00\x30", "\x00\x30\x00\x42\x00"))
    && "\x00\x30\x00\x42\x00" eq
	join(':', strsplit("\x01\x30", "\x00\x30\x00\x42\x00"))
    ? "ok" : "not ok", " 19\n";

print "\x00\x30\x00\x42\x00" eq
	join(':', strsplit("\x30\x00\x00", "\x00\x30\x00\x42\x00\x30\x00\x00"))
   && "\x00\x30\x00\x42\x00" eq
	join(':', strsplit("\x30\x00\x00", "\x00\x30\x00\x42\x00\x30\x00\x00"))
    ? "ok" : "not ok", " 20\n";

if ($] < 5.005) {
  foreach(21..24) { print "ok $_\n"; }
}
else {
  $str = "\x00\x00\x30\x00\x00\x42\x00\x00\x30\x00\x42\x00";
  print join(':', strsplit("\x00\x30\x00\x42\x00", $str)) eq
	"\x00\x00\x30\x00\x00\x42\x00"
    ? "ok" : "not ok", " 21\n";

  print join(':', strsplit("\x00\x30\x00\x00\x00", $str)) eq $str
    ? "ok" : "not ok", " 22\n";

  print join(':', strsplit("\x00\x00\x30\x00", $str)) eq
	":\x00\x42:\x42\x00"
    ? "ok" : "not ok", " 23\n";

  print join(':', strsplit("\x00\x30\x00", $str)) eq
	"\x00:\x00\x42\x00:\x42\x00"
    ? "ok" : "not ok", " 24\n";
}

1;
__END__
