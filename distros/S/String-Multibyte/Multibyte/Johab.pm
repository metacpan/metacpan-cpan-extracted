package String::Multibyte::Johab;

use vars qw($VERSION);
$VERSION = '1.12';

# Hangul Letter Next Trailing Byte
use vars qw(@HLNT %HLNT1 %HLNT2 %HLNT3);

# Hangul Syllable Next Trailing Byte
use vars qw(@HSNT %HSNT1 %HSNT2 %HSNT3);

%HLNT1 = (
	0x44, 0x46,	0x47, 0x4A,	0x50, 0x54,
	0x54, 0x61,	0x61, 0x81,	0x81, 0xA1,
	0xA1, 0xC1,	0xC1, 0xE1,	0xE1, 0x41,
    );

%HLNT2 = (
	0x41, 0x61,	0x61, 0x81,	0x81, 0xA1,
	0xA1, 0xC1,	0xC1, 0xE1,	0xE1, 0x41,
    );

%HLNT3 = (
	0x41, 0x61,	0x61, 0x81,	0x81, 0xA1,
	0xA1, 0x41,
    );

@HLNT  = (\%HLNT1, \%HLNT2, \%HLNT2, \%HLNT3);

%HSNT1 = (
	0x41, 0x61,	0x71, 0x73,	0x7D, 0x81,
	0x91, 0x93,	0x9D, 0xA1,	0xB1, 0xB3,
	0xBD, 0xC1,	0xD1, 0xD3,	0xDD, 0xE1,
	0xF1, 0xF3,	0xFD, 0x41,
    );

%HSNT2 = (
	0x51, 0x53,	0x5D, 0x61,	0x71, 0x73,
	0x7D, 0x81,	0x91, 0x93,	0x9D, 0xA1,
	0xB1, 0xB3,	0xBD, 0xC1,	0xD1, 0xD3,
	0xDD, 0xE1,	0xF1, 0xF3,	0xFD, 0x41,
    );

%HSNT3 = (
	0x51, 0x53,	0x5D, 0x61,	0x71, 0x73,
	0x7D, 0x81,	0x91, 0x93,	0x9D, 0xA1,
	0xB1, 0xB3,	0xBD, 0x41,
   );

@HSNT  = (\%HSNT1, \%HSNT2, \%HSNT2, \%HSNT3);


+{
    charset  => 'Johab',

    regexp   => '(?:[\x00-\x7F]|[\xD8-\xDE\xE0-\xF9][\x31-\x7E\x91-\xFE]|'
	. '\x84[\x44\x46\x47\x4A-\x50\x54\x61\x81\xA1\xC1\xE1]|'
	. '[\x85\x86][\x41\x61\x81\xA1\xC1\xE1]|\x87[\x41\x61\x81\xA1]|'
	. '[\x88\x8C\x90\x94\x98\x9C\xA0\xA4\xA8\xAC\xB0\xB4\xB8\xBC'
	. '\xC0\xC4\xC8\xCC\xD0][\x41\x61-\x71\x73-\x7D\x81-\x91\x93-\x9D'
	. '\xA1-\xB1\xB3-\xBD\xC1-\xD1\xD3-\xDD\xE1-\xF1\xF3-\xFD]|'
	. '[\x89\x8A\x8D\x8E\x91\x92\x95\x96\x99\x9A\x9D\x9E\xA1\xA2\xA5\xA6'
	. '\xA9\xAA\xAD\xAE\xB1\xB2\xB5\xB6\xB9\xBA\xBD\xBE\xC1\xC2\xC5\xC6'
	. '\xC9\xCA\xCD\xCE\xD1\xD2][\x41-\x51\x53-\x5D\x61-\x71\x73-\x7D'
	. '\x81-\x91\x93-\x9D\xA1-\xB1\xB3-\xBD\xC1-\xD1\xD3-\xDD\xE1-\xF1'
	. '\xF3-\xFD]|'
	. '[\x8B\x8F\x93\x97\x9B\x9F\xA3\xA7\xAB\xAF\xB3\xB7\xBB\xBF\xC3\xC7'
	. '\xCB\xCF\xD3][\x41-\x51\x53-\x5D\x61-\x71\x73-\x7D\x81-\x91'
	. '\x93-\x9D\xA1-\xB1\xB3-\xBD])',

    cmpchar => sub { $_[0] cmp $_[1] },

    nextchar => sub {
	my $ch = shift;
	my $len = length $ch;
	if ($len == 1) {
	    return $ch eq "\x7F"
		? "\x84\x44"
		: chr(ord($ch)+1);
	}
	elsif ($len == 2) {
	    return undef if $ch eq "\xF9\xFE";
	    return "\xD8\x31" if $ch eq "\xD3\xBD"; # Hangul to non-Hangul
	    return "\xE0\x31" if $ch eq "\xDE\xFE"; # gap in non-Hangul

	    my ($n, $c, $d);
	    ($c, $d) = unpack('CC', $ch);

	    if (0x84 <= $c && $c <= 0x87 && ($n = $HLNT[$c % 4]{$d}) ||
		0x88 <= $c && $c <= 0xD3 && ($n = $HSNT[$c % 4]{$d}) ) {
		return $n == 0x41
		    ? pack('CC', $c+1, $n)
		    : pack('CC', $c,   $n);
	    }
	    else {
		return $d == 0xFE
		    ? chr($c+1)."\x31"
		    : $d == 0x7E
			? chr($c)."\x91"
			: pack('CC', $c, $d+1);
	    }
	}
	else {
	    return;
	}
    },
};

__END__

=head1 NAME

String::Multibyte::Johab - internally used by String::Multibyte
for Johab

=head1 SYNOPSIS

    use String::Multibyte;

    $johab = String::Multibyte->new('Johab');
    $johab_length = $johab->length($johab_string);

=head1 DESCRIPTION

C<String::Multibyte::Johab> is used for manipulation of strings
in Johab.

Byte range of single-byte characters:
C<0x00..0x7F>.

Leading byte range of non-Hangul double-byte characters:
C<0xD8..0xDE, 0xE0..0xF9>.

Trailing byte range of non-Hangul double-byte characters:
C<0x31..0x7E, 0x91..0xFE>.

Character order (invalid code points are excluded):
C<0x00..0x7F>, C<HANGUL LETTER KIYEOK-SIOS..HANGUL SYLLABLE HIH>,
C<0xD831..0xF9FE>.

=head1 CAVEAT

C<0x7F> (DEL) is included.

=head1 SEE ALSO

L<String::Multibyte>

=cut
