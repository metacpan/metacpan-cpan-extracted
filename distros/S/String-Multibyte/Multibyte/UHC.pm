package String::Multibyte::UHC;

use vars qw($VERSION);
$VERSION = '1.12';

#  HANGUL SYLLABLE 11172
#  [\x81-\xA0][\x41-\x5A\x61-\x7A\x81-\xFE]   32 * 178 = 5696
#  [\xA1-\xAF][\x41-\x5A\x61-\x7A\x81-\xA0]   15 *  84 = 1260
#  [\xB0-\xC5][\x41-\x5A\x61-\x7A\x81-\xFE]   22 * 178 = 3916
#  \xC6[\x41-\x52\xA1-\xFE]                   18 +  94 =  112
#  [\xC7-\xC8][\xA1-\xFE]                      2 *  94 =  188

+{
    charset  => 'UHC',

    regexp   => '(?:[\x00-\x7F]|[\x81-\xC5][\x41-\x5A\x61-\x7A\x81-\xFE]|'
	  . '\xC6[\x41-\x52\xA1-\xFE]|[\xC7-\xFE][\xA1-\xFE])',

    cmpchar => sub { $_[0] cmp $_[1] },

    nextchar => sub {
	my $ch = shift;
	my $len = length $ch;
	if ($len == 1) {
	    return $ch eq "\x7F"
		? "\x81\x41"
		: chr(ord($ch)+1);
	}
	elsif ($len == 2) {
	    my($c, $d) = unpack('CC', $ch);
	    return $ch eq "\xFE\xFE"
		? undef
		: $ch eq "\xC6\x52"
		    ? "\xC6\xA1"
		    : $d == 0xFE
			? pack('CC', $c+1, $c < 0xC6 ? 0x41 : 0xA1)
			: $d == 0x5A
			    ? chr($c) ."\x61"
			    : $d == 0x7A
				? chr($c) ."\x81"
				: pack('CC', $c, $d+1);
	}
	else {
	    return;
	}
    },
};

__END__

=head1 NAME

String::Multibyte::UHC - internally used by String::Multibyte
for UHC

=head1 SYNOPSIS

    use String::Multibyte;

    $uhc = String::Multibyte->new('UHC');
    $uhc_length = $uhc->length($uhc_string);

=head1 DESCRIPTION

C<String::Multibyte::UHC> is used for manipulation of strings
in UHC (Unified Hangul Code).

Byte range of single-byte characters:
C<0x00..0x7F>.

Leading byte range of double-byte characters:
C<0x81..0xFE>.

Trailing byte range of double-byte characters:
C<0x41..0x5A>, C<0x61..0x7A>, and C<0x81..0xFE>.

Unassigned code points out of EUC-KR are disabled.

Character order (invalid code points are excluded):
C<0x00..0x7F>, C<0x8141..0xFEFE>.

=head1 SEE ALSO

L<String::Multibyte>

=cut
