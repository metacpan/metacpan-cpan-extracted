package String::Multibyte::GBK;

use vars qw($VERSION);
$VERSION = '1.12';

+{
    charset  => 'GBK',

    regexp   => '(?:[\x00-\x80]|[\x81-\xFE][\x40-\x7E\x80-\xFE])',

    cmpchar => sub { $_[0] cmp $_[1] },

    nextchar => sub {
	my $ch = shift;
	my $len = length $ch;
	if ($len == 1) {
	    return $ch eq "\x80"
		? "\x81\x40"
		: chr(ord($ch)+1);
	}
	elsif ($len == 2) {
	    my($c, $d) = unpack('CC', $ch);
	    return $ch eq "\xFE\xFE"
		? undef
		: $d == 0xFE
		    ? chr($c+1)."\x40"
		    : $d == 0x7E
			? chr($c)  ."\x80"
			: pack('CC', $c, $d+1);
	}
	else {
	    return;
	}
    },
};

__END__

=head1 NAME

String::Multibyte::GBK - internally used by String::Multibyte
for GBK

=head1 SYNOPSIS

    use String::Multibyte;

    $gbk = String::Multibyte->new('GBK');
    $gbk_length = $gbk->length($gbk_string);

=head1 DESCRIPTION

C<String::Multibyte::GBK> is used for manipulation of strings
in GBK (Guobiao Kuozhan).

Byte range of single-byte characters:
C<0x00..0x80>.

Leading byte range of double-byte characters:
C<0x81..0xFE>.

Trailing byte range of double-byte characters:
C<0x40..0x7E> and C<0x80..0xFE>.

Character order (invalid code points are excluded):
C<0x00..0x80>, C<0x8140..0xFEFE>.

=head1 CAVEAT

C<0x80> is supported in consideration of Microsoft's CP936.
(Hmmm, according to IANA Charset Registration for GBK,
GBK must be identical to CP936.)

=head1 SEE ALSO

L<String::Multibyte>

=cut
