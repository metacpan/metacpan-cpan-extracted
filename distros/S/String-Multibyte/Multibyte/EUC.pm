package String::Multibyte::EUC;

use vars qw($VERSION);
$VERSION = '1.12';

+{
    charset  => 'EUC',

    regexp   => '(?:[\x00-\x7F]|[\xA1-\xFE][\xA1-\xFE])',

    cmpchar => sub { $_[0] cmp $_[1] },

    nextchar => sub {
	my $ch = shift;
	my $len = length $ch;
	if ($len < 1 || 2 < $len) {
	    return undef;
	}
	elsif ($len == 1) {
	    return $ch eq "\x7F"
		? "\xA1\xA1"
		: chr(ord($ch)+1);
	}
	else {
	    my($c, $d) = unpack('CC', $ch);
	    return $ch eq "\xFE\xFE"
		? undef
		: $d == 0xFE
		    ? chr($c+1)."\xA1"
		    : pack('CC', $c, $d+1);
	}
    },
};

__END__

=head1 NAME

String::Multibyte::EUC - internally used by String::Multibyte
for simple EUC encodings

=head1 SYNOPSIS

    use String::Multibyte;

    $euc = String::Multibyte->new('EUC');
    $euc_length = $euc->length($euc_string);

=head1 DESCRIPTION

C<String::Multibyte::EUC> is used for manipulation of strings in EUC
comprising C<C0>, C<G0>, and C<G1> in which a double-byte set is invoked.

Byte range of single-byte characters:
C<0x00..0x7F>.

Leading byte range of double-byte characters:
C<0xA1..0xFE>.

Trailing byte range of double-byte characters:
C<0xA1..0xFE>.

Character order: C<0x00..0x7F>, C<0xA1A1..0xFEFE>

=head1 CAVEAT

C1 controls, C<0x80..0x9E>, are not supported.

=head1 SEE ALSO

L<String::Multibyte>

=cut
