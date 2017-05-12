package String::Multibyte::EUC_JP;

use vars qw($VERSION);
$VERSION = '1.12';

+{
    charset  => 'EUC-JP',

    regexp   => '(?:[\x00-\x7F]|[\x8E\xA1-\xFE][\xA1-\xFE]|' .
	'\x8F[\xA1-\xFE][\xA1-\xFE])',

    cmpchar => sub {
	length($_[0]) <=> length($_[1]) || $_[0] cmp $_[1];
    },

    nextchar => sub {
	my $ch = shift;
	my $len = length $ch;
	if ($len < 1 || 3 < $len) {
	    return;
	}
	elsif ($len == 1) {
	    return $ch eq "\x7F"
		? "\x8E\xA1"
		: chr(ord($ch)+1);
	}
	elsif ($len == 2) {
	    my($c,$d) = unpack('CC', $ch);
	    return $ch eq "\x8E\xFE"
		? "\xA1\xA1"
		: $ch eq "\xFE\xFE"
		    ? "\x8F\xA1\xA1"
		    : $d == 0xFE
			? chr($c+1)."\xA1"
			: pack('CC', $c, $d+1);
	}
	else {
	    return if 0x8F != ord $ch;
	    my($b,$c,$d) = unpack('CCC',$ch);
	    return $ch eq "\x8F\xFE\xFE"
		? undef
		: $d == 0xFE
		    ? pack('CCC', 0x8F, $c+1, 0xA1)
		    : pack('CCC', 0x8F, $c, $d+1);
	}
    },
};

__END__

=head1 NAME

String::Multibyte::EUC_JP - internally used by String::Multibyte
for EUC-JP

=head1 SYNOPSIS

    use String::Multibyte;

    $eucjp = String::Multibyte->new('EUC_JP');
    $eucjp_length = $eucjp->length($eucjp_string);

=head1 DESCRIPTION

C<String::Multibyte::EUC_JP> is used for manipulation of strings
in EUC-JP family encodings.

Byte range of single-byte characters:
C<0x00..0x7F>.

First and second byte range of double-byte characters:
C<0xA1..0xFE>.

Legal byte range for two bytes preceded by SS3:
C<0xA1..0xFE>.

Character order (invalid code points are excluded):
C<0x00..0x7F>, C<0x8EA1..0x8EFE>, C<0xA1A1..0xFEFE>,
C<0x8FA1A1..0x8FFEFE>.

                                       EUC-JP         EUC-JISX0213
  1.  0x00..0x7F         C0/G0      ASCII          ASCII
  2.  0x8EA1..0x8EFE       G2       JIS kana       JIS kana
  3.  0xA1A1..0xFEFE       G1       JIS X 0208     JIS X 0213 plane-1
  4.  0x8FA1A1..0x8FFEFE   G3       JIS X 0212     JIS X 0213 plane-2

=head1 CAVEAT

C1 controls other than SS2/SS3 (C<0x80..0x8D> and C<0x90..0x9E>)
are not supported.

Unassigned G2 (C<0x8EE0..0x8EFE>) are now included.

=head1 SEE ALSO

L<String::Multibyte>

=cut
