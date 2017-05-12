package String::Dump;

use 5.006;
use strict;
use warnings;
use parent 'Exporter';
use charnames qw( :full );
use Carp;

our $VERSION = '0.09';
our @EXPORT  = qw( dump_hex dump_dec dump_oct dump_bin dump_names dump_codes );
our %EXPORT_TAGS = (all => \@EXPORT);

sub dump_hex {
    my ($str) = @_;
    carp('dump_hex() expects one argument') && return if @_ != 1;
    return unless defined $str;
    return sprintf '%*vX', ' ', $str;
}

sub dump_dec {
    my ($str) = @_;
    carp('dump_dec() expects one argument') && return if @_ != 1;
    return unless defined $str;
    return sprintf '%*vd', ' ', $str;
}

sub dump_oct {
    my ($str) = @_;
    carp('dump_oct() expects one argument') && return if @_ != 1;
    return unless defined $str;
    return sprintf '%*vo', ' ', $str;
}

sub dump_bin {
    my ($str) = @_;
    carp('dump_bin() expects one argument') && return if @_ != 1;
    return unless defined $str;
    return sprintf '%*vb', ' ', $str;
}

sub dump_names {
    my ($str) = @_;
    carp('dump_names() expects one argument') && return if @_ != 1;
    return unless defined $str;
    return join ', ',
           map { charnames::viacode(ord) || '?' }
           split '', $str;
}

sub dump_codes {
    my ($str) = @_;
    carp('dump_codes() expects one argument') && return if @_ != 1;
    return unless defined $str;
    return join ' ', map { sprintf 'U+%04X', ord } split '', $str;
}

1;

__END__

=encoding UTF-8

=head1 NAME

String::Dump - Dump strings of characters (or bytes) for printing and debugging

=head1 VERSION

This document describes String::Dump version 0.09.

=head1 SYNOPSIS

    use String::Dump qw( dump_hex dump_bin );

    say 'hex: ', dump_hex($string);
    say 'bin: ', dump_bin($string);

=head1 DESCRIPTION

When debugging or examining strings containing non-ASCII or non-printing
characters, String::Dump is your friend.  It provides simple functions to return
a dump of the code points for Unicode strings or the bytes for byte strings in
several different formats, such as hex, binary, Unicode names, and more.

For using this module from the command line, see the bundled L<dumpstr> script.
For tips on debugging Unicode or byte strings with this module, see the document
L<String::Dump::Debugging>.

=head1 FUNCTIONS

These functions all accept a single argument: the string to dump, which may
either be a Unicode string or a byte string.  All functions are exported by
default unless specific ones are requested.  The C<:all> tag may be used to
explicitly export all functions.

=head2 dump_hex($string)

Hexadecimal (base 16) mode.

    use utf8;
    # string of 6 characters
    say dump_hex('Ĝis! ☺');  # 11C 69 73 21 20 263A

    no utf8;
    # series of 9 bytes
    say dump_hex('Ĝis! ☺');  # C4 9C 69 73 21 20 E2 98 BA

For a lowercase hex dump, simply pass the response to C<lc>.

    say lc dump_hex('Ĝis! ☺');  # 11c 69 73 21 20 263a

=head2 dump_dec($string)

Decimal (base 10) mode.  This is mainly useful when referencing 8-bit code pages
like ISO-8859-1 or 7-bit ones like ASCII variants.

    use utf8;
    say dump_dec('Ĝis! ☺');  # 284 105 115 33 32 9786

    no utf8;
    say dump_dec('Ĝis! ☺');  # 196 156 105 115 33 32 226 152 186

=head2 dump_oct($string)

Octal (base 8) mode.  This is mainly useful when referencing 7-bit code pages
like ASCII variants.

    use utf8;
    say dump_oct('Ĝis! ☺');  # 434 151 163 41 40 23072

    no utf8;
    say dump_oct('Ĝis! ☺');  # 304 234 151 163 41 40 342 230 272

=head2 dump_bin($string)

Binary (base 2) mode.

    use utf8;
    say dump_bin('Ĝis! ☺');
    # 100011100 1101001 1110011 100001 100000 10011000111010

    no utf8;
    say dump_bin('Ĝis! ☺');
    # 11000100 10011100 1101001 1110011 100001 100000 11100010 10011000 10111010

=head2 dump_names($string)

Unicode character name mode.  Unlike the various numeral modes above, this mode
uses “, ” <comma, space> for the delimiter and it only makes sense for Unicode
strings, not byte strings.

    use utf8;
    say dump_names('Ĝis! ☺');
    # LATIN CAPITAL LETTER G WITH CIRCUMFLEX, LATIN SMALL LETTER I,
    # LATIN SMALL LETTER S, EXCLAMATION MARK, SPACE, WHITE SMILING FACE

The output in the example above has been manually split into multiple lines for
the layout of this document.

=head2 dump_codes($string)

Unicode code point mode.  This is similar to C<dump_hex> except it follows the
standard Unicode code point notation.  The hex value is 4 to 6 digits, padded
with “0” <digit zero> when less than 4, and prefixed with “U+” <latin capital
letter u, plus sign>.  As with C<dump_names>, this function only makes sense for
Unicode strings, not byte strings.

    use utf8;
    say dump_codes('Ĝis! ☺');  # U+011C U+0069 U+0073 U+0021 U+0020 U+263A

=head1 SEE ALSO

=over

=item * L<dumpstr> - Dump strings of characters on the command line

=item * L<String::Dump::Debugging> - String debugging tips with String::Dump

=item * L<Template::Plugin::StringDump> - String::Dump plugin for TT

=item * L<Data::HexDump> - Simple hex dumping using the default output of the
Unix C<hexdump> utility

=item * L<Data::Hexdumper> - Advanced formatting of binary data, similar to
C<hexdump>

=back

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 COPYRIGHT AND LICENSE

© 2011–2013 Nick Patch

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
