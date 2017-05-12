package String::Multibyte::Big5Plus;

use vars qw($VERSION);
$VERSION = '1.12';

+{
    charset  => 'Big-5 Plus',

    regexp   => '(?:[\x00-\x7F]|[\x81-\xFE][\x40-\x7E\x80-\xFE])',

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
			? chr($c)."\x80"
			: pack('CC', $c, $d+1);
	}
    },
};

__END__

=head1 NAME

String::Multibyte::Big5Plus - internally used by String::Multibyte
for Big-5 Plus

=head1 SYNOPSIS

    use String::Multibyte;

    $big5p = String::Multibyte->new('Big5Plus');
    $big5p_length = $big5p->length($big5p_string);

=head1 DESCRIPTION

C<String::Multibyte::Big5Plus> is used for manipulation of strings
in Big-5 Plus.

Byte range of single-byte characters:
C<0x00..0x7F>.

Leading byte range of double-byte characters:
C<0x81..0xFE>.

Trailing byte range of double-byte characters:
C<0x40..0x7E> and C<0x80..0xFE>.

Character order (invalid code points are excluded):
C<0x00..0x7F>, C<0x8140..0xFEFE>

=head1 SEE ALSO

L<String::Multibyte>

=cut
