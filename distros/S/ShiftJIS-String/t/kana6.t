
BEGIN { $| = 1; print "1..101\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::String qw(:kana :H2Z :Z2H toupper tolower);

$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

{
  for $ary (
    [ \&kanaZ2H, qw/ ƒEJƒ@ƒEJƒBƒEJƒEJƒFƒEJƒH   ³Þ§³Þ¨³Þ³Þª³Þ«  14 / ],
    [ \&kataZ2H, qw/ ƒEJƒ@ƒEJƒBƒEJƒEJƒFƒEJƒH   ³Þ§³Þ¨³Þ³Þª³Þ«  14 / ],
    [ \&hiraZ2H, 'ƒEJƒ@ƒEJƒBƒEJƒEJƒFƒEJƒH',
                 'ƒEÞƒ@ƒEÞƒBƒEÞƒEÞƒFƒEÞƒH',  5],
    [ \&kanaZ2H, qw/ ‚¤J‚Ÿ‚¤J‚¡‚¤J‚¤J‚¥‚¤J‚§   ³Þ§³Þ¨³Þ³Þª³Þ«   9 / ],
    [ \&hiraZ2H, qw/ ‚¤J‚Ÿ‚¤J‚¡‚¤J‚¤J‚¥‚¤J‚§   ³Þ§³Þ¨³Þ³Þª³Þ«   9 / ],
    [ \&kataZ2H, '‚¤J‚Ÿ‚¤J‚¡‚¤J‚¤J‚¥‚¤J‚§',
                 '‚¤J‚Ÿ‚¤J‚¡‚¤J‚¤J‚¥‚¤J‚§',  0 ],
    [ \&kanaH2Z, qw/ ‚±‚ñ‚¿‚É‚Í ‚±‚ñ‚¿‚É‚Í   0 / ],
    [ \&kanaH2Z, qw/ ºÝÆÁÊ      ƒRƒ“ƒjƒ`ƒn   5 / ],
    [ \&kanaH2Z, qw/ Êß°Ù       ƒp[ƒ‹       3 / ],
    [ \&kanaH2Z, qw/ ÌßÛ¸Þ×ÑŒ¾Œê ƒvƒƒOƒ‰ƒ€Œ¾Œê 5 / ],
    [ \&kanaH2Z, qw/ ËÞÀÞ¸µÝ    ƒrƒ_ƒNƒIƒ“   5 / ],
    [ \&kanaH2Z, qw/ ¶ß·ß¸ß¹ßºß ƒJKƒLKƒNKƒPKƒRK 10 / ],
    [ \&kanaH2Z, qw/ ‚¦Þ¡       ‚¦JB       2 / ],
    [ \&kanaH2Z, qw/ ´Þ¡        ƒGJB       3 / ],
    [ \&kanaH2Z, qw/ A³Þ¡B      Aƒ”BB       2 / ],
    [ \&kataH2Z, qw/ ‚±‚ñ‚¿‚É‚Í ‚±‚ñ‚¿‚É‚Í   0 / ],
    [ \&kataH2Z, qw/ ºÝÆÁÊ      ƒRƒ“ƒjƒ`ƒn   5 / ],
    [ \&kataH2Z, qw/ Êß°Ù       ƒp[ƒ‹       3 / ],
    [ \&hiraH2Z, qw/ ‚±‚ñ‚¿‚É‚Í ‚±‚ñ‚¿‚É‚Í   0 / ],
    [ \&hiraH2Z, qw/ ºÝÆÁÊ      ‚±‚ñ‚É‚¿‚Í   5 / ],
    [ \&hiraH2Z, qw/ Êß°Ù       ‚Ï[‚é       3 / ],
    [ \&tolower, qw/ ‚ ‚¢‚¤‚¦ABCD‚±‚ñ‚¿‚É‚Í ‚ ‚¢‚¤‚¦abcd‚±‚ñ‚¿‚É‚Í   4 / ],
    [ \&tolower, qw/ ƒAƒ‹ƒtƒ@ƒxƒbƒg‚ðŠÜ‚Ü‚È‚¢  ƒAƒ‹ƒtƒ@ƒxƒbƒg‚ðŠÜ‚Ü‚È‚¢ 0 / ],
    [ \&tolower, qw/ Perl_Module    perl_module   2 / ],
    [ \&tolower, qw/ ‚o‚…‚’‚Œ‚ðŽg‚¤ ‚o‚…‚’‚Œ‚ðŽg‚¤ 0 / ],
  ) {
    $str = $ary->[1];
    print &{ $ary->[0] }($str)  eq $ary->[2]
	? "ok" : "not ok", " ", ++$loaded, "\n";
    print $str eq $ary->[1]
	? "ok" : "not ok", " ", ++$loaded, "\n";
    print &{ $ary->[0] }(\$str) eq $ary->[3]
	? "ok" : "not ok", " ", ++$loaded, "\n";
    print $str eq $ary->[2]
	? "ok" : "not ok", " ", ++$loaded, "\n";
  }
}

