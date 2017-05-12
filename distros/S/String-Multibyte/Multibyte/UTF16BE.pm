package String::Multibyte::UTF16BE;

use vars qw($VERSION);
$VERSION = '1.12';

+{
    charset  => 'UTF-16BE',

    regexp   => '(?:[\xD8-\xDB][\x00-\xFF][\xDC-\xDF][\x00-\xFF]|' .
	'[\x00-\xD7\xE0-\xFF][\x00-\xFF])',

    cmpchar => sub {
	length($_[0]) <=> length($_[1]) || $_[0] cmp $_[1];
    },

    nextchar => sub {
	my $ch = shift;
	my $len = length $ch;
	if ($len == 2) {
	    return $ch eq "\xD7\xFF"
		? "\xE0\x00"
		: $ch eq "\xFF\xFF"
		    ? "\xD8\x00\xDC\x00"
		    : pack('n', 1 + unpack 'n', $ch);
	}
	elsif ($len == 4) {
	    my($hi,$lo) = unpack('nn', $ch);
	    return $ch eq "\xDB\xFF\xDF\xFF"
		? undef
		: $lo == 0xDFFF
		    ? pack('nn', $hi+1, 0xDC00)
		    : pack('nn', $hi, $lo+1);
	}
	return undef;
    },

    hyphen => "\x00-",
    escape => "\x00\\",
};

__END__

=head1 NAME

String::Multibyte::UTF16BE - internally used
by String::Multibyte for UTF-16BE

=head1 SYNOPSIS

    use String::Multibyte;

    $utf16be = String::Multibyte->new('UTF16BE');
    $utf16be_length = $utf16be->length($utf16be_string);

=head1 DESCRIPTION

C<String::Multibyte::UTF16BE> is used for manipulation of strings in UTF-16BE.

Character order: C<U+00..U+D7FF>, C<U+E000..U+10FFFF>.

=head1 CAVEAT

Surrogate characters C<U+D800..U+DFFF> are excluded.

A hyphen for a character range also must be
properly encoded (i.e. C<"\x00\x2D">).

=head1 SEE ALSO

L<String::Multibyte>

=cut
