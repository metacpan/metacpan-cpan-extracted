package ShiftJIS::Regexp::Class;
use strict;
use Carp;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
$VERSION = '1.03';

require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(parse_class parse_prop parse_regex rechar);
@EXPORT_OK = qw();

use vars qw(%AbbrevProp %Re %Eq %Err $Char $Trail);
use ShiftJIS::Regexp::Const qw(%AbbrevProp %Re %Err $Char $Trail);
use ShiftJIS::Regexp::Equiv qw(%Eq);

my $Open = 5.005 > $] ? '(?:' : '(?-i:';
my $OpenRe = quotemeta $Open;
my $Close = ')';
my $InClassRe = '[\-0-9A-Za-z\\\\]';

sub __ord ($) {
    length($_[0]) > 1 ? unpack('n', $_[0]) : ord($_[0]);
}

sub __ord2($) {
    0xFF < $_[0] ? unpack('C*', pack 'n', $_[0]) : chr($_[0]);
}

sub rechar ($;$)
{
    my $c   = shift;
    my $mod = shift || '';
    if (1 == length $c) {
	my $o = ord $c;
	return $mod =~ /i/
	    ? 0x41 <= $o && $o <= 0x5A
		? sprintf('[\\x%02x\\x%02x]', $o, $o + 0x20)
		: 0x61 <= $o && $o <= 0x7A
		    ? sprintf('[\\x%02x\\x%02x]', $o, $o - 0x20)
		    : sprintf('\\x%02x', $o)
	    : sprintf('\\x%02x', $o)
    }
    my $d = ord substr($c,1,1); # the trail byte
    my $rechar =
	   $c =~ /^\x82([\x60-\x79])$/ && $mod =~ /I/
	? sprintf('\x82[\x%02x\x%02x]', $d, $d + 33)
	:  $c =~ /^\x82([\x81-\x9A])$/ && $mod =~ /I/
	? sprintf('\x82[\x%02x\x%02x]', $d, $d - 33)
	:  $c =~ /^\x83([\x9F-\xB6])$/ && $mod =~ /I/
	? sprintf('\x83[\x%02x\x%02x]', $d, $d + 32)
	:  $c =~ /^\x83([\xBF-\xD6])$/ && $mod =~ /I/
	? sprintf('\x83[\x%02x\x%02x]', $d, $d - 32)
	:  $c =~ /^\x84([\x40-\x4E])$/ && $mod =~ /I/
	? sprintf('\x84[\x%02x\x%02x]', $d, $d + 48)
	:  $c =~ /^\x84([\x4F-\x60])$/ && $mod =~ /I/
	? sprintf('\x84[\x%02x\x%02x]', $d, $d + 49)
	:  $c =~ /^\x84([\x70-\x7E])$/ && $mod =~ /I/
	? sprintf('\x84[\x%02x\x%02x]', $d, $d - 48)
	:  $c =~ /^\x84([\x80-\x91])$/ && $mod =~ /I/
	? sprintf('\x84[\x%02x\x%02x]', $d, $d - 49)
	:  $c =~ /^\x82([\x9F-\xDD])$/ && $mod =~ /j/
	? sprintf('\x82\x%02x|\x83\x%02x', $d, $d - 0x5F)
	:  $c =~ /^\x82([\xDE-\xF1])$/ && $mod =~ /j/
	? sprintf('\x82\x%02x|\x83\x%02x', $d, $d - 0x5E)
	:  $c =~ /^\x83([\x40-\x7E])$/ && $mod =~ /j/
	? sprintf('\x83\x%02x|\x82\x%02x', $d, $d + 0x5F)
	:  $c =~ /^\x83([\x80-\x93])$/ && $mod =~ /j/
	? sprintf('\x83\x%02x|\x82\x%02x', $d, $d + 0x5E)
	:  $c =~ /^\x81([\x52-\x53])$/ && $mod =~ /j/
	? sprintf('\x81[\x%02x\x%02x]', $d, $d + 2)
	:  $c =~ /^\x81([\x54-\x55])$/ && $mod =~ /j/
	? sprintf('\x81[\x%02x\x%02x]', $d, $d - 2)
	: sprintf('\x%02x\x%02x', unpack 'C2', $c);
    return "$Open$rechar$Close";
}


#
# parse_regex('R', ref to string)
# returning '\R{padA}' etc.
#
sub parse_regex ($$) {
    my($key, $rev);
    my $r = shift;
    for (${ $_[0] }) {
	if (s/^\{//) {
	    if (s/^([0-9A-Za-z]+)\}//) {
		$key = lc $1;
	    }
	    elsif (s/^([0-9A-Za-z]*(?![0-9A-Za-z])$Char)//o) {
		croak sprintf($Err{notAlnum}, "\\R\{$1");
	    }
	    else {
		croak sprintf($Err{notTermin}, "\\R\{$_}", '}');
	    }
	} else {
	    croak sprintf($Err{notBrace}, '\R');
	}
    }
    return "\\R\{$key\}";
}


#
# parse_prop('p' or 'P', ref to string)
# returning '\p{digit}' etc.
#
sub parse_prop ($$) {
    my($key, $rev);
    my $p = shift;
    for (${ $_[0] }) {
	if (s/^\{//) {
	    $rev = s/^\^// ? '^' : '';
	    s/^I[sn]//; # XXX, deprecated
	    if (s/^([0-9A-Za-z]+)\}//) {
		$key = lc $1;
	    }
	    elsif (s/^([0-9A-Za-z]*(?![0-9A-Za-z])$Char)//o) {
		croak sprintf($Err{notAlnum}, "\\$p\{$rev$1");
	    }
	    else {
		croak sprintf($Err{notTermin}, "\\$p\{$_}", '}');
	    }
	} else {
	    $rev = s/^\^// ? '^' : '';
	    if (s/^([\x21-\x7e])//) {
		$key = $AbbrevProp{uc $1} || $1;
	    }
	    elsif (s/^($Char)//o) {
		croak sprintf($Err{notASCII}, "\\$p$rev$1");
	    }
	    else {
		croak sprintf($Err{notTermin}, "\\$p^", '');
	    }
	}
    }
    if ($rev) {
	$p = $p eq 'p' ? 'P' : 'p';
    }
    return "\\$p\{$key\}";
}


#
# parse_posix(ref to string)
#   called after "[:" in a character class.
#   returning '\p{digit}' etc.
#
sub parse_posix ($) {
    my($key, $rev);

    for(${ $_[0] }) {
	$rev = s/^\^// ? '^' : '';
	if (s/^([0-9A-Za-z]+)\:\]//) {
	    $key = lc $1;
	}
	elsif (s/^([0-9A-Za-z]*(?![:])$Char)//o) {
	    croak sprintf($Err{notAlnum}, "[:$rev$1");
	}
	else {
	    croak sprintf($Err{notTermin}, "[:$rev$_", ":]");
	}
    }
    return $rev ? "\\P\{$key\}" : "\\p\{$key\}";
}


#
# parse_char(ref to string)
#   returning a single- or double-byte char.
#
sub parse_char ($) {
    for (${ $_[0] }) {
	if ($_ eq '\\') {
	    croak sprintf($Err{backtips});
	}
	if (s/^\\([0-7][0-7][0-7])//) {
	    return chr(oct $1);
	}
	if (s/^\\x//) {
	    if (s/^([0-9A-Fa-f][0-9A-Fa-f])//) {
		return chr(hex $1);
	    }
	    if (s/^\{([0-9A-Fa-f]{4})\}//) {
		return pack('n', hex $1);
	    }
	    if (length) {
		croak sprintf($Err{invalHex}, $_);
	    } else {
		croak sprintf($Err{notTermin}, '\x{$_', '}');
	    }
	}
	if (s/^\\c//) {
	    if (s/([\x00-\x7F])//) {
		return chr(ord(uc $1) ^ 64);
	    }
	    if (length) {
		croak sprintf($Err{invalFlw}, ord, '\c', '[\x00-\x7F]');
	    } else {
		croak sprintf($Err{notTermin}, '\c');
	    }
	}
	if (s/^\\a//) { return "\a" }
	if (s/^\\b//) { return "\b" }
	if (s/^\\e//) { return "\e" }
	if (s/^\\f//) { return "\f" }
	if (s/^\\n//) { return "\n" }
	if (s/^\\r//) { return "\r" }
	if (s/^\\t//) { return "\t" }
	if (s/^\\0//) { return "\0" }
	if (s/^\\([0-9A-Za-z])//) {
	    croak sprintf($Err{invalMch}, "\\$1");
	}
	if (s/^\\?($Char)//o) { return $1 }
	croak sprintf($Err{oddTrail}, ord);
    }
}

#
# parse_literal(string)
#   returning a literal.
#
sub parse_literal ($) {
    my $str = shift;
    my $ret = '';
    $ret .= parse_char(\$str) while length $str;
    return $ret;
}


sub expand ($$;$)
{
    my($fr, $to, $mod) = @_;
    $mod ||= '';
    my($ini, $fin, $i, $ch, @retv, @retd, $add);
    my($ini_f, $fin_f, $ini_t, $fin_t, $ini_c, $fin_c);

    if ($fr > $to) { croak sprintf($Err{revRange}, $fr, $to) }

    if ($fr <= 0x7F) {
	$ini = $fr < 0x00 ? 0x00 : $fr;
	$fin = $to > 0x7F ? 0x7F : $to;
	if ($ini == $fin) {
	    push @retv, rechar(chr($ini),$mod);
	} elsif ($ini < $fin) {
	    if ($mod =~ /i/) {
		for ($i=$ini; $i<=$fin; $i++) {
		    $add .= lc(chr $i) if 0x41 <= $i && $i <= 0x5A;
		    $add .= uc(chr $i) if 0x61 <= $i && $i <= 0x7A;
		}
	    } else { $add = '' }
	    push @retv, sprintf "[\\x%02x-\\x%02x$add]", $ini, $fin;
	}
    }

    if ($fr <= 0xDF) {
	$ini = $fr < 0xA1 ? 0xA1 : $fr;
	$fin = $to > 0xDF ? 0xDF : $to;
	if ($ini == $fin) {
	    push @retd, sprintf('\\x%2x', $ini);
	} elsif ($ini < $fin) {
	    push @retd, sprintf('[\\x%2x-\\x%2x]', $ini, $fin);
	}
    }

    $ini = $fr < 0x8140 ? 0x8140 : $fr;
    $fin = $to > 0xFCFC ? 0xFCFC : $to;
    if ($ini <= $fin) {
	($ini_f,$ini_t) = __ord2($ini);
	($fin_f,$fin_t) = __ord2($fin);
	if ($ini_f == $fin_f) {
	    push @retd,
		$ini_t == $fin_t ?
		  sprintf('\x%2x\x%2x', $ini_f, $ini_t) :
		$fin_t <= 0x7E || 0x80 <= $ini_t ?
		  sprintf('\x%2x[\x%2x-\x%2x]', $ini_f, $ini_t, $fin_t) :
		$ini_t == 0x7E && $fin_t == 0x80 ?
		  sprintf('\x%2x[\x7e\x80]', $ini_f) :
		$ini_t == 0x7E ?
		  sprintf('\x%2x[\x7e\x80-\x%2x]', $ini_f, $fin_t) :
		$fin_t == 0x80 ?
		  sprintf('\x%2x[\x%2x-\x7e\x80]', $ini_f, $ini_t) :
		sprintf('\x%2x[\x%2x-\x7e\x80-\x%2x]',$ini_f, $ini_t, $fin_t);
	} else {
	    $ini_c = $ini_t == 0x40 ? $ini_f :
		     $ini_f == 0x9F ? 0xE0 : $ini_f + 1;
	    $fin_c = $fin_t == 0xFC ? $fin_f :
		     $fin_f == 0xE0 ? 0x9F : $fin_f - 1;

	    if ($ini_t != 0x40) {
		push @retd,
		  $ini_t == 0xFC ?
		    sprintf('\x%2x\xfc', $ini_f) :
		  0x80 <= $ini_t ?
		    sprintf('\x%2x[\x%2x-\xfc]', $ini_f, $ini_t) :
		  $ini_t == 0x7E ?
		    sprintf('\x%2x[\x7e\x80-\xfc]', $ini_f) :
		    sprintf('\x%2x[\x%2x-\x7e\x80-\xfc]', $ini_f, $ini_t);
	    }
	    if ($ini_c <= $fin_c) {
		my $lead =
		    $ini_c == $fin_c
			?  sprintf('\x%2x', $ini_c) :
		    $fin_c <= 0x9F || 0xE0 <= $ini_c
			? sprintf('[\x%2x-\x%2x]', $ini_c, $fin_c) :
		    $ini_c == 0x9F && $fin_c == 0xE0
			? '[\x9f\xe0]' :
		    $ini_c == 0x9F
			? sprintf('[\x9f\xe0-\x%2x]', $fin_c) :
		    $fin_c == 0xE0
			? sprintf('[\x%2x-\x9f\xe0]', $ini_c)
			: sprintf('[\x%2x-\x9f\xe0-\x%2x]', $ini_c, $fin_c);
		push @retd, $lead.$Trail;
	    }
	    if ($fin_t != 0xFC) {
		push @retd,
		  $fin_t == 0x40 ?
		    sprintf('\x%2x\x40', $fin_f) :
		  $fin_t <= 0x7E ?
		    sprintf('\x%2x[\x40-\x%2x]', $fin_f, $fin_t) :
		  $fin_t == 0x80 ?
		    sprintf('\x%2x[\x40-\x7e\x80]', $fin_f) :
		  sprintf('\x%2x[\x40-\x7e\x80-\x%2x]', $fin_f, $fin_t);
	    }
	}
    }
    if ($mod =~ /I/) {
	foreach (
	    [0x8260, 0x8279, +33], # Full A to Z
	    [0x8281, 0x829A, -33], # Full a to z
	    [0x839F, 0x83B6, +32], # Greek Alpha to Omega
	    [0x83BF, 0x83D6, -32], # Greek alpha to omega
	    [0x8440, 0x844E, +48], # Cyrillic A to N
	    [0x8470, 0x847E, -48], # Cyrillic a to n
	    [0x844F, 0x8460, +49], # Cyrillic O to Ya
	    [0x8480, 0x8491, -49], # Cyrillic o to ya
	) {
	    if ($fr <= $_->[1] && $_->[0] <= $to) {
		($ini_f,$ini_t) = __ord2($fr <= $_->[0] ? $_->[0] : $fr);
		($fin_f,$fin_t) = __ord2($_->[1] <= $to ? $_->[1] : $to);
		push @retd, sprintf('\x%02x[\x%02x-\x%02x]',
		    $ini_f, $ini_t + $_->[2], $fin_t + $_->[2]);
	    }
	}
    }
    if ($mod =~ /j/) {
	foreach (
	    [0x829F, 0x82DD, -0x5F, 0x83], # Hiragana Small A to Mi
	    [0x82DE, 0x82F1, -0x5E, 0x83], # Hiragana Mu to N
	    [0x8340, 0x837E, +0x5F, 0x82], # Katakana Small A to Mi
	    [0x8380, 0x8393, +0x5E, 0x82], # Katakana Mu to N
	    [0x8152, 0x8153, +2,    0x81], # Katakana Iteration Marks
	    [0x8154, 0x8155, -2,    0x81], # Hiragana Iteration Marks
	) {
	    if ($fr <= $_->[1] && $_->[0] <= $to) {
		($ini_f,$ini_t) = __ord2($fr <= $_->[0] ? $_->[0] : $fr);
		($fin_f,$fin_t) = __ord2($_->[1] <= $to ? $_->[1] : $to);
		push @retd, sprintf('\x%02x[\x%02x-\x%02x]',
		    $_->[3], $ini_t + $_->[2], $fin_t + $_->[2]);
	    }
	}
    }
    return(@retv, @retd ? $Open.join('|',@retd).$Close : ());
}



#
# parse_class(ref to string, mode)
#   called after "[" at the beginning of a character class.
#   returning a byte-oriented regexp.
#
sub parse_class ($;$) {
    my(@re, $subclass);
    my $mod = $_[1] || '';
    my $state = 0; # enum: initial, char, range, subclass, last;

    for (${ $_[0] }) {
	while (length) {
	    if (s/^\]//) {
		if (@re) {
		    if ($state == 1) {
			push @re, rechar(pop(@re), $mod);
		    } elsif ($state == 2) {
			push @re, rechar(pop(@re), $mod);
			push @re, rechar('-', $mod);
		    }
		} else {
		    push(@re, ']');
		    $state = 1;
		    next;
		}
		$state = 4;
		last;
	    }
	    if (s/^\-//) {
		if ($state == 0) {
		    push(@re, '-');
		    $state = 1;
		} elsif ($state == 1) {
		    $state = 2;
		} elsif ($state == 2) {
		    push @re, expand(__ord(pop(@re)), __ord('-'), $mod);
		    $state = 0;
		} else {
		    croak sprintf($Err{invalRng}, "-$_");
		}
		next;
	    }

	    $subclass = undef;
	    if (s/^\[\://) {
		my $key = parse_posix(\$_);
		$subclass = defined $Re{$key} ? $Re{$key}
		    : croak sprintf($Err{Undef}, $key);
	    } elsif(s/^\\([pP])//) { # prop
		my $key = parse_prop($1, \$_);
		$subclass = defined $Re{$key} ? $Re{$key}
		    : croak sprintf($Err{Undef}, $key);
	    } elsif(s/^(\\[dwsDWS])//) {
		$subclass = $Re{ $1 };
	    } elsif(s/^\[=\\?([\\=])=\]//) {
		$subclass = defined $Eq{$1} ? $Eq{$1} : rechar($1,$mod);
	    } elsif(s/^\[=([^=]+)=\]//) {
		my $lit = parse_literal($1);
	        $subclass = defined $Eq{$lit} ? $Eq{$lit} : rechar($lit,$mod);
	    }

	    if (defined $subclass) {
		if ($state == 1) {
		    push @re, rechar(pop(@re), $mod);
		} elsif($state == 2) {
		    croak sprintf($Err{invalRng}, "-$_");
		}
		push @re, $subclass;
		$state = 3;
		next;
	    }

	    my $char = parse_char(\$_);
	    if ($state == 1) {
		push @re, rechar(pop(@re), $mod);
		push @re, $char;
		$state = 1;
	    } elsif ($state == 2) {
		push @re, expand(__ord(pop(@re)), __ord($char), $mod);
		$state = 0;
	    } else {
		push @re, $char;
		$state = 1;
	    }
	}
    }

    if ($state != 4) {
	croak sprintf($Err{notTermin}, "character class", ']');
    }

# contract: e.g. ('\x81\x40', '\x81[\x44-\x48]') to ('\x81[\x40\x44-\x48]').

    my ($pre, @retv, $r);
    push @retv, shift @re;
    $retv[0] =~ s/^(?:$OpenRe)? \[ ($InClassRe+) \] \)? $/[$1]/xo;
    $retv[0] =~ s/^(?:$OpenRe)? (\\x[0-9A-Fa-f]{2}) \)? $/[$1]/xo;
    $retv[0] =~ s/^(?:$OpenRe)? (\\x[0-9A-Fa-f]{2}) \[ ($InClassRe+) \] \)? $/${1}[$2]/xo;
    $retv[0] =~ s/^(?:$OpenRe)? (\\x[0-9A-Fa-f]{2}) (\\x[0-9A-Fa-f]{2}) \)? $/${1}[$2]/xo;

    foreach $r (@re) {
	$r =~ s/^(?:$OpenRe)? \[ ($InClassRe+) \] \)? $/[$1]/xo;
	$r =~ s/^(?:$OpenRe)? (\\x[0-9A-Fa-f]{2}) \)? $/[$1]/xo;
	$r =~ s/^(?:$OpenRe)? (\\x[0-9A-Fa-f]{2})
	    \[ ($InClassRe+) \] \)? $/${1}[$2]/xo;
	$r =~ s/^(?:$OpenRe)? (\\x[0-9A-Fa-f]{2})
	    (\\x[0-9A-Fa-f]{2}) \)? $/${1}[$2]/xo;

	if ("$retv[-1]|$r" =~ /^ \[($InClassRe+)\] \| \[($InClassRe+)\] $/xo) {
	    $retv[-1] = "[$1$2]";
	}
	elsif ("$retv[-1]|$r" =~ /^
	    (\\x[0-9A-Fa-f]{2}) \[($InClassRe+)\] \| \1 \[($InClassRe+)\] $/xo)
	{
	    $retv[-1] = "$1\[$2$3\]";
	}
	else {
	    $retv[-1] =~ s/^\[(\\x[0-9A-Fa-f]{2})\]$/$1/x;
	    $retv[-1] =~ s/^(\\x[0-9A-Fa-f]{2})\[(\\x[0-9A-Fa-f]{2})\]$/$1$2/x;
	    push(@retv, $r);
	}
    }

    $retv[-1] =~ s/^\[(\\x[0-9A-Fa-f]{2})\]$/$1/x;
    $retv[-1] =~ s/^(\\x[0-9A-Fa-f]{2})\[(\\x[0-9A-Fa-f]{2})\]$/$1$2/x;

    return $Open.join('|', @retv).$Close;
}

1;
__END__
