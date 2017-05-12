
BEGIN { $| = 1; print "1..71\n"; }
END {print "not ok 1\n" unless $loaded;}
use String::Multibyte;
$^W = 1;
$loaded = 1;
print "ok 1\n";

%Template = (
    UTF16LE => 'v*',   UTF16BE => 'n*',
    UTF32LE => 'V*',   UTF32BE => 'N*',
);
sub asc2str ($$) {
   my($cs, $str) = @_;
   return $str if ! $Template{$cs};
   return pack($Template{$cs}, unpack 'C*', $str);
}
sub str2asc ($$) {
   my($cs, $str) = @_;
   return $str if ! $Template{$cs};
   return pack('C*', unpack $Template{$cs}, $str);
}
sub list2str {
    my $cs = shift;
    my $lt = asc2str($cs, '<');
    my $gt = asc2str($cs, '>');
    return @_ ? join('', map "$lt$_$gt", @_) : '';
}

#####

@ran_char = (0xFF21,0x2D,0xFF3A,0xFF41,0x2D,0xFF5A,0x3000,0xFF20,0xFF1D);
%ran = (
    Bytes =>   "A-Za-z\x20\x40=",
    EUC =>      "\xA3\xC1-\xA3\xDA\xA3\xE1-\xA3\xFA\xA1\xA1\xA1\xF7\xA1\xE1",
    EUC_JP =>   "\xA3\xC1-\xA3\xDA\xA3\xE1-\xA3\xFA\xA1\xA1\xA1\xF7\xA1\xE1",
    ShiftJIS => "\x82\x60-\x82\x79\x82\x81-\x82\x9A\x81\x40\x81\x97\x81\x81",
    UTF8    => pack('H*', "efbca12defbcbaefbd812defbd9ae38080efbca0efbc9d"),
    UTF16BE => pack('n*', @ran_char),
    UTF16LE => pack('v*', @ran_char),
    UTF32BE => pack('N*', @ran_char),
    UTF32LE => pack('V*', @ran_char),
    Unicode => $] < 5.008 ? "" : pack('U*', @ran_char),
);

@src_char = (0x3000, 0x3000, 0x54, 0xff48, 0x69, 0xff53, 0x3000,
   0x3000, 0x69, 0x73, 0x3000, 0x3000, 0x3000, 0x61, 0x3000, 0x3000,
   0xff34, 0xff25, 0x53, 0x54, 0x3000, 0xff1d, 0x40, 0x3000);
%src = (
    Bytes => '  This  is   a  TEST =@ ',
    EUC =>      pack('H*', 'a1a1a1a154a3e869a3f3a1a1a1a16973a1a1a1a1a1a161a1a1a1a1a3d4a3c55354a1a1a1e140a1a1'),
    EUC_JP =>      pack('H*', 'a1a1a1a154a3e869a3f3a1a1a1a16973a1a1a1a1a1a161a1a1a1a1a3d4a3c55354a1a1a1e140a1a1'),
    ShiftJIS => pack('H*', '81408140548288698293814081406973814081408140618140814082738264535481408181408140'),
    UTF8    =>  pack('H*', 'e38080e3808054efbd8869efbd93e38080e380806973e38080e38080e3808061e38080e38080efbcb4efbca55354e38080efbc9d40e38080'),
    UTF16BE =>  pack('n*', @src_char),
    UTF16LE =>  pack('v*', @src_char),
    UTF32BE =>  pack('N*', @src_char),
    UTF32LE =>  pack('V*', @src_char),
    Unicode => $] < 5.008 ? "" : pack('U*', @src_char),
);

%space = (
    Bytes => ' ',
    EUC =>      "\xa1\xa1",
    EUC_JP =>   "\xa1\xa1",
    ShiftJIS => "\x81\x40",
    UTF8 =>     "\xe3\x80\x80",
    UTF16BE =>  "\x30\x00",
    UTF16LE =>  "\x00\x30",
    UTF32BE =>  "\x00\x00\x30\x00",
    UTF32LE =>  "\x00\x30\x00\x00",
    Unicode => $] < 5.008 ? "" : pack('U*', 0x3000),
);

#####

for $cset (qw/Bytes EUC EUC_JP ShiftJIS
	UTF8 UTF16BE UTF16LE UTF32BE UTF32LE Unicode/) {
    if ($cset eq 'Unicode' && $] < 5.008) {
	for (1..7) { print("ok ", ++$loaded, "\n"); }
	next;
    }
    if ($] < 5.005 && ($cset eq 'UTF32BE' || $cset eq 'UTF32LE')) {
	for (1..7) { print("ok ", ++$loaded, "\n"); }
	next;
    }
    testsplit($cset);
}

sub testsplit {
    my $cs  = shift;
    my $mb  = String::Multibyte->new($cs,1);
    my $tr  = $mb->trclosure($ran{$cs}, asc2str($cs, $ran{Bytes}));
    my $str = $src{Bytes};
    my $zen = $src{$cs};
    my $sp  = $space{$cs};

    # splitchar in scalar context
    $NG = 0;
    for ($n = -1; $n <= 20; $n++) {
	my $core = @{[ split(//, $str, $n) ]};
	my $mbcs = $mb->strsplit('',$zen,$n);
	++$NG unless $core == $mbcs;
    }
    print !$NG ? "ok" : "not ok", " ", ++$loaded, "\n";

    # splitchar in list context
    $NG = 0;
    for ($n = -1; $n <= 20; $n++) {
	my $core = list2str('CORE', split //, $str, $n );
	my $mbcs = list2str($cs, $mb->strsplit('', $zen, $n) );
	++$NG unless $core eq str2asc($cs, &$tr($mbcs));
    }
    print !$NG ? "ok" : "not ok", " ", ++$loaded, "\n";

    # split / / in list context
    $NG = 0;
    for ($n = -1; $n <= 5; $n++) {
	my $core = @{[ split(/ /, $str, $n) ]};
	my $mbcs = $mb->strsplit($sp, $zen, $n);
	++$NG unless $core == $mbcs;
    }
    print !$NG ? "ok" : "not ok", " ", ++$loaded, "\n";

    # split / / in list context
    $NG = 0;
    for ($n = -1; $n <= 5; $n++) {
	my $core = list2str('CORE', split(/ /, $str, $n));
	my $mbcs = list2str($cs,  $mb->strsplit($sp, $zen, $n) );
	++$NG unless $core eq str2asc($cs, &$tr($mbcs));
    }
    print !$NG ? "ok" : "not ok", " ", ++$loaded, "\n";

    # splitchar of null string in scalar context
    $NG = 0;
    for ($n = -1; $n <= 20; $n++) {
	my $core = @{[ split(//, '', $n) ]};
	my $mbcs = $mb->strsplit('','',$n);
	++$NG unless $core == $mbcs;
    }
    print !$NG ? "ok" : "not ok", " ", ++$loaded, "\n";

   # splitchar of null string in list context
    $NG = 0;
    for ($n = -1; $n <= 20; $n++) {
	my $core = list2str('CORE', split //, '', $n);
	my $mbcs = list2str($cs, $mb->strsplit('','',$n));
	++$NG unless $core eq str2asc($cs, $mbcs);
    }
    print !$NG ? "ok" : "not ok", " ", ++$loaded, "\n";

    # split / /, '' in list context
    $NG = 0;
    for ($n = -1; $n <= 5; $n++) {
	my $core = list2str('CORE', split(/ /, '', $n) );
	my $mbcs = list2str($cs, $mb->strsplit($sp, '', $n) );
	++$NG unless $core eq str2asc($cs, $mbcs);
    }
    print !$NG ? "ok" : "not ok", " ", ++$loaded, "\n";
}

1;
__END__
