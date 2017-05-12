package String::Multibyte::ShiftJIS;

use vars qw($VERSION);
$VERSION = '1.12';

+{
    charset  => 'Shift-JIS',

    regexp   => '(?:[\x00-\x7F\xA1-\xDF]|' .
	'[\x81-\x9F\xE0-\xFC][\x40-\x7E\x80-\xFC])',

    cmpchar => sub {
	length($_[0]) <=> length($_[1]) || $_[0] cmp $_[1];
    },

    nextchar => sub {
	my $ch = shift;
	my $len = length $ch;
	if ($len < 1 || 2 < $len) {
	    return undef;
	}
	elsif ($len == 1) {
	    return $ch eq "\x7F"
		? "\xA1"
		: $ch eq "\xDF"
		    ? "\x81\x40"
		    : chr(ord($ch)+1);
	}
	else {
	    my($c,$d) = unpack('CC',$ch);
	    return $ch eq "\x9F\xFC"
		? "\xE0\x40"
		: $ch eq "\xFC\xFC"
		    ? undef
		    : $d == 0xFC
			? chr($c+1)."\x40"
			: $d == 0x7E
			    ? chr($c)  ."\x80"
			    : pack('CC', $c, $d+1);
	}
    },
};

__END__

=head1 NAME

String::Multibyte::ShiftJIS - internally used by String::Multibyte
for Shift-JIS

=head1 SYNOPSIS

    use String::Multibyte;

    $sjis = String::Multibyte->new('ShiftJIS');
    $sjis_length = $sjis->length($sjis_string);

=head1 DESCRIPTION

C<String::Multibyte::ShiftJIS> is used for manipulation of strings
in Shift-JIS family encodings.

Byte range of single-byte characters:
C<0x00..0x7F> and C<0xA1..0xDF>.

Leading byte range of double-byte characters:
C<0x81..0x9F> and C<0xE0..0xFC>.

Trailing byte range of double-byte characters:
C<0x40..0x7E> and C<0x80..0xFC>.

Character order (invalid code points are excluded):
C<0x00..0x7F>, C<0xA1..0xDF>, C<0x8140..0x9FFC>,
C<0xE040..0xFCFC>.

=head1 CAVEAT

C<0xF040..0xFCFC> are included.

C<0x80>, C<0xA0>, and C<0xFD..0xFF> are not supported.

For Shift_JISX0213, row 8 of the plane 2, C<0xF09F..0xF0FC>,
is simply arranged in the binary order
(This module is not aware of the JIS X 0213 order).
Then, row 1 (C<0xF040>) E<lt> row 8 (C<0xF09F>) E<lt> row 3 (C<0xF140>) ...

=head1 SEE ALSO

L<String::Multibyte>

=cut
