
BEGIN { $| = 1; print "1..53\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::String qw(:kana :H2Z :Z2H toupper tolower);

$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

{
  $kigouH = '｡｢｣､･ｰﾞﾟ';
  $kigouZ = '。「」、・ー゛゜';
  $kigouA = $kigouZ.$kigouH;

  foreach $ary (
    [ \&kataH2Z,  $kigouZ.$kigouZ,  8 ],
    [ \&kanaH2Z,  $kigouZ.$kigouZ,  8 ],
    [ \&hiraH2Z,  $kigouZ.$kigouZ,  8 ],
    [ \&kataZ2H,  $kigouH.$kigouH,  8 ],
    [ \&kanaZ2H,  $kigouH.$kigouH,  8 ],
    [ \&hiraZ2H,  $kigouH.$kigouH,  8 ],
    [ \&hiXka,    $kigouZ.$kigouH,  0 ],
    [ \&hi2ka,    $kigouZ.$kigouH,  0 ],
    [ \&ka2hi,    $kigouZ.$kigouH,  0 ],
    [ \&spaceH2Z, $kigouZ.$kigouH,  0 ],
    [ \&spaceZ2H, $kigouZ.$kigouH,  0 ],
    [ \&toupper,  $kigouZ.$kigouH,  0 ],
    [ \&tolower,  $kigouZ.$kigouH,  0 ],
  ) {
    $str = $kigouA;
    print &{ $ary->[0] }($str) eq $ary->[1]
	? "ok" : "not ok", " ", ++$loaded, "\n";
    print $str eq $kigouA
	? "ok" : "not ok", " ", ++$loaded, "\n";
    print &{ $ary->[0] }(\$str) eq $ary->[2]
	? "ok" : "not ok", " ", ++$loaded, "\n";
    print $str eq $ary->[1]
	? "ok" : "not ok", " ", ++$loaded, "\n";
  }
}

