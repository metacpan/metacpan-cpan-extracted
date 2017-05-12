package ShiftJIS::String;

use Carp;
use strict;
use vars qw($VERSION $PACKAGE @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION = '1.11';
$PACKAGE = 'ShiftJIS::String'; # __PACKAGE__

require Exporter;
@ISA = qw(Exporter);

%EXPORT_TAGS = (
    issjis => [qw/issjis/],
    string => [qw/length index rindex strspn strcspn strrev substr strsplit/],
    'span' => [qw/strspn strcspn rspan rcspan/],
    'trim' => [qw/trim ltrim rtrim/],
    'cmp'  => [qw/strcmp strEQ strNE strLT strLE strGT strGE strxfrm/],
    ctype  => [qw/toupper tolower/],
    'tr'   => [qw/mkrange strtr trclosure/],
    'kana' => [qw/hi2ka ka2hi hiXka/],
    'H2Z'  => [qw/kataH2Z kanaH2Z hiraH2Z spaceH2Z/],
    'Z2H'  => [qw/kataZ2H kanaZ2H hiraZ2H spaceZ2H/],
);

$EXPORT_TAGS{all}  = [ map @$_, values %EXPORT_TAGS ];
$EXPORT_TAGS{core} = [ map @$_, @EXPORT_TAGS{qw/issjis string cmp ctype tr/} ];

@EXPORT_OK = @{ $EXPORT_TAGS{all} };
@EXPORT = ();

my $Char = '(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x00-\xFF])';
my $White = "\t\n\r\f\x20\x81\x40";

##
## issjis(LIST)
##
sub issjis {
    for (@_) {
	my $str = $_;
	$str =~ s/[\x00-\x7F\xA1-\xDF]|
	    [\x81-\x9F\xE0-\xFC][\x40-\x7E\x80-\xFC]//gx;
	return '' if CORE::length($str);
    }
    return 1;
}

##
## length(STRING)
##
sub length ($) {
    my $str = shift;
    return 0 + $str =~ s/$Char//go;
}

##
## strrev(STRING)
##
sub strrev ($) {
    my $str = shift;
    join '', reverse $str =~ /$Char/go;
}

##
## index(STRING, SUBSTR; POSITION)
##
sub index($$;$) {
    my $cnt = 0;
    my($str, $sub) = @_;
    my $len = &length($str);
    my $pos = @_ == 3 ? $_[2] : 0;
    if ($sub eq "") {
	return $pos <= 0 ? 0 : $len <= $pos ? $len : $pos;
    }
    return -1 if $len < $pos;

    my $sublen = CORE::length($sub);
    $str =~ s/^$Char//o ? $cnt++ : croak "${PACKAGE}::index"
	while CORE::length($str) && $cnt < $pos;
    $str =~ s/^$Char//o ? $cnt++ : croak "${PACKAGE}::index"
	while CORE::length($str) && CORE::substr($str,0,$sublen) ne $sub;
    return CORE::length($str) ? $cnt : -1;
}

##
## rindex(STRING, SUBSTR; POSITION)
##
sub rindex($$;$) {
    my $cnt = 0;
    my($str, $sub) = @_;
    my $len = &length($str);
    my $pos = @_ == 3 ? $_[2] : $len;
    if ($sub eq "") {
	return $pos <= 0 ? 0 : $len <= $pos ? $len : $pos;
    }
    return -1 if $pos < 0;

    my $sublen = CORE::length($sub);
    my $ret = -1;
    while ($cnt <= $pos && CORE::length($str)) {
	$ret = $cnt if CORE::substr($str,0,$sublen) eq $sub;
	$str =~ s/^$Char//o ? $cnt++ : croak "${PACKAGE}::rindex";
    }
    return $ret;
}

##
## strspn(STRING, SEARCHLIST)
##
sub strspn($$) {
    my($str, $lst) = @_;
    my $ret = 0;
    my(%lst);
    @lst{ $lst =~ /$Char/go } = ();
    while ($str =~ /($Char)/go) {
	last if ! exists $lst{$1};
	$ret++;
    }
    return $ret;
}

##
## strcspn(STRING, SEARCHLIST)
##
sub strcspn($$) {
    my($str, $lst) = @_;
    my $ret = 0;
    my(%lst);
    @lst{ $lst=~ /$Char/go } = ();
    while ($str =~ /($Char)/go) {
	last if exists $lst{$1};
	$ret++;
    }
    return $ret;
}

##
## rspan(STRING, SEARCHLIST)
##
sub rspan($$) {
    my($str, $lst) = @_;
    my $ret = 0;
    my $cnt = 0;
    my($found, %lst);
    @lst{ $lst =~ /$Char/go } = ();
    while ($str =~ /($Char)/go) {
	$ret = $cnt if exists $lst{$1} && !$found;
	$found = exists $lst{$1};
	$cnt++;
    }
    return $found ? $ret : $cnt;
}

##
## rcspan(STRING, SEARCHLIST)
##
sub rcspan($$) {
    my($str, $lst) = @_;
    my $ret = 0;
    my $cnt = 0;
    my($found, %lst);
    @lst{ $lst =~ /$Char/go } = ();
    while ($str =~ /($Char)/go) {
	$ret = $cnt if !exists $lst{$1} && $found;
	$found = exists $lst{$1};
	$cnt++;
    }
    return !$found ? $ret : $cnt;
}

##
## ltrim(STRING; SEARCHLIST; USE_COMPLEMENT)
##
sub ltrim($;$$) {
    my($str, $lst, $c) = @_;
    $lst = $White if ! defined $lst;
    my $pos = 0;
    my(%lst);
    @lst{ $lst =~ /$Char/go } = ();
    while ($str =~ /($Char)/go) {
	last if $c ? exists $lst{$1} : ! exists $lst{$1};
	$pos += CORE::length($1);
    }
    return CORE::substr($str,$pos);
}

##
## rtrim(STRING; SEARCHLIST; USE_COMPLEMENT)
##
sub rtrim($;$$) {
    my($str, $lst, $c) = @_;
    $lst = $White if ! defined $lst;
    my $ret = 0;
    my $pos = 0;
    my($prefound, $curfound, %lst);
    @lst{ $lst=~ /$Char/go } = ();
    while ($str =~ /($Char)/go) {
	$curfound = $c ? ! exists $lst{$1} : exists $lst{$1};
	$ret = $pos if $curfound && !$prefound;
	$prefound = $curfound;
	$pos += CORE::length($1);
    }
    return CORE::substr($str, 0, $prefound ? $ret : $pos);
}

##
## trim(STRING; SEARCHLIST; USE_COMPLEMENT)
##
sub trim($;$$) {
    my($str, $lst, $c) = @_;
    rtrim(ltrim($str, $lst, $c), $lst, $c);
}


##
## substr(STRING or SCALAR REF, OFFSET; LENGTH)
## substr(SCALAR, OFFSET, LENGTH, REPLACEMENT)
##
sub substr($$;$$) {
    my($ini, $fin, $except);
    my($arg, $off, $len, $rep) = @_;
    my $str = ref $arg ? $$arg : $arg;

    my $slen = &length($str);
    $except = 1 if $slen < $off;
    if (@_ == 2) {$len = $slen - $off }
    else {
	$except = 1 if $off + $slen < 0 && $len + $slen < 0;
	$except = 1 if 0 <= $len && $off + $len + $slen < 0;
    }
    if ($except) {
	if (@_ > 3) {
	    croak "$PACKAGE outside of string in substr";
	} else { return }
    }
    $ini = $off < 0 ? $slen + $off : $off;
    $fin = $len < 0 ? $slen + $len : $ini + $len;
    $ini = 0     if $ini < 0;
    $fin = $ini  if $ini > $fin;
    $ini = $slen if $slen < $ini;
    $fin = $slen if $slen < $fin;

    my $cnt  = 0;
    my $plen = 0;
    my $clen = 0;
    while ($str =~ /($Char)/go) {
	if   ($cnt < $ini) { $plen += CORE::length($1) }
	elsif($cnt < $fin) { $clen += CORE::length($1) }
	else { last }
	$cnt++;
    }
    if (@_ > 3) {
	$_[0] = CORE::substr($str, 0,      $plen) .
	  $rep. CORE::substr($str, $plen + $clen);
    }
    return ref $arg
	? \ CORE::substr($$arg, $plen, $clen)
	:   CORE::substr($str,  $plen, $clen);
}

##
## strtr(STRING or SCALAR REF, SEARCHLIST, REPLACEMENTLIST;
##       MODIFIER, PATTERN, TOPATTERN)
##
my %Cache;

sub getStrtrCache { wantarray ? %Cache : \%Cache }

sub strtr($$$;$$$) {
    my $str = shift;
    my $coderef = (defined $_[2] && $_[2] =~ /o/)
	? ( $Cache{ join "\xFF", @_ } ||= trclosure(@_) )
	: trclosure(@_);
    &$coderef($str);
}


##
## trclosure(SEARCHLIST, REPLACEMENTLIST; MODIFIER, PATTERN, TOPATTERN)
##
sub trclosure($$;$$$)
{
    my(@fr, @to, $noxs, $r, $R, $c, $d, $s, $h, $i, %hash);
    my($fr, $to, $mod, $re, $tore) = @_;
    $mod ||= ''; # '0' is not supposed.

    $noxs = $[ <= CORE::index($mod, 'n'); # no-op in the Non-XS version.
    $h = $[ <= CORE::index($mod, 'h');
    $r = $[ <= CORE::index($mod, 'r');
    $R = $[ <= CORE::index($mod, 'R');

    if (ref $fr) {
	@fr = @$fr;
	$re = defined $re
	    ? "$re|$Char"
	    : join('|', map(quotemeta($_), @$fr), $Char);
    } else {
	$fr = mkrange($fr, $r) unless $R;
	$re = defined $re ? "$re|$Char" : $Char;
	@fr = $fr =~ /\G$re/g;
    }
    if (ref $to) {
	@to = @$to;
	$tore = defined $tore
	    ? "$tore|$Char"
	    : join('|', map(quotemeta($_), @$to), $Char);
    } else {
	$to = mkrange($to, $r) unless $R;
	$tore = defined $tore ? "$tore|$Char" : $re;
	@to = $to =~ /\G$tore/g;
    }

    $c = $[ <= CORE::index($mod, 'c');
    $d = $[ <= CORE::index($mod, 'd');
    $s = $[ <= CORE::index($mod, 's');
    my $modes = $s * 4 + $d * 2 + $c;

    for ($i = 0; $i < @fr; $i++) {
	next if exists $hash{ $fr[$i] };
	$hash{ $fr[$i] } = @to
	    ? defined $to[$i] ? $to[$i] : $d ? '' : $to[-1]
	    : $d && !$c ? '' : $fr[$i];
    }

    return
	$modes == 0 || $modes == 2 ?
	    sub { # $c: false, $d: true/false, $s: false, $mod:  0 or 2
		my $str = shift;
		my $cnt = 0; my %cnt = ();
		(ref $str ? $$str : $str) =~ s{($re)}{
		    exists $hash{$1}
			? ($h ? ++$cnt{$1} : ++$cnt, $hash{$1})
			: $1;
		}ge;
		return $h
		    ? wantarray ? %cnt : \%cnt
		    : ref $str  ? $cnt : $str;
	    } :

	$modes == 1 ?
	    sub { # $c: true, $d: false, $s: false, $mod: 1
		my $str = shift;
		my $cnt = 0; my %cnt = ();
		(ref $str ? $$str : $str) =~ s{($re)}{
		    exists $hash{$1} ? $1
			: ($h ? ++$cnt{$1} : ++$cnt, @to) ? $to[-1] : $1;
		}ge;
		return $h
		    ? wantarray ? %cnt : \%cnt
		    : ref $str  ? $cnt : $str;
	    } :

	$modes == 3 || $modes == 7 ?
	    sub { # $c: true, $d: true, $s: true/false, $mod: 3 or 7
		my $str = shift;
		my $cnt = 0; my %cnt = ();
		(ref $str ? $$str : $str) =~ s{($re)}{
		    exists $hash{$1} ? $1 : ($h ? ++$cnt{$1} : ++$cnt, '');
		}ge;
		return $h
		    ? wantarray ? %cnt : \%cnt
		    : ref $str  ? $cnt : $str;
	    } :

	$modes == 4 || $modes == 6 ?
	    sub { # $c: false, $d: true/false, $s: true, $mod: 4 or 6
		my $str = shift;
		my $cnt = 0; my %cnt = ();
		my $pre = '';
		(ref $str ? $$str : $str) =~ s{($re)}{
		    exists $hash{$1} ? ($h ? ++$cnt{$1} : ++$cnt,
			$hash{$1} eq '' || $hash{$1} eq $pre
			    ? '' : ($pre = $hash{$1})
		    ) : ($pre = '', $1);
		}ge;
		return $h
		    ? wantarray ? %cnt : \%cnt
		    : ref $str  ? $cnt : $str;
	    } :

	$modes == 5 ?
	    sub { # $c: true, $d: false, $s: true, $mod: 5
		my $str = shift;
		my $cnt = 0; my %cnt = ();
		my $pre = '';
		my $tmp;
		(ref $str ? $$str : $str) =~ s{($re)}{
		    exists $hash{$1}
			? ($pre = '', $1)
			: ($h ? ++$cnt{$1} : ++$cnt,
			    $tmp = @to ? $to[-1] : $1,
				$tmp eq $pre ? '' : ($pre = $tmp)
		    );
		}ge;
		return $h
		    ? wantarray ? %cnt : \%cnt
		    : ref $str  ? $cnt : $str;
	    } :
	    sub { croak "$PACKAGE Panic! Invalid closure in trclosure!\n" }
}


sub sjis_display ($) { # for err-msg
    my $c = shift;
    $c == 0 ? '\0' :
    $c < 0x20 || $c == 0x7F ? sprintf("\\x%02x", $c) :
    $c > 0xFF ? pack('n', $c) : chr($c);
}

sub __ord ($) { CORE::length($_[0]) > 1 ? unpack('n', $_[0]) : ord($_[0]) }

sub __expand {
    my($ini, $fin, $i, $ch, @retv);
    my($fin_f,$fin_t,$ini_f,$ini_t);
    my($fr, $to, $rev) = @_;
    if ($fr > $to) {
	if($rev){ ($fr,$to) = ($to,$fr) }
	else {
	    croak sprintf "$PACKAGE Invalid character range %s-%s",
		sjis_display($fr), sjis_display($to);
	}
    } else { $rev = 0 }
    if ($fr <= 0x7F) {
	$ini = $fr < 0x00 ? 0x00 : $fr;
	$fin = $to > 0x7F ? 0x7F : $to;
	for ($i = $ini; $i <= $fin; $i++) { push @retv, chr($i) }
    }
    if ($fr <= 0xDF) {
	$ini = $fr < 0xA1 ? 0xA1 : $fr;
	$fin = $to > 0xDF ? 0xDF : $to;
	for ($i = $ini; $i <= $fin; $i++) { push @retv, chr($i) }
    }
    $ini = $fr < 0x8140 ? 0x8140 : $fr;
    $fin = $to > 0xFCFC ? 0xFCFC : $to;
    if ($ini <= $fin) {
	($ini_f,$ini_t) = unpack 'C*', pack 'n', $ini;
	($fin_f,$fin_t) = unpack 'C*', pack 'n', $fin;
	$ini_t = 0x40 if $ini_t < 0x40;
	$fin_t = 0xFC if $fin_t > 0xFC;
	if ($ini_f == $fin_f) {
	    $ch = chr $ini_f;
	    for ($i = $ini_t; $i <= $fin_t; $i++) {
		next if $i == 0x7F;
		push @retv, $ch.chr($i);
	    }
	} else {
	    $ch = chr($ini_f);
	    for ($i = $ini_t; $i <= 0xFC; $i++) {
		next if $i == 0x7F;
		push @retv, $ch.chr($i);
	    }
	    for ($i = $ini_f+1; $i < $fin_f; $i++) {
		next if 0xA0 <= $i && $i <= 0xDF;
		$ch = chr($i);
		push @retv, map $ch.chr, 0x40..0x7E, 0x80..0xFC;
	    }
	    $ch = chr($fin_f);
	    for ($i = 0x40; $i <=  $fin_t; $i++) {
		next if $i == 0x7F;
		push @retv, $ch.chr($i);
	    }
	}
    }
    return $rev ? reverse(@retv) : @retv;
}


##
## mkrange(STRING, BOOL)
##
sub mkrange($;$) {
    my($s, @retv, $range, $min, $max);
    my($self,$rev) = @_;
    $self =~ s/^-/\\-/;
    $range = 0;
    foreach $s ($self =~ /\G(?:\\\\|\\-|$Char)/go) {
	if ($range) {
	    if    ($s eq '\\-')  { $s = '-'  }
	    elsif ($s eq '\\\\') { $s = '\\' }

	    $min = @retv ? __ord(pop(@retv)) : 1;
	    $max = __ord($s);
	    push @retv, __expand($min,$max,$rev);
	    $range = 0;
	} else {
	    if    ($s eq '-')    { $range = 1 }
	    elsif ($s eq '\\-')  { push @retv, '-' }
	    elsif ($s eq '\\\\') { push @retv, '\\'}
	    else		 { push @retv, $s  }
	}
    }
    push @retv, '-' if $range;
    wantarray ? @retv : @retv ? join('', @retv) : '';
}


##
## spaceH2Z(STRING)
##
sub spaceH2Z($) {
    my $str = shift;
    my $len = CORE::length(ref $str ? $$str : $str);
    (ref $str ? $$str : $str) =~ s/ /\x81\x40/g;
    ref $str ? abs($len - CORE::length $$str) : $str;
};

##
## spaceZ2H(STRING)
##
## tolower(STRING)  and toupper(STRING)
##
my $spaceZ2H = trclosure('　', ' ');
my $toupper  = trclosure('a-z', 'A-Z');
my $tolower  = trclosure('A-Z', 'a-z');

sub spaceZ2H($) { &$spaceZ2H(@_) }
sub toupper($)  { &$toupper(@_) }
sub tolower($)  { &$tolower(@_) }

##
## Kana Letters
##
my $kataTRE = '(?:[\xB3\xB6-\xC4\xCA-\xCE]\xDE|[\xCA-\xCE]\xDF)';
my $hiraTRE = '(?:\x82\xA4\x81\x4A)'; # 'う゛'
my $kanaTRE = "(?:$hiraTRE|$kataTRE)";

my $kataH
    = '｡｢｣､･ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ'
    . 'ﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝﾞﾟ'
    . 'ｶﾞｷﾞｸﾞｹﾞｺﾞｻﾞｼﾞｽﾞｾﾞｿﾞﾀﾞﾁﾞﾂﾞﾃﾞﾄﾞﾊﾞﾋﾞﾌﾞﾍﾞﾎﾞﾊﾟﾋﾟﾌﾟﾍﾟﾎﾟ'
    . 'ｳﾞｲｴﾜｶｹ';

my $kataZH
    = '。「」、・ヲァィゥェォャュョッーアイウエオカキクケコサシスセソタ'
    . 'チツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン゛゜'
    . 'ガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポ'
    . 'ヴヰヱヮヵヶ';

my $hiraZH
    = '。「」、・をぁぃぅぇぉゃゅょっーあいうえおかきくけこさしすせそた'
    . 'ちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわん゛゜'
    . 'がぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽ'
    . 'う゛ゐゑゎかけ';

my $kataH2Z = trclosure($kataH,          $kataZH,       'R', $kanaTRE);
my $hiraH2Z = trclosure($kataH,          $hiraZH,       'R', $kanaTRE);
my $kataZ2H = trclosure($kataZH,         $kataH,        'R', $kanaTRE);
my $kanaZ2H = trclosure($hiraZH.$kataZH, $kataH.$kataH, 'R', $kanaTRE);
my $hiraZ2H = trclosure($hiraZH,         $kataH,        'R', $kanaTRE);

my $kataZ
    = 'ヲァィゥェォャュョッアイウエオカキクケコサシスセソタ'
    . 'チツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン'
    . 'ガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポ'
    . 'ヴヰヱヮヵヶヽヾ';

my $hiraZ
    = 'をぁぃぅぇぉゃゅょっあいうえおかきくけこさしすせそた'
    . 'ちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわん'
    . 'がぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽ'
    . 'う゛ゐゑゎかけゝゞ';

my $hiXka = trclosure($kataZ.$hiraZ, $hiraZ.$kataZ, 'R', $hiraTRE);
my $hi2ka = trclosure($hiraZ, $kataZ, 'R', $hiraTRE);
my $ka2hi = trclosure($kataZ, $hiraZ, 'R', $hiraTRE);

sub kataH2Z ($) { &$kataH2Z(@_) }
sub kanaH2Z ($) { &$kataH2Z(@_) }
sub hiraH2Z ($) { &$hiraH2Z(@_) }
sub kataZ2H ($) { &$kataZ2H(@_) }
sub kanaZ2H ($) { &$kanaZ2H(@_) }
sub hiraZ2H ($) { &$hiraZ2H(@_) }
sub hiXka   ($) { &$hiXka(@_) }
sub hi2ka   ($) { &$hi2ka(@_) }
sub ka2hi   ($) { &$ka2hi(@_) }


##
## strsplit
##
sub strsplit ($$;$) {
    my $strpat = shift;
    my $str = shift;
    my $lim = shift || 0;

    return wantarray ? () : 0 if $str eq '';

    my($pat);
    if (!defined $strpat) {
	if ($lim <= 0) {
	    return @{ [ split ' ', spaceZ2H($str), $lim ] };
	}
	$str =~ s/^(?:[ \n\r\t\f]|\x81\x40)+//;
	$pat = '(?:(?:[ \n\r\t\f]|\x81\x40)+)';
    } else {
	if ($strpat eq '' && $lim <= 0) {
	    return wantarray
		? ($str =~ /$Char/go, $lim < 0 ? '' : ())
		: ($lim < 0) + &length($str);
	}
	$pat = quotemeta $strpat;
    }

    return wantarray ? ($str) : 1 if $lim == 1;

    my $cnt = 0;
    my @ret = CORE::length $pat ? ('') : ();

    if (CORE::length $pat) {
	while (($lim <= 0 || $cnt < $lim) && CORE::length($str)) {
	    if ($str =~ s/^$pat//) {
		$cnt = push @ret, '';
	    } else {
		croak("$PACKAGE Panic in strsplit") if $str !~ s/^($Char)//o;
		$ret[-1] .= $1;
	    }
	}
    } else {
	while ($cnt < $lim && CORE::length($str)) {
	    croak("$PACKAGE Panic in strsplit") unless $str =~ s/^($Char)//o;
	    $cnt = push @ret, $1;
	}
    }
    $ret[-1] .= $str if $str ne '';
    if ($lim == 0) {
	pop @ret while defined $ret[-1] && $ret[-1] eq '';
    }
    return @ret;
}

##
## strxfrm
##
sub strxfrm ($) {
    my $str = shift;
    $str =~ s/($Char)/ CORE::length $1 > 1 ? $1 : "\0".$1 /ge;
    return $str;
}

sub strcmp($$) { $_[0] eq $_[1] ? 0  : strxfrm($_[0]) cmp strxfrm($_[1]) }
sub strEQ ($$) { $_[0] eq $_[1] }
sub strNE ($$) { $_[0] ne $_[1] }
sub strLT ($$) { $_[0] eq $_[1] ? '' : strxfrm($_[0]) lt strxfrm($_[1]) }
sub strLE ($$) { $_[0] eq $_[1] ? 1  : strxfrm($_[0]) le strxfrm($_[1]) }
sub strGT ($$) { $_[0] eq $_[1] ? '' : strxfrm($_[0]) gt strxfrm($_[1]) }
sub strGE ($$) { $_[0] eq $_[1] ? 1  : strxfrm($_[0]) ge strxfrm($_[1]) }

1;

__END__
