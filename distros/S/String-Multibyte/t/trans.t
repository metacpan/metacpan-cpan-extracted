
BEGIN { $| = 1; print "1..81\n"; }
END {print "not ok 1\n" unless $loaded;}
use String::Multibyte;
$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

%ran = (
    ShiftJIS => {
	dH => "0-9", dZ => "\x82\x4F-\x82\x58",
	uH => "A-Z", uZ => "\x82\x60-\x82\x79",
	lH => "a-z", lZ => "\x82\x81-\x82\x9A",
    },
    EUC => {
	dH => "0-9", dZ => "\xA3\xB0-\xA3\xB9",
	uH => "A-Z", uZ => "\xA3\xC1-\xA3\xDA",
	lH => "a-z", lZ => "\xA3\xE1-\xA3\xFA",
    },
    EUC_JP => {
	dH => "0-9", dZ => "\xA3\xB0-\xA3\xB9",
	uH => "A-Z", uZ => "\xA3\xC1-\xA3\xDA",
	lH => "a-z", lZ => "\xA3\xE1-\xA3\xFA",
    },
    Bytes => {
	dH => "0-9", dZ => "0-9",
	uH => "A-Z", uZ => "A-Z",
	lH => "a-z", lZ => "a-z",
    },
    UTF8 => {
	dH => "0-9", dZ => "\xEF\xBC\x90-\xEF\xBC\x99",
	uH => "A-Z", uZ => "\xEF\xBC\xA1-\xEF\xBC\xBA",
	lH => "a-z", lZ => "\xEF\xBD\x81-\xEF\xBD\x9A",
    },
    UTF16BE => {
	dH => "\0\x30\0-\0\x39", dZ => "\xFF\x10\x00\x2D\xFF\x19",
	uH => "\0\x41\0-\0\x5A", uZ => "\xFF\x21\x00\x2D\xFF\x3A",
	lH => "\0\x61\0-\0\x7A", lZ => "\xFF\x41\x00\x2D\xFF\x5A",
    },
    UTF16LE => {
	dH => "\x30\0-\0\x39\0", dZ => "\x10\xFF\x2D\x00\x19\xFF",
	uH => "\x41\0-\0\x5A\0", uZ => "\x21\xFF\x2D\x00\x3A\xFF",
	lH => "\x61\0-\0\x7A\0", lZ => "\x41\xFF\x2D\x00\x5A\xFF",
    },
    UTF32BE => {
	dH => "\0\0\0\x30\0\0\0-\0\0\0\x39",
	dZ => "\0\0\xFF\x10\0\0\x00\x2D\0\0\xFF\x19",
	uH => "\0\0\0\x41\0\0\0-\0\0\0\x5A",
	uZ => "\0\0\xFF\x21\0\0\x00\x2D\0\0\xFF\x3A",
	lH => "\0\0\0\x61\0\0\0-\0\0\0\x7A",
	lZ => "\0\0\xFF\x41\0\0\x00\x2D\0\0\xFF\x5A",
    },
    UTF32LE => {
	dH => "\x30\0\0\0-\0\0\0\x39\0\0\0",
	dZ => "\x10\xFF\0\0\x2D\x00\0\0\x19\xFF\0\0",
	uH => "\x41\0\0\0-\0\0\0\x5A\0\0\0",
	uZ => "\x21\xFF\0\0\x2D\x00\0\0\x3A\xFF\0\0",
	lH => "\x61\0\0\0-\0\0\0\x7A\0\0\0",
	lZ => "\x41\xFF\0\0\x2D\x00\0\0\x5A\xFF\0\0",
    },
    Unicode => $] < 5.008 ? {}  : {
	dH => "0-9", dZ => pack('U*', 0xFF10, 0x2D, 0xFF19),
	uH => "A-Z", uZ => pack('U*', 0xFF21, 0x2D, 0xFF3A),
	lH => "a-z", lZ => pack('U*', 0xFF41, 0x2D, 0xFF5A),
    },
);

#####

for $cs (qw/Bytes EUC EUC_JP ShiftJIS
	UTF8 UTF16BE UTF16LE UTF32BE UTF32LE Unicode/) {
    if ($cs eq 'Unicode' && $] < 5.008) {
	for (1..8) { print("ok ", ++$loaded, "\n"); }
	next;
    }
    my $mb = String::Multibyte->new($cs,1);

    my $digitH = $mb->mkrange($ran{$cs}{dH});
    my $digitZ = $mb->mkrange($ran{$cs}{dZ});
    my $upperH = $mb->mkrange($ran{$cs}{uH});
    my $upperZ = $mb->mkrange($ran{$cs}{uZ});
    my $lowerH = $mb->mkrange($ran{$cs}{lH});
    my $lowerZ = $mb->mkrange($ran{$cs}{lZ});
    my $alphaH = $mb->mkrange($ran{$cs}{uH}.$ran{$cs}{lH});
    my $alphaZ = $mb->mkrange($ran{$cs}{uZ}.$ran{$cs}{lZ});
    my $alnumH = $mb->mkrange(join '', @{ $ran{$cs} }{qw/dH uH lH/});
    my $alnumZ = $mb->mkrange(join '', @{ $ran{$cs} }{qw/dZ uZ lZ/});

    my $digitZ2H = $mb->trclosure($digitZ, $digitH);
    my $upperZ2H = $mb->trclosure($upperZ, $upperH);
    my $lowerZ2H = $mb->trclosure($lowerZ, $lowerH);
    my $alphaZ2H = $mb->trclosure($alphaZ, $alphaH);
    my $alnumZ2H = $mb->trclosure($alnumZ, $alnumH);

    my $digitH2Z = $mb->trclosure($digitH, $digitZ);
    my $upperH2Z = $mb->trclosure($upperH, $upperZ);
    my $lowerH2Z = $mb->trclosure($lowerH, $lowerZ);
    my $alphaH2Z = $mb->trclosure($alphaH, $alphaZ);
    my $alnumH2Z = $mb->trclosure($alnumH, $alnumZ);

    my($H, $Z, $tr, $NG);
    $NG = 0;
    for $H ($digitH, $lowerH, $upperH) {
	for $tr ($digitZ2H, $upperZ2H,
		 $lowerZ2H, $alphaZ2H, $alnumZ2H) {
	    ++$NG unless $H eq &$tr($H);
	}
    }
    print ! $NG ? "ok" : "not ok", " ", ++$loaded, "\n";

    $NG = 0;
    for $Z ($digitZ, $lowerZ, $upperZ) {
	for $tr ($digitH2Z, $upperH2Z,
		 $lowerH2Z, $alphaH2Z, $alnumH2Z) {
	    ++$NG unless $Z eq &$tr($Z);
	}
    }
    print ! $NG ? "ok" : "not ok", " ", ++$loaded, "\n";

    print  $digitZ eq &$digitH2Z($digitH)
	&& $digitH eq &$upperH2Z($digitH)
	&& $digitH eq &$lowerH2Z($digitH)
	&& $digitH eq &$alphaH2Z($digitH)
	&& $digitZ eq &$alnumH2Z($digitH)
	  ? "ok" : "not ok", " ", ++$loaded, "\n";

    print  $upperH eq &$digitH2Z($upperH)
	&& $upperZ eq &$upperH2Z($upperH)
	&& $upperH eq &$lowerH2Z($upperH)
	&& $upperZ eq &$alphaH2Z($upperH)
	&& $upperZ eq &$alnumH2Z($upperH)
	  ? "ok" : "not ok", " ", ++$loaded, "\n";

    print  $lowerH eq &$digitH2Z($lowerH)
	&& $lowerH eq &$upperH2Z($lowerH)
	&& $lowerZ eq &$lowerH2Z($lowerH)
	&& $lowerZ eq &$alphaH2Z($lowerH)
	&& $lowerZ eq &$alnumH2Z($lowerH)
	  ? "ok" : "not ok", " ", ++$loaded, "\n";

    print  $digitH eq &$digitZ2H($digitZ)
	&& $digitZ eq &$upperZ2H($digitZ)
	&& $digitZ eq &$lowerZ2H($digitZ)
	&& $digitZ eq &$alphaZ2H($digitZ)
	&& $digitH eq &$alnumZ2H($digitZ)
	  ? "ok" : "not ok", " ", ++$loaded, "\n";

    print  $upperZ eq &$digitZ2H($upperZ)
	&& $upperH eq &$upperZ2H($upperZ)
	&& $upperZ eq &$lowerZ2H($upperZ)
	&& $upperH eq &$alphaZ2H($upperZ)
	&& $upperH eq &$alnumZ2H($upperZ)
	  ? "ok" : "not ok", " ", ++$loaded, "\n";

    print  $lowerZ eq &$digitZ2H($lowerZ)
	&& $lowerZ eq &$upperZ2H($lowerZ)
	&& $lowerH eq &$lowerZ2H($lowerZ)
	&& $lowerH eq &$alphaZ2H($lowerZ)
	&& $lowerH eq &$alnumZ2H($lowerZ)
	  ? "ok" : "not ok", " ", ++$loaded, "\n";
}

1;
__END__
