package String::Multibyte::Unicode;

require 5.008;
use vars qw($VERSION);
$VERSION = '1.12';

+{
    charset  => 'Unicode',
    regexp   => qr/./s,
    nextchar => sub { pack 'U', 1 + unpack('U', $_[0]) },
    cmpchar  => sub { $_[0] cmp $_[1] },
};

__END__

=head1 NAME

String::Multibyte::Unicode - internally used by String::Multibyte
for Unicode (Perl's internal format)

=head1 SYNOPSIS

    use String::Multibyte;

    $uni = String::Multibyte->new('Unicode');
    $unicode_length = $uni->length($unicode_string);

=head1 DESCRIPTION

C<String::Multibyte::Unicode> is used for manipulation of strings
in Perl's internal format for Unicode.

=head1 CAVEAT

This module requires Perl 5.8.0 or later.

Surrogates, C<U+D800..U+DFFF>, and other non-characters may be included
in a character range, but may be ignored, warned, or croaked,
by the C<CORE::> Unicode support.

=head1 SEE ALSO

L<String::Multibyte>

=cut
