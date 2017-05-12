package String::Multibyte::GB18030;

use vars qw($VERSION);
$VERSION = '1.12';

+{
    charset  => 'GB18030',

    regexp   => '(?:[\x00-\x80]|[\x81-\xFE][\x40-\x7E\x80-\xFE]|'
	. '[\x81-\xFE][\x30-\x39][\x81-\xFE][\x30-\x39])',

    cmpchar => sub {
	length($_[0]) <=> length($_[1]) || $_[0] cmp $_[1];
    },

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
		? "\x81\x30\x81\x30"
		: $d == 0xFE
		    ? chr($c+1)."\x40"
		    : $d == 0x7E
			? chr($c)  ."\x80"
			: pack('CC', $c, $d+1);
	}
	elsif ($len == 4) {
	    my($c, $d, $e, $f) = unpack('CCCC', $ch);
	    return $f == 0x39
		    ? $e == 0xFE
			? $d == 0x39
			    ? $c == 0xFE
				? undef
				: pack('CCCC', $c+1, 0x30, 0x81, 0x30)
			    : pack('CCCC', $c, $d+1, 0x81, 0x30)
			: pack('CCCC', $c, $d, $e+1, 0x30)
		    : pack('CCCC', $c, $d, $e, $f+1);
	}
	else {
	    return;
	}
    },
};

__END__

=head1 NAME

String::Multibyte::GB18030 - internally used by String::Multibyte
for GB18030

=head1 SYNOPSIS

    use String::Multibyte;

    $gb18030 = String::Multibyte->new('GB18030');
    $gb18030_length = $gb18030->length($gb18030_string);

=head1 DESCRIPTION

C<String::Multibyte::GB18030> is used for manipulation of strings
in GB18030.

Byte range of single-byte characters:
C<0x00..0x80>.

First byte range of double-byte characters:
C<0x81..0xFE>.

Second byte range of double-byte characters:
C<0x40..0x7E> and C<0x80..0xFE>.

First and third byte range of four-byte characters:
C<0x81..0xFE>.

Second and fourth byte range of four-byte characters:
C<0x30..0x39>.

Character order (invalid code points are excluded):
C<0x00..0x80>, C<0x8140..0xFEFE>, C<0x81308130..0xFE39FE39>.

=head1 CAVEAT

C<0x80> is included for backward compatibility.

=head1 SEE ALSO

L<String::Multibyte>

=cut
