
BEGIN { $| = 1; print "1..53\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::String qw(:kana :H2Z :Z2H toupper tolower);

$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

{
  $kanaV = '³Þ§³Þ¨³Þ³Þª³Þ«³Þ¬³Þ­³Þ®';
  $kataV = 'ƒ”ƒ@ƒ”ƒBƒ”ƒ”ƒFƒ”ƒHƒ”ƒƒƒ”ƒ…ƒ”ƒ‡';
  $hiraV = '‚¤J‚Ÿ‚¤J‚¡‚¤J‚¤J‚¥‚¤J‚§‚¤J‚á‚¤J‚ã‚¤J‚å';

  $allV = $hiraV.$kataV.$kanaV;

  foreach $ary (
    [ \&kataH2Z,  $hiraV.$kataV.$kataV,  15 ],
    [ \&kanaH2Z,  $hiraV.$kataV.$kataV,  15 ],
    [ \&hiraH2Z,  $hiraV.$kataV.$hiraV,  15 ],
    [ \&kataZ2H,  $hiraV.$kanaV.$kanaV,  15 ],
    [ \&kanaZ2H,  $kanaV.$kanaV.$kanaV,  30 ],
    [ \&hiraZ2H,  $kanaV.$kataV.$kanaV,  15 ],
    [ \&hiXka,    $kataV.$hiraV.$kanaV,  30 ],
    [ \&hi2ka,    $kataV.$kataV.$kanaV,  15 ],
    [ \&ka2hi,    $hiraV.$hiraV.$kanaV,  15 ],
    [ \&spaceH2Z, $hiraV.$kataV.$kanaV,   0 ],
    [ \&spaceZ2H, $hiraV.$kataV.$kanaV,   0 ],
    [ \&toupper,  $hiraV.$kataV.$kanaV,   0 ],
    [ \&tolower,  $hiraV.$kataV.$kanaV,   0 ],
  ) {
    $str = $allV;
    print &{ $ary->[0] }($str) eq $ary->[1]
	? "ok" : "not ok", " ", ++$loaded, "\n";
    print $str eq $allV
	? "ok" : "not ok", " ", ++$loaded, "\n";
    print &{ $ary->[0] }(\$str) eq $ary->[2]
	? "ok" : "not ok", " ", ++$loaded, "\n";
    print $str eq $ary->[1]
	? "ok" : "not ok", " ", ++$loaded, "\n";
  }
}

