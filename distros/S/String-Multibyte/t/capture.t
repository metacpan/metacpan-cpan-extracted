
BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use String::Multibyte;
$^W = 1;
$loaded = 1;
print "ok 1\n";

$mb = String::Multibyte->new('ShiftJIS',1);

#####

my $L82 = '(?:\x82[\x40-\xfc])';
my $L83 = '(?:\x83[\x40-\xfc])';

"ＡＢＣアイウエオ" =~ /($L82+)($L83+)/;

print "ＡＢＣ" eq $1 && "アイウエオ" eq $2
  ? "ok" : "not ok", " 2\n";

print $mb->length($1) == 3
   && $mb->length($2) == 5
  ? "ok" : "not ok", " 3\n";

print $mb->strrev($1) eq "ＣＢＡ"
   && $mb->strrev($2) eq "オエウイア"
  ? "ok" : "not ok", " 4\n";

print "ＢＣ" eq $mb->substr($1,1,2)
   && "ウエオ" eq $mb->substr($2,-3)
  ? "ok" : "not ok", " 5\n";

print "ABC" eq $mb->strtr($1,'Ａ-Ｚ','A-Z')
   && "アイウエオ" eq $mb->strtr($2,'Ａ-Ｚ','A-Z')
  ? "ok" : "not ok", " 6\n";

print "ＡＢＣ" eq $mb->strtr($1,'ア-ン','あ-ん')
   && "あいうえお" eq $mb->strtr($2,'ア-ン','あ-ん')
  ? "ok" : "not ok", " 7\n";

print "ＡＢＣ" eq $1 && "アイウエオ" eq $2
  ? "ok" : "not ok", " 8\n";

my $str = "ＡＢＣアイウエオ％％％ＸＹＺハヒフヘホ";

$str =~ s/($L82+)($L83+)/
    $mb->strtr($1,'Ａ-Ｚ','A-Z') . $mb->strtr($2,'ア-ン','あ-ん')
/ge;

print $str eq "ABCあいうえお％％％XYZはひふへほ"
  ? "ok" : "not ok", " 9\n";

$str =~ s/($L82+)/$mb->strrev($mb->substr($1,1,3))/ge;

print $str eq "ABCえうい％％％XYZへふひ"
  ? "ok" : "not ok", " 10\n";

$str =~ s/($L82+)/$mb->length($1)/ge;

print $str eq "ABC3％％％XYZ3"
  ? "ok" : "not ok", " 11\n";

1;
__END__
