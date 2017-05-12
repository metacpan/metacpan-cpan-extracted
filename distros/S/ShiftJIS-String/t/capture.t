
BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::String qw(:all);
$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

$L82 = '(?:\x82[\x40-\xfc])';
$L83 = '(?:\x83[\x40-\xfc])';

"ＡＢＣアイウエオ" =~ /($L82+)($L83+)/;

print "ＡＢＣ" eq $1 && "アイウエオ" eq $2
  ? "ok" : "not ok", " 2\n";

print length($1) == 3 && length($2) == 5
  ? "ok" : "not ok", " 3\n";

print strrev($1) eq "ＣＢＡ" && strrev($2) eq "オエウイア"
  ? "ok" : "not ok", " 4\n";

print "ＢＣ" eq substr($1,1,2) && "ウエオ" eq substr($2,-3)
  ? "ok" : "not ok", " 5\n";

print "ABC" eq strtr($1,'Ａ-Ｚ','A-Z')
    && "アイウエオ" eq strtr($2,'Ａ-Ｚ','A-Z')
  ? "ok" : "not ok", " 6\n";

print "ＡＢＣ" eq strtr($1,'ア-ン','あ-ん')
     && "あいうえお" eq strtr($2,'ア-ン','あ-ん')
  ? "ok" : "not ok", " 7\n";

print "ＡＢＣ" eq $1 && "アイウエオ" eq $2
  ? "ok" : "not ok", " 8\n";

$str = "ＡＢＣアイウエオ％％％ＸＹＺハヒフヘホ";

$str =~ s/($L82+)($L83+)/
    strtr($1,'Ａ-Ｚ','A-Z'). strtr($2,'ア-ン','あ-ん')
/ge;

print $str eq "ABCあいうえお％％％XYZはひふへほ"
  ? "ok" : "not ok", " 9\n";

$str =~ s/($L82+)/strrev(substr($1,1,3))/ge;

print $str eq "ABCえうい％％％XYZへふひ"
  ? "ok" : "not ok", " 10\n";

$str =~ s/($L82+)/length($1)/ge;

print $str eq "ABC3％％％XYZ3"
  ? "ok" : "not ok", " 11\n";

1;
__END__
