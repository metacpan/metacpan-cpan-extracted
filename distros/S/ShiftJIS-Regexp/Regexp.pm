package ShiftJIS::Regexp;
use strict;
use Carp;

use vars qw($VERSION $PACKAGE @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION = '1.03';
$PACKAGE = 'ShiftJIS::Regexp'; #__PACKAGE__

use vars qw(%Err %Re $Char $PadA $PadG $PadGA);
use ShiftJIS::Regexp::Class;
use ShiftJIS::Regexp::Const qw(%Err %Re $Char $PadA $PadG $PadGA);

require Exporter;
@ISA = qw(Exporter);

%EXPORT_TAGS = (
    're'    => [qw(re mkclass rechar)],
    'op'    => [qw(match replace)],
    'split' => [qw(jsplit splitchar splitspace)],
);
$EXPORT_TAGS{all} = [ map @$_, values %EXPORT_TAGS ];
@EXPORT_OK   = @{ $EXPORT_TAGS{all} };
@EXPORT      = ();

my(%Cache);

sub getReCache { wantarray ? %Cache : \%Cache }

sub re ($;$) {
    my($flag);
    my $pat = shift;
    my $mod = shift || '';
    if ($pat =~ s/^ (\^|\\[AG]|) \(\? ([a-zA-Z]+) \) /$1/x) {
	$mod .= $2;
    }

    my $s = $mod =~ /s/;
    my $m = $mod =~ /m/;
    my $x = $mod =~ /x/;
    my $h = $mod =~ /h/;

    if ($mod =~ /o/ && defined $Cache{$pat}{$mod}) {
	return $Cache{$pat}{$mod};
    }

    my $res = $m && $s ? '(?ms)' : $m ? '(?m)' : $s ? '(?s)' : '';
    my $tmppat = $pat;

    for ($tmppat) {
	while (length) {
	    if (s/^(\(\?[p?]?\{)//) { # (?{}), (??{}) and (?p{})
		$res .= $1;
		my $count = 1;
		while ($count && length) {
		    if (s/^(\x5C[\x00-\xFC])//) {
			$res .= $1;
			next;
		    }
		    if (s/^([^\{\}\\]+)//) {
			$res .= $1;
			next;
		    }
		    if (s/^\{//) {
			++$count;
			$res .= '{';
			next;
		    }
		    if (s/^\}//) {
			--$count;
			$res .= '}';
			next;
		    }
		    croak $Err{Code};
		}
		if (s/^\)//) {
		    $res .= ')';
		    next;
		}
		croak $Err{Code};
	    }

	    if (s/^\x5B(\^?)//) {
		my $not = $1;
		my $class = parse_class(\$_, $mod);
		$res .= $not ? "(?:(?!$class)$Char)" : $class;
		next;
	    }

	    if (s/^\\([.*+?^$|\\()\[\]\{\}])//) { # backslashed meta chars
		$res .= '\\'.$1;
		next;
	    }
	    if (s|^\\?(['"/])||) { # <'>, <">, </> should be backslashed.
		$res .= '\\'.$1;
		next;
	    }
	    if ($x && s/^\s+//) { # skip whitespace
		next;
	    }
	    if (s/^\.//) { # dot
		$res .= $s ? $Re{'\j'} : $Re{'\J'};
		next;
	    }
	    if (s/^\^//) { # begin
		$res .= '(?:^)';
		next;
	    }
	    if (s/^\$//) { # end
		$res .= '(?:$)';
		next;
	    }
	    if (s/^\\z//) { # \z (Perl 5.003 doesn't have this)
		$res .= '(?!\n)\Z';
		next;
	    }
	    if (s/^\\([dDwWsSCjJ])//) { # class
		$res .= $Re{ "\\$1" };
		next;
	    }
	    if (s/^\\([pP])//) { # prop
	        my $key = parse_prop($1, \$_);
		if (defined $Re{$key}) {
		    $res .= $Re{$key};
		} else {
		    croak sprintf($Err{Undef}, $key);
		}
		next;
	    }
	    if (s/^\\([R])//) { # regex
	        my $key = parse_regex($1, \$_);
		if (defined $Re{$key}) {
		    $res .= $Re{$key};
		} else {
		    croak sprintf($Err{Undef}, $key);
		}
		next;
	    }
	    if (s/^\\([0-7][0-7][0-7]?)//) {
		$res .= rechar(chr oct $1, $mod);
		next;
	    }
	    if (s/^\\0//) {
		$res .='\\x00';
		next;
	    }
	    if (s/^\\c([\x00-\x7F])//) {
		$res .= rechar(chr(ord(uc $1) ^ 64), $mod);
		next;
	    }
	    if (s/^\\x([0-9A-Fa-f][0-9A-Fa-f])//) {
		$res .= rechar(chr hex $1, $mod);
		next;
	    }
	    if (s/^\\x\{([0-9A-Fa-f][0-9A-Fa-f])([0-9A-Fa-f][0-9A-Fa-f])\}//) {
		$res .= rechar(chr(hex $1).chr(hex $2), $mod);
		next;
	    }
	    if (s/^\\([A-Za-z])//) {
		$res .= '\\'. $1;
		next;
	    }
	    if (s/^(\(\?[a-z\-\s]+)//) {
		$res .= $1;
		next;
	    }
	    if (s/^\\([1-9])//) {
		$res .= $h ? '\\'. ($1+1) : '\\'. $1;
		next;
	    }
	    if (s/^([\x21-\x40\x5B\x5D-\x60\x7B-\x7E])//) {
		$res .= $1;
		next;
	    }
	    if ($_ eq '\\') {
		croak $Err{backtips};
	    }
	    if (s/^\\?($Char)//o) {
		$res .= rechar($1, $mod);
		next;
	    }
	    croak sprintf($Err{oddTrail}, ord);
	}
    }
    return $mod =~ /o/ ? ($Cache{$pat}{$mod} = $res) : $res;
}



sub dst ($) {
    my $str = shift;
    my $res = '';
    for ($str) {
	while (length) {
	    if (s/^\\\\//) {
		$res .= '\\\\';
		next;
	    }
	    if (s/^\\?\///) {
		$res .= '\\/';
		next;
	    }
	    if (s/^\$([1-8])//) {
		$res .= '${' . ($1 + 1) . '}';
		next;
	    }
	    if (s/^\$\{([1-8])\}//) {
		$res .= '${' . ($1 + 1) . '}';
		next;
	    }
	    if (s/^\\([0-7][0-7][0-7])//) {
		$res .= "\\$1";
		next;
	    }
	    if (s/^\\([0-7][0-7])//) {
		$res .= "\\0$1";
		next;
	    }
	    if (s/^\\x([0-9A-Fa-f][0-9A-Fa-f])//) {
		$res .= "\\x$1";
		next;
	    }
	    if (s/^\\x\{([0-9A-Fa-f][0-9A-Fa-f])([0-9A-Fa-f][0-9A-Fa-f])\}//) {
		$res .= '\\x' . $1 . '\\x' . $2;
		next;
	    }
	    if (s/^\\0//) {
		$res .='\\x00';
		next;
	    }
	    if (s/^\\([A-Za-z])//) {
		$res .= '\\'. $1;
		next;
	    }
	    if (s/^\\?([\x81-\x9F\xE0-\xFC][\x40-\x7E\x80-\xFC])//) {
		$res .= quotemeta($1);
		next;
	    }
	    if (s/^\\?([\x00-\x7F\xA1-\xDF])//) {
		$res .= $1;
		next;
	    }
	    croak sprintf($Err{oddTrail}, ord);
	}
    }
    return $res;
}

sub match ($$;$) {
    my $str = $_[0];
    my $mod = $_[2] || '';
    my $pat = re($_[1], $mod);
    if ($mod =~ /g/) {
	my $fore = $mod =~ /z/ || '' =~ /$pat/ ? $PadGA : $PadG;
	$str =~ /$fore(?:$pat)/g;
    } else {
	$str =~ /$PadA(?:$pat)/;
    }
}


sub replace ($$$;$) {
    my $str = $_[0];
    my $dst = dst($_[2]);
    my $mod = $_[3] || '';
    my $pat = re($_[1], 'h'.$mod);
    if ($mod =~ /g/) {
	my $fore = $mod =~ /z/ || '' =~ /$pat/ ? $PadGA : $PadG;
	if (ref $str) {
	    eval "\$\$str =~ s/($fore)(?:$pat)/\${1}$dst/g";
	} else {
	    eval   "\$str =~ s/($fore)(?:$pat)/\${1}$dst/g";
	    $str;
	}
    } else {
	if (ref $str) {
	    eval "\$\$str =~ s/($PadA)(?:$pat)/\${1}$dst/";
	} else {
	    eval   "\$str =~ s/($PadA)(?:$pat)/\${1}$dst/";
	    $str;
	}
   }
}


#
# splitchar(STRING; LIMIT)
#
sub splitchar ($;$) {
    my $str = shift;
    my $lim = shift || 0;

    return wantarray ? () : 0 if $str eq '';
    return wantarray ? ($str) : 1 if $lim == 1;

    my(@ret);
    if ($lim > 1) {
	while ($str =~ s/($Char)//o) {
	    push @ret, $1;
	    last if @ret >= $lim - 1;
	}
	push @ret, $str;
    } else {
	@ret = $str =~ /$Char/go;
	push @ret, '' if $lim < 0;
    }
    return @ret;
}

#
# splitspace(STRING; LIMIT)
#
sub splitspace ($;$) {
    my $str = shift;
    my $lim = shift || 0;
    return wantarray ? () : 0 if $str eq '';

    my @ret;
    if (0 < $lim) {
	$str =~ s/^(?:[ \n\r\t\f]|\x81\x40)+//;
	@ret = jsplit('(?o)[ \n\r\t\f\x{8140}]+', $str, $lim)
    } else {
	$str =~ s/\G($Char*?)\x81\x40/$1 /go;
	@ret = split(' ', $str, $lim);
    }
    return @ret;
}

#
# jsplit(PATTERN, STRING; LIMIT)
#
sub jsplit ($$;$) {
    my $thing = shift;
    my $str = shift;
    my $lim = shift || 0;

    return splitspace($str, $lim) if !defined $thing;

    my $pat = 'ARRAY' eq ref $thing
	? re($$thing[0], $$thing[1])
	: re($thing);

    return splitchar($str, $lim) if $pat eq '';
    return wantarray ? () : 0 if $str eq '';
    return wantarray ? ($str) : 1 if $lim == 1;

    my $cnt = 0;
    my(@mat, @ret);
    while (@mat = $str =~ /^($Char*?)($pat)/) {
	if ($mat[0] eq '' && $mat[1] eq '') {
	    @mat = $str =~ /^($Char)($pat)/;
	    $str =~ s/^$Char$pat//;
	} else {
	    $str =~ s/^$Char*?$pat//;
	}
	if (@mat) {
	    push @ret, shift @mat;
	    shift @mat; # $mat[1] eq $2 is to be removed.
	    push @ret, @mat;
	}
	$cnt++;
	last if ! CORE::length $str;
	last if $lim > 1 && $cnt >= $lim - 1;
    }
    push @ret, $str if $str ne '' || $lim < 0 || $cnt < $lim;
    if ($lim == 0) {
	pop @ret while defined $ret[-1] && $ret[-1] eq '';
    }
    return @ret;
}

1;
__END__
