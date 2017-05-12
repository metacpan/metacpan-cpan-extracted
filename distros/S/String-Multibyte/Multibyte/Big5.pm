package String::Multibyte::Big5;

use vars qw($VERSION);
$VERSION = '1.12';

+{
    charset  => 'Big-5',

    regexp   => '(?:[\x00-\x7F]|[\x81-\xFE][\x40-\x7E\xA1-\xFE])',

    cmpchar => sub { $_[0] cmp $_[1] },

    nextchar => sub {
	my $ch = shift;
	my $len = length $ch;
	if ($len < 1 || 2 < $len) {
	    return undef;
	}
	elsif ($len == 1) {
	    return $ch eq "\x7F"
		? "\x81\x40"
		: chr(ord($ch)+1);
	}
	else {
	    my($c, $d) = unpack('CC', $ch);
	    return $ch eq "\xFE\xFE"
		? undef
		: $d == 0xFE
		    ? chr($c+1)."\x40"
		    : $d == 0x7E
			? chr($c)."\xA1"
			: pack('CC', $c, $d+1);
	}
    },
};

__END__

=head1 NAME

String::Multibyte::Big5 - internally used by String::Multibyte
for Big-5

=head1 SYNOPSIS

    use String::Multibyte;

    $big5 = String::Multibyte->new('Big5');
    $big5_length = $big5->length($big5_string);

=head1 DESCRIPTION

C<String::Multibyte::Big5> is used for manipulation of strings
in Big-5 family encodings.

Byte range of single-byte characters:
C<0x00..0x7F>.

Leading byte range of double-byte characters:
C<0x81..0xFE>.

Trailing byte range of double-byte characters:
C<0x40..0x7E> and C<0xA1..0xFE>.

Character order (invalid code points are excluded):
C<0x00..0x7F>, C<0x8140..0xFEFE>.

=head1 CAVEAT

C<0x81..0xA0> are treated as legal leading bytes and
C<0x80..0xA0> as illegal trailing bytes,
in consideration of EUDC of Microsoft's CP950
and HKSCS of Hong Kong Government.

=head1 SEE ALSO

L<String::Multibyte>

=cut
