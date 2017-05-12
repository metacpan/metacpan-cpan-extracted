package String::Multibyte::UTF16LE;

use vars qw($VERSION);
$VERSION = '1.12';

+{
    charset  => 'UTF-16LE',

    regexp   => '(?:[\x00-\xFF][\xD8-\xDB][\x00-\xFF][\xDC-\xDF]|' .
	'[\x00-\xFF][\x00-\xD7\xE0-\xFF])',

    cmpchar => sub {
	length($_[0]) <=> length($_[1]) ||
	unpack('v', $_[0]) <=> unpack('v', $_[1]) ||
	reverse($_[0]) cmp reverse($_[1])
    },

    nextchar => sub {
	my $ch = shift;
	my $len = length $ch;
	if ($len == 2) {
	    return $ch eq "\xFF\xD7"
		? "\x00\xE0"
		: $ch eq "\xFF\xFF"
		    ? "\x00\xD8\x00\xDC"
		    : pack('v', 1 + unpack 'v', $ch);
	}
	elsif ($len == 4) {
	    my($hi,$lo) = unpack('vv', $ch);
	    return $ch eq "\xFF\xDB\xFF\xDF"
		? undef
		: $lo == 0xDFFF
		    ? pack('vv', $hi+1, 0xDC00)
		    : pack('vv', $hi, $lo+1);
	}
	return undef;
    },

    hyphen => "-\x00",
    escape => "\\\x00",
};

__END__

=head1 NAME

String::Multibyte::UTF16LE - internally used
by String::Multibyte for UTF-16LE

=head1 SYNOPSIS

    use String::Multibyte;

    $utf16le = String::Multibyte->new('UTF16LE');
    $utf16le_length = $utf16le->length($utf16le_string);

=head1 DESCRIPTION

C<String::Multibyte::UTF16LE> is used for manipulation of strings in UTF-16LE.

Character order: C<U+00..U+D7FF>, C<U+E000..U+10FFFF>.

=head1 CAVEAT

Surrogate characters C<U+D800..U+DFFF> are excluded.

A hyphen for a character range also must be
properly encoded (i.e. C<"\x2D\x00">).

=head1 SEE ALSO

L<String::Multibyte>

=cut
