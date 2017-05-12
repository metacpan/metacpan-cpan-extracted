
BEGIN { $| = 1; print "1..53\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::String qw(:kana :H2Z :Z2H toupper tolower);

$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

{
  $lo = 'abcdefghijklmnopqrstuvwxyz';
  $up = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  $sp = ' ';
  $zp = '@';
  $allSUL = "$sp$lo$zp$up$sp$lo";

  foreach $ary (
    [ \&kataH2Z,  "$sp$lo$zp$up$sp$lo",  0 ],
    [ \&kanaH2Z,  "$sp$lo$zp$up$sp$lo",  0 ],
    [ \&hiraH2Z,  "$sp$lo$zp$up$sp$lo",  0 ],
    [ \&kataZ2H,  "$sp$lo$zp$up$sp$lo",  0 ],
    [ \&kanaZ2H,  "$sp$lo$zp$up$sp$lo",  0 ],
    [ \&hiraZ2H,  "$sp$lo$zp$up$sp$lo",  0 ],
    [ \&hiXka,    "$sp$lo$zp$up$sp$lo",  0 ],
    [ \&hi2ka,    "$sp$lo$zp$up$sp$lo",  0 ],
    [ \&ka2hi,    "$sp$lo$zp$up$sp$lo",  0 ],
    [ \&toupper,  "$sp$up$zp$up$sp$up", 52 ],
    [ \&tolower,  "$sp$lo$zp$lo$sp$lo", 26 ],
    [ \&spaceH2Z, "$zp$lo$zp$up$zp$lo",  2 ],
    [ \&spaceZ2H, "$sp$lo$sp$up$sp$lo",  1 ],
  ) {
    $str = $allSUL;
    print &{ $ary->[0] }($str) eq $ary->[1]
	? "ok" : "not ok", " ", ++$loaded, "\n";
    print $str eq $allSUL
	? "ok" : "not ok", " ", ++$loaded, "\n";
    print &{ $ary->[0] }(\$str) eq $ary->[2]
	? "ok" : "not ok", " ", ++$loaded, "\n";
    print $str eq $ary->[1]
	? "ok" : "not ok", " ", ++$loaded, "\n";
  }
}

