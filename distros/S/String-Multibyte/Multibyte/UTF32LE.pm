package String::Multibyte::UTF32LE;

use vars qw($VERSION);
$VERSION = '1.12';

+{
    charset  => 'UTF-32LE',

    regexp   => '(?:[\x00-\xFF][\x00-\xD7\xE0-\xFF]\x00\x00|'
	  . '[\x00-\xFF][\x00-\xFF][\x01-\x10]\x00)',

    cmpchar => sub { unpack('V', $_[0]) <=> unpack('V', $_[1]) },

    nextchar => sub {
	my $u = unpack('V', $_[0]);
	return if 0x10FFFF <= $u;
	pack('V', $u == 0xD7FF ? 0xE000 :$u + 1);
    },

    hyphen => "-\x00\x00\x00",
    escape => "\\\x00\x00\x00",
};

__END__

=head1 NAME

String::Multibyte::UTF32LE - internally used
by String::Multibyte for UTF-32LE

=head1 SYNOPSIS

    use String::Multibyte;

    $utf32le = String::Multibyte->new('UTF32LE');
    $utf32le_length = $utf32le->length($utf32le_string);

=head1 DESCRIPTION

C<String::Multibyte::UTF32LE> is used for manipulation of strings in UTF-32LE.

Character order: C<U+00..U+D7FF>, C<U+E000..U+10FFFF>.

=head1 CAVEAT

Surrogate characters C<U+D800..U+DFFF> are excluded.

A hyphen for a character range also must be
properly encoded (i.e. C<"\x2D\x00\x00\x00">).

=head1 SEE ALSO

L<String::Multibyte>

=cut
