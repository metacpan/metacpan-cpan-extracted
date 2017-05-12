
BEGIN { $| = 1; print "1..52\n"; }
END {print "not ok 1\n" unless $loaded;}
use String::Multibyte;
$^W = 1;
$loaded = 1;
print "ok 1\n";

$sjis  = String::Multibyte->new('ShiftJIS',1);
$euc   = String::Multibyte->new('EUC',1);
$utf8  = String::Multibyte->new('UTF8',1);

print $sjis->substr("\x81\x40\xAD\x40", 1) eq "\xAD\x40"
   && $euc ->substr("\xA1\xA1\x20\xBD\xBD",2) eq "\xBD\xBD"
   && $utf8->substr("\xC2\xA0\xEF\xBD\xBF\x60",1,1) eq "\xEF\xBD\xBF"
  ? "ok" : "not ok", " ", ++$loaded, "\n";

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
sub undefstr ($) {
   asc2str(shift, 'undef');
}

#####

@ran_char = (0xFF10, 0x2D, 0xFF19, 0xFF21, 0x2D, 0xFF3A, 0xFF41, 0x2D, 0xFF5A);
%ran = (
    Bytes => "0-9A-Za-z",
    EUC => "\xA3\xB0-\xA3\xB9\xA3\xC1-\xA3\xDA\xA3\xE1-\xA3\xFA",
    EUC_JP => "\xA3\xB0-\xA3\xB9\xA3\xC1-\xA3\xDA\xA3\xE1-\xA3\xFA",
    ShiftJIS => "\x82\x4F-\x82\x58\x82\x60-\x82\x79\x82\x81-\x82\x9A",
    UTF8 => pack('H*', "efbc902defbc99efbca12defbcbaefbd812defbd9a"),
    UTF16BE => pack('n*', @ran_char),
    UTF16LE => pack('v*', @ran_char),
    UTF32BE => pack('N*', @ran_char),
    UTF32LE => pack('V*', @ran_char),
    Unicode => $] < 5.008 ? "" : pack('U*', @ran_char),
);

@src_char = (0x30, 0xff11, 0xff12, 0xff13, 0x34, 0x35, 0x36, 0xff17);
%src = (
    Bytes => '01234567',
    EUC => pack('H*', '30a3b1a3b2a3b3343536a3b7'),
    EUC_JP => pack('H*', '30a3b1a3b2a3b3343536a3b7'),
    ShiftJIS => pack('H*', '308250825182523435368256'),
    UTF8 => pack('H*', '30efbc91efbc92efbc93343536efbc97'),
    UTF16BE => pack('n*', @src_char),
    UTF16LE => pack('v*', @src_char),
    UTF32BE => pack('N*', @src_char),
    UTF32LE => pack('V*', @src_char),
    Unicode => $] < 5.008 ? ""  : pack('U*', @src_char),
);

%rep = (
    Bytes => 'RE',
    EUC => "\xa3\xd2\xa3\xc5",
    EUC_JP => "\xa3\xd2\xa3\xc5",
    ShiftJIS => "\x82\x71\x82\x64",
    UTF8 => "\xef\xbc\xb2\xef\xbc\xa5",
    UTF16BE => pack('n*', 0xff32, 0xff25),
    UTF16LE => pack('v*', 0xff32, 0xff25),
    UTF32BE => pack('N*', 0xff32, 0xff25),
    UTF32LE => pack('V*', 0xff32, 0xff25),
    Unicode => $] < 5.008 ? ""  : pack('U*', 0xff32, 0xff25),
);

#####

for $cs (qw/Bytes EUC EUC_JP ShiftJIS
	UTF8 UTF16BE UTF16LE UTF32BE UTF32LE Unicode/) {
    if ($cs eq 'Unicode' && $] < 5.008) {
	for (1..5) { print("ok ", ++$loaded, "\n"); }
	next;
    }
    $mb = String::Multibyte->new($cs,1);

    $alnumZ2H = $mb->trclosure($ran{$cs}, asc2str($cs, $ran{Bytes}));

    $str = $src{Bytes};
    $zen = $src{$cs};

    $NG = 0;
    for $i (-10..10) {
	next if 5.004 > $] && $i < -8;
	local $^W = 0;
	$s = substr($str,$i);
	$t = $mb->substr($zen,$i);
	$s = "undef" if ! defined $s;
	$t = undefstr($cs) if ! defined $t;
	++$NG unless $s eq str2asc($cs, &$alnumZ2H($t));
    }
    print ! $NG ? "ok" : "not ok", " ", ++$loaded, "\n";

    $NG = 0;
    for $i (-10..10) {
	next if 5.004 > $] && $i < -8;
	for $j (undef, -10..10) {
	    local $^W = 0;
	    $s = substr($str,$i,$j);
	    $t = $mb->substr($zen,$i,$j);
	    $s = "undef" if ! defined $s;
	    $t = undefstr($cs) if ! defined $t;
	    ++$NG unless $s eq str2asc($cs, &$alnumZ2H($t));
	}
    }
    print ! $NG ? "ok" : "not ok", " ", ++$loaded, "\n";

    $NG = 0;
    for $i (-8..8) {
	local $^W = 0;
	$s = $str;
	$t = $zen;
	substr($s,$i) = $rep{Bytes};
	${ $mb->substr(\$t,$i) } = $rep{$cs};
	++$NG unless $s eq str2asc($cs, &$alnumZ2H($t));
    }
    print ! $NG ? "ok" : "not ok", " ", ++$loaded, "\n";

    $NG = 0;
    for $i (-8..8) {
	for $j (undef,-10..10) {
	    local $^W = 0;
	    $s = $str;
	    $t = $zen;
	    substr($s,$i,$j) = $rep{Bytes};
	    ${ $mb->substr(\$t,$i,$j) } = $rep{$cs};
	    ++$NG unless $s eq str2asc($cs, &$alnumZ2H($t));
	}
    }
    print ! $NG ? "ok" : "not ok", " ", ++$loaded, "\n";

    $NG = 0;
    for $i (-8..8) {
	last if 5.005 > $];
	for $j (-10..10) {
	    local $^W = 0;
	    $s = $str;
	    $t = $zen;
	    $core = ''; # avoid "used only once"
	    eval q{ $core = substr($s,$i,$j, $rep{Bytes}) };
	    $mbcs = $mb->substr($t,$i,$j,$rep{$cs});
	    ++$NG unless $s eq str2asc($cs, &$alnumZ2H($t));
	    ++$NG unless $core eq str2asc($cs, &$alnumZ2H($mbcs));
	}
    }
    print ! $NG ? "ok" : "not ok", " ", ++$loaded, "\n";
}

1;
__END__

