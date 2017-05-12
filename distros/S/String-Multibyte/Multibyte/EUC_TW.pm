package String::Multibyte::EUC_TW;

use vars qw($VERSION);
$VERSION = '1.12';

+{
    charset  => 'EUC-TW',

    regexp   => '(?:[\x00-\x7F]|[\xA1-\xFE][\xA1-\xFE]|' .
	'\x8E[\xA1-\xB0][\xA1-\xFE][\xA1-\xFE])',

    cmpchar => sub {
	length($_[0]) <=> length($_[1]) || $_[0] cmp $_[1];
    },

    nextchar => sub {
	my $ch = shift;
	my $len = length $ch;
	if ($len == 1) {
	    return $ch eq "\x7F"
		? "\xA1\xA1"
		: chr(ord($ch)+1);
	}
	elsif ($len == 2) {
	    my($c,$d) = unpack('CC', $ch);
	    return $ch eq "\xFE\xFE"
		    ? "\x8E\xA1\xA1\xA1"
		    : $d == 0xFE
			? chr($c+1)."\xA1"
			: pack('CC', $c, $d+1);
	}
	elsif ($len == 4) {
	    return unless $ch =~ s/^\x8E//;
	    my($b,$c,$d) = unpack('CCC',$ch);
	    return $d == 0xFE
		    ? $c == 0xFE
			? $b == 0xB0
			    ? undef
			    : pack('CCCC', 0x8E, $b+1, 0xA1, 0xA1)
			: pack('CCCC', 0x8E, $b, $c+1, 0xA1)
		    : pack('CCCC', 0x8E, $b, $c, $d+1);
	}
	else {
	    return;
	}
    },
};

__END__

=head1 NAME

String::Multibyte::EUC_TW - internally used by String::Multibyte
for EUC-TW

=head1 SYNOPSIS

    use String::Multibyte;

    $euctw = String::Multibyte->new('EUC_TW');
    $euctw_length = $euctw->length($euctw_string);

=head1 DESCRIPTION

C<String::Multibyte::EUC_TW> is used for manipulation of strings
in EUC-TW.

Byte range of single-byte characters:
C<0x00..0x7F>.

First and second byte range of double-byte characters:
C<0xA1..0xFE>.

Second byte range of four-byte characters:
C<0xA1..0xB0>.

Third and fourth byte range of four-byte characters:
C<0xA1..0xFE>.

Character order (invalid code points are excluded):
C<0x00..0x7F>, C<0xA1A1..0xFEFE>, C<0x8EA1A1A1..0x8EB0FEFE>.

=head1 CAVEAT

C1 controls other than SS2 (C<0x80..0x8D> and C<0x8F..0x9E>)
are not supported.

Plane 1 characters in G1 (e.g. C<0xA1A1>) and those in G2
(e.g. C<0x8EA1A1A1>) are not treated as equivalents.

=head1 SEE ALSO

L<String::Multibyte>

=cut
