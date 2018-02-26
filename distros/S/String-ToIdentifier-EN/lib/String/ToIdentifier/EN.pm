package String::ToIdentifier::EN;
our $AUTHORITY = 'cpan:AVAR';
$String::ToIdentifier::EN::VERSION = '0.12';
use 5.008001;
use strict;
use warnings;
use Text::Unidecode 'unidecode';
use Lingua::EN::Inflect::Phrase 'to_PL';
use Unicode::UCD 'charinfo';
use namespace::clean;
use Exporter 'import';

=head1 NAME

String::ToIdentifier::EN - Convert Strings to English Program Identifiers

=head1 SYNOPSIS

    use utf8;
    use String::ToIdentifier::EN 'to_identifier';

    to_identifier 'foo-bar';             # fooDashBar
    to_identifier 'foo-bar', '_';        # foo_dash_bar
    to_identifier 'foo.bar', '_';        # foo_dot_bar
    to_identifier "foo\x{4EB0}bar";      # fooJingBar
    to_identifier "foo\x00bar";          # fooNullCharBar
    to_identifier "foo\x00\x00bar";      # foo2NullCharsBar
    to_identifier "foo\x00\x00bar", '_'; # foo_2_null_chars_bar

    {
        no utf8;
        to_identifier "foo\xFF\xFFbar.baz";      # foo_2_0xFF_BarDotBaz
        to_identifier "foo\xFF\xFFbar.baz", '_'; # foo_2_0xFF_bar_dot_baz
    }

=head1 DESCRIPTION

This module provides a utility method, L</to_identifier> for converting an
arbitrary string into a readable representation using the ASCII subset of C<\w>
for use as an identifier in a computer program. The intent is to make unique
identifier names from which the content of the original string can be easily
inferred by a human just by reading the identifier.

If you need the full set of C<\w> including Unicode, see
the subclass L<String::ToIdentifier::EN::Unicode>.

Currently, this process is one way only, and will likely remain this way.

The default is to create camelCase identifiers, or you may pass in a separator
char of your choice such as C<_>.

Binary char groups will be separated by C<_> even in camelCase identifiers to
make them easier to read, e.g.: C<foo_2_0xFF_Bar>.

=head1 EXPORT

Optionally exports the L</to_identifier> function.

=cut

our @EXPORT_OK = qw/to_identifier/;

=head1 SUBROUTINES

=cut

our %ASCII_MAP = (
    0x00 => ['null'],
    0x01 => ['start', 'of', 'heading'],
    0x02 => ['start', 'of', 'text'],
    0x03 => ['end', 'of', 'text'],
    0x04 => ['end', 'of', 'transmission'],
    0x05 => ['enquiry', 'char'],
    0x06 => ['ack'],
    0x07 => ['bell', 'char'],
    0x08 => ['backspace'],
    0x09 => ['tab', 'char'],
    0x0A => ['newline'],
    0x0B => ['vertical', 'tab'],
    0x0C => ['form', 'feed'],
    0x0D => ['carriage', 'return'],
    0x0E => ['shift', 'out'],
    0x0F => ['shift', 'in'],
    0x10 => ['data', 'link', 'escape'],
    0x11 => ['device', 'control1'],
    0x12 => ['device', 'control2'],
    0x13 => ['device', 'control3'],
    0x14 => ['device', 'control4'],
    0x15 => ['negative', 'ack'],
    0x16 => ['synchronous', 'idle'],
    0x17 => ['end', 'of', 'transmission', 'block'],
    0x18 => ['cancel', 'char'],
    0x19 => ['end', 'of', 'medium'],
    0x1A => ['substitute', 'char'],
    0x1B => ['escape', 'char'],
    0x1C => ['file', 'separator'],
    0x1D => ['group', 'separator'],
    0x1E => ['record', 'separator'],
    0x1F => ['unit', 'separator'],
    0x20 => ['space', 'char'],
    0x21 => ['exclamation', 'mark'],
    0x22 => ['double', 'quote'],
    0x23 => ['hash', 'mark'],
    0x24 => ['dollar', 'sign'],
    0x25 => ['percent', 'sign'],
    0x26 => ['ampersand'],
    0x27 => ['single', 'quote'],
    0x28 => ['left', 'paren'],
    0x29 => ['right', 'paren'],
    0x2A => ['asterisk'],
    0x2B => ['plus', 'sign'],
    0x2C => ['comma'],
    0x2D => ['dash'],
    0x2E => ['dot'],
    0x2F => ['slash'],
    0x3A => ['colon'],
    0x3B => ['semicolon'],
    0x3C => ['left', 'angle', 'bracket'],
    0x3D => ['equals', 'sign'],
    0x3E => ['right', 'angle', 'bracket'],
    0x3F => ['question', 'mark'],
    0x40 => ['at', 'sign'],
    0x5B => ['left', 'bracket'],
    0x5C => ['backslash'],
    0x5D => ['right', 'bracket'],
    0x5E => ['caret'],
    0x60 => ['backtick'],
    0x7B => ['left', 'brace'],
    0x7C => ['pipe', 'char'],
    0x7D => ['right', 'brace'],
    0x7E => ['tilde'],
    0x7F => ['delete', 'char'],
);

# fixup for perl <= 5.8.3
$ASCII_MAP{0} = ['null'];

=head2 to_identifier

Takes the string to be converted to an identifier, and optionally a separator
char such as C<_>. If a separator char is not provided, a camelCase identifier
will be returned.

=cut

sub to_identifier {
    return __PACKAGE__->string_to_identifier(@_);
}

# Override some pluralizations Lingua::EN::Inflect::Phrase gets wrong here, if
# needed.
sub _pluralize_phrase {
    my ($self, $phrase) = @_;

    return to_PL($phrase);
}

# for overriding in ::Unicode
sub _non_identifier_char {
    return qr/[^0-9a-zA-Z_]/;
}

=head1 METHODS

=head2 string_to_identifier

The class method version of L</to_identifier>, if you want to use the object
oriented interface.

=cut

sub string_to_identifier {
    my ($self, $str, $sep_char) = @_;

    my $is_utf8 = utf8::is_utf8($str);

    my $char_to_match = $self->_non_identifier_char;

    my $phrase_at_start = 0;

    while ($str =~ /((${char_to_match})\2*)/sg) {
        my $to_replace = $1;
        my $pos        = $-[1];

        my $count = length $to_replace;
        my $char  = substr $to_replace, 0, 1;

        my $replacement_phrase;
        my $use_underscore = 0;

        if (ord $char < 128) {
            $replacement_phrase = join ' ', @{ $ASCII_MAP{ord $char} };
        }
        elsif ($is_utf8) {
            my $decoded = lcfirst unidecode $char;

            $decoded =~ s/^\s+//;
            $decoded =~ s/\s+\z//;

            (my $decoded_without_spaces = $decoded) =~ s/\s+//g;

            my $bad_chars =()= $decoded_without_spaces =~ /$char_to_match/sg;

            # If Text::Unidecode gives us non-identifier chars, we use
            # either it or the UCD charname, whichever has fewer
            # non-identifier chars, after recursively passing the strings
            # through ->string_to_identifier.
            if ($bad_chars) {
                my $charname = lc charinfo(ord $char)->{name};

                $charname =~ s/^\s+//;
                $charname =~ s/\s+\z//;

                (my $charname_without_spaces = $charname) =~ s/\s+//g;

                my $charname_bad_chars =()=
                    $charname_without_spaces =~ /$char_to_match/sg;

                $decoded = $charname if $charname_bad_chars < $bad_chars;

                $decoded =
                    join ' ',
                    map $self->string_to_identifier($_),
                        split /\s+/, $decoded;
            }

            $replacement_phrase = $decoded;
        }
        else { # binary
            $replacement_phrase = sprintf '0x%X', ord $char;
            $use_underscore     = 1;
        }

        # For single char replacements, no separation or camelcasing is
        # necessary.
        if (length $replacement_phrase > 1) {
            $phrase_at_start = 1 if $pos == 0;

            $replacement_phrase = $self->_pluralize_phrase("$count $replacement_phrase")
                if $count > 1;

            {
                my $sep_char = $use_underscore ? '_' : $sep_char;

                if ($sep_char) {
                    $replacement_phrase = 
                        join($sep_char, split /\s+/, $replacement_phrase);

                    $replacement_phrase = $sep_char . $replacement_phrase
                        unless $pos == 0;

                    # Insert sep_char at the end of replacement text unless
                    # position is at the end of the string.
                    $replacement_phrase .= $sep_char
                        unless $pos + length($to_replace) == length($str);
                }
                else {
                    $replacement_phrase =
                        join '', map "\u$_", split /\s+/, $replacement_phrase;
                }
            }

            # titlecase the following text for camelCase identifiers
            substr($str, $pos + length($to_replace), 1) =
                ucfirst substr($str, $pos + length($to_replace), 1)
                if not $sep_char;
        }
        else {
            # For single char replacements we want to match the case.
            if (substr($str, $pos, 1) =~ /^\p{Lu}\z/) {
                $replacement_phrase = ucfirst $replacement_phrase;
            }
            else {
                $replacement_phrase = lcfirst $replacement_phrase;
            }
        }

        substr($str, $pos, length($to_replace)) = $replacement_phrase;
    }

    $str = lcfirst $str if $phrase_at_start;

    return $str;
}

=head1 SEE ALSO

L<String::ToIdentifier::EN::Unicode>,
L<Text::Unidecode>,
L<Lingua::EN::Inflect::Phrase>

=head1 AUTHOR

Rafael Kitover, C<< <rkitover@gmail.com> >>

=head1 REPOSITORY

L<http://github.com/rkitover/string-toidentifier-en>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018 Rafael Kitover <rkitover@gmail.com>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of String::ToIdentifier::EN
