
BEGIN { $| = 1; print "1..91\n"; }
END {print "not ok 1\n" unless $loaded;}
use String::Multibyte;
$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

sub asc2str ($$) {
   my($cs, $str) = @_;
   my $tmp =  {
      UTF16LE => 'v',   UTF32LE => 'V',
      UTF16BE => 'n',   UTF32BE => 'N',
   }->{$cs};
   $tmp and $str =~ s/([\x00-\xFF])/pack $tmp, ord $1/ge;
   return $str;
}
sub str2asc ($$) {
   my($cs, $str) = @_;
   my $re = {
      UTF16LE => '([\0-\xFF])\0',  UTF32LE => '([\0-\xFF])\0\0\0',
      UTF16BE => '\0([\0-\xFF])',  UTF32BE => '\0\0\0([\0-\xFF])',
   }->{$cs};
   $re and $str =~ s/$re/$1/g;
   return $str;
}

#####

for $cs (qw/Bytes EUC EUC_JP ShiftJIS
	UTF8 UTF16BE UTF16LE UTF32BE UTF32LE Unicode/) {
    if ($cs eq 'Unicode' && $] < 5.008) {
	for (1..9) { print("ok ", ++$loaded, "\n"); }
	next;
    }

    $mb = String::Multibyte->new($cs,1);

    $strC = "abcdefg-123456789";
    $strM = asc2str($cs, $strC);
    $cntC = $strC =~ tr'a-cd'15-7';
    $cntM = $mb->strtr(\$strM, asc2str($cs, 'a-cd'),
	asc2str($cs, '15-7'),'R');

    print $strC eq str2asc($cs, $strM) && $cntC == $cntM
	? "ok" : "not ok", " ", ++$loaded, "\n";

    @uc = ("", "I", "IA", "AIS", "ASIB","AAA");
    @lc = ("", "i", "ia", "ais", "asib","aba");
    @mod = ("", "d", "c", "cd", "s", "sd", "sc", "scd");
    $str = "THIS IS A PEN. YOU ARE A RABBIT.";
    $^W = 0;
    for $m (0..$#mod) {
	$NG = 0;
	for $i (0..$#uc) {
	    for $j(0..$#lc) {
		$strC = $str;
		$strM = asc2str($cs, $str);
		$ucP  = asc2str($cs, $uc[$i]);
		$lcP  = asc2str($cs, $lc[$j]);

		$cntC = eval "\$strC =~ tr/$uc[$i]/$lc[$j]/$mod[$m];";
		$cntM = $mb->strtr(\$strM, $ucP, $lcP, $mod[$m]);
		++$NG unless $strC eq str2asc($cs, $strM) && $cntC == $cntM;
	    }
	}
	print ! $NG ? "ok" : "not ok", " ", ++$loaded, "\n";
    }
}

1;
__END__
