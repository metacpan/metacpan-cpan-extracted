package String::Multibyte::UTF32BE;

use vars qw($VERSION);
$VERSION = '1.12';

+{
    charset  => 'UTF-32BE',

    regexp   => '(?:\x00\x00[\x00-\xD7\xE0-\xFF][\x00-\xFF]|'
	  . '\x00[\x01-\x10][\x00-\xFF][\x00-\xFF])',

    cmpchar => sub { $_[0] cmp $_[1] },

    nextchar => sub {
	my $u = unpack('N', $_[0]);
	return if 0x10FFFF <= $u;
	pack('N', $u == 0xD7FF ? 0xE000 : $u + 1);
    },

    hyphen => "\x00\x00\x00-",
    escape => "\x00\x00\x00\\",
};

__END__

=head1 NAME

String::Multibyte::UTF32BE - internally used
by String::Multibyte for UTF-32BE

=head1 SYNOPSIS

    use String::Multibyte;

    $utf32be = String::Multibyte->new('UTF32BE');
    $utf32be_length = $utf32be->length($utf32be_string);

=head1 DESCRIPTION

C<String::Multibyte::UTF32BE> is used for manipulation of strings in UTF-32BE.

Character order: C<U+00..U+D7FF>, C<U+E000..U+10FFFF>.

=head1 CAVEAT

Surrogate characters C<U+D800..U+DFFF> are excluded.

A hyphen for a character range also must be
properly encoded (i.e. C<"\x00\x00\x00\x2D">).

=head1 SEE ALSO

L<String::Multibyte>

=cut
