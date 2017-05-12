
BEGIN { $| = 1; print "1..53\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::String qw(:kana :H2Z :Z2H toupper tolower);

$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

{
  my $wiwewakake = '‚î‚ï‚ì‚©‚¯ƒAƒ”ƒƒ‘ƒŽƒ•ƒ–ƒETURS';

  foreach $ary (
    [ \&kataH2Z,  '‚î‚ï‚ì‚©‚¯ƒAƒ”ƒƒ‘ƒŽƒ•ƒ–ƒETURS',    0 ],
    [ \&kanaH2Z,  '‚î‚ï‚ì‚©‚¯ƒAƒ”ƒƒ‘ƒŽƒ•ƒ–ƒETURS',    0 ],
    [ \&hiraH2Z,  '‚î‚ï‚ì‚©‚¯ƒAƒ”ƒƒ‘ƒŽƒ•ƒ–ƒETURS',    0 ],
    [ \&kataZ2H,  '‚î‚ï‚ì‚©‚¯±³Þ²´Ü¶¹³TURS',           8 ],
    [ \&kanaZ2H,  '²´Ü¶¹±³Þ²´Ü¶¹³TURS',               13 ],
    [ \&hiraZ2H,  '²´Ü¶¹ƒAƒ”ƒƒ‘ƒŽƒ•ƒ–ƒETURS',         5 ],
    [ \&hiXka,    'ƒƒ‘ƒŽƒJƒP‚ ‚¤J‚î‚ï‚ì‚©‚¯‚¤RSTU', 17 ],
    [ \&hi2ka,    'ƒƒ‘ƒŽƒJƒPƒAƒ”ƒƒ‘ƒŽƒ•ƒ–ƒERSRS',    7 ],
    [ \&ka2hi,    '‚î‚ï‚ì‚©‚¯‚ ‚¤J‚î‚ï‚ì‚©‚¯‚¤TUTU', 10 ],
    [ \&spaceH2Z, '‚î‚ï‚ì‚©‚¯ƒAƒ”ƒƒ‘ƒŽƒ•ƒ–ƒETURS',    0 ],
    [ \&spaceZ2H, '‚î‚ï‚ì‚©‚¯ƒAƒ”ƒƒ‘ƒŽƒ•ƒ–ƒETURS',    0 ],
    [ \&toupper,  '‚î‚ï‚ì‚©‚¯ƒAƒ”ƒƒ‘ƒŽƒ•ƒ–ƒETURS',    0 ],
    [ \&tolower,  '‚î‚ï‚ì‚©‚¯ƒAƒ”ƒƒ‘ƒŽƒ•ƒ–ƒETURS',    0 ],
  ) {
    $str = $wiwewakake;
    print &{ $ary->[0] }($str) eq $ary->[1]
	? "ok" : "not ok", " ", ++$loaded, "\n";
    print $str eq $wiwewakake
	? "ok" : "not ok", " ", ++$loaded, "\n";
    print &{ $ary->[0] }(\$str) eq $ary->[2]
	? "ok" : "not ok", " ", ++$loaded, "\n";
    print $str eq $ary->[1]
	? "ok" : "not ok", " ", ++$loaded, "\n";
  }
}
