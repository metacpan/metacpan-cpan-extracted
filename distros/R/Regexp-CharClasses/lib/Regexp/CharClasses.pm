package Regexp::CharClasses;

use strict;
use warnings;

use 5.010;

use Exporter  ();
use charnames ();

our  @ISA      = qw (Exporter);
our  $VERSION  = '2015112801';

our %EXPORT_TAGS = (
    digits       => [qw [IsDigit0 IsDigit1 IsDigit2 IsDigit3 IsDigit4
                         IsDigit5 IsDigit6 IsDigit7 IsDigit8 IsDigit9
                         IsLatinDigit]],
    perl         => [qw [IsPerlSigil IsLeftParen IsRightParen IsParen]],
    english      => [qw [IsLcVowel IsUcVowel IsVowel 
                         IsLcConsonant IsUcConsonant IsConsonant]],
    encode       => [qw [IsUuencode IsBase64 IsBase64url IsBase32 IsBase32hex
                         IsBase16 IsBinHex]],
);

#
# @EXPORT is defined at the bottom of the file.
#

sub _d {
    my $number = shift;
    join "\n" => map {
        my $char = $_ ? "$_ DIGIT $number" : "DIGIT $number";
        sprintf "%04X" => charnames::vianame ($char)
    } @_;
}

sub _n {
    join "\n" => map {
        s/^\s+//;
        sprintf "%04X" => charnames::vianame ($_)
    } split "\n" => shift;
}

sub __ {
    local $_ = shift;
    s/^\s+//mg;
    $_;
}

#
# I'd prefer 'state', but that gives errors.
#
my $digits = [map {s/^\s+//; $_} split "\n" => <<"--"];

    ARABIC-INDIC
    EXTENDED ARABIC-INDIC
    NKO
    DEVANAGARI
    BENGALI
    GURMUKHI
    GUJARATI
    ORIYA
    TAMIL
    TELUGU
    KANNADA
    MALAYALAM
    THAI
    LAO
    TIBETAN
    MYANMAR
    KHMER
    MONGOLIAN
    LIMBU
    NEW TAI LUE
    BALINESE
    FULLWIDTH
    OSMANYA
    MATHEMATICAL BOLD
    MATHEMATICAL DOUBLE-STRUCK
    MATHEMATICAL SANS-SERIF
    MATHEMATICAL SANS-SERIF BOLD
    MATHEMATICAL MONOSPACE
--

my $numbers = [map {s/^\s+//; $_} split "\n" => <<"--"];
    ZERO
    ONE
    TWO
    THREE
    FOUR
    FIVE
    SIX
    SEVEN
    EIGHT
    NINE
--

sub IsDigit0    {state $return = _d ZERO  => @$digits}
sub IsDigit1    {state $return = _d ONE   => @$digits}
sub IsDigit2    {state $return = _d TWO   => @$digits}
sub IsDigit3    {state $return = _d THREE => @$digits}
sub IsDigit4    {state $return = _d FOUR  => @$digits}
sub IsDigit5    {state $return = _d FIVE  => @$digits}
sub IsDigit6    {state $return = _d SIX   => @$digits}
sub IsDigit7    {state $return = _d SEVEN => @$digits}
sub IsDigit8    {state $return = _d EIGHT => @$digits}
sub IsDigit9    {state $return = _d NINE  => @$digits}

foreach my $language (@$digits) {
    next if !$language;
    my $t_name   =  join "" => map {ucfirst lc} split /\W+/ => $language;
    my $sub_name = "Is${t_name}Digit";
    push @{$EXPORT_TAGS {digits}} => $sub_name;
    if ($language eq "FULLWIDTH" || $language =~ /^MATHEMATICAL/
                                 || $language =~ /ARABIC-INDIC$/) {
        eval <<"        --";
            sub $sub_name {
                state \$return = _n join "\n" =>
                                    map {"$language DIGIT \$_"} \@\$numbers;
            }
        --
        die $@ if $@;
    }
    else {
        eval <<"        --";
            sub $sub_name {state \$return = __ <<"            --"}
                +utf8::Is${t_name}
                &utf8::IsDigit
            --
        --
        die $@ if $@;
    }
}

sub IsLatinDigit {
    state $return = _n join "\n" => map {"DIGIT $_"} @$numbers
}

sub IsPerlSigil {state $return = _n <<"--"}
    DOLLAR SIGN
    PERCENT SIGN
    AMPERSAND
    ASTERISK
    COMMERCIAL AT
--

sub IsLeftParen {state $return = _n <<"--"}
    LEFT PARENTHESIS
    LESS-THAN SIGN
    LEFT SQUARE BRACKET
    LEFT CURLY BRACKET
--

sub IsRightParen {state $return = _n <<"--"}
    RIGHT PARENTHESIS
    GREATER-THAN SIGN
    RIGHT SQUARE BRACKET
    RIGHT CURLY BRACKET
--

sub IsParen {state $return = __ <<"--"}
    +Regexp::CharClasses::IsLeftParen
    +Regexp::CharClasses::IsRightParen
--

sub IsLcVowel {state $return = _n <<"--"}
    LATIN SMALL LETTER A
    LATIN SMALL LETTER E
    LATIN SMALL LETTER I
    LATIN SMALL LETTER O
    LATIN SMALL LETTER U
--

sub IsUcVowel {state $return = _n <<"--"}
    LATIN CAPITAL LETTER A
    LATIN CAPITAL LETTER E
    LATIN CAPITAL LETTER I
    LATIN CAPITAL LETTER O
    LATIN CAPITAL LETTER U
--

sub IsVowel {state $return = __ <<"--"}
    +Regexp::CharClasses::IsLcVowel
    +Regexp::CharClasses::IsUcVowel
--

sub IsLcConsonant {state $return = __ <<"--"}
    0061 007A
    -Regexp::CharClasses::IsLcVowel
--

sub IsUcConsonant {state $return = __ <<"--"}
    0041 005A
    -Regexp::CharClasses::IsUcVowel
--

sub IsConsonant {state $return = __ <<"--"}
    +Regexp::CharClasses::IsLcConsonant
    +Regexp::CharClasses::IsUcConsonant
--

# Space to grave accent.
sub IsUuencode {state $return = __ <<"--"}
    0020 0060
--

# A-Z, a-z, 0-9, '+' and '/'; '=' is use for padding. (RFC 4648)
sub IsBase64 {state $return = __ <<"--"}
    0030 0039
    0041 005A
    0061 007A
    002B
    002F
    003D
--

# A-Z, a-z, 0-9, '-' and '_'; '=' is use for padding. (RFC 4648)
sub IsBase64url {state $return = __ <<"--"}
    0030 0039
    0041 005A
    0061 007A
    002D
    005F
    003D
--

# A-Z, 2-7; '=' is use for padding. (RFC 4648)
sub IsBase32 {state $return = __ <<"--"}
    0032 0037
    0041 005A
    003D
--


# 0-9, A-V; '=' is use for padding. (RFC 4648)
sub IsBase32hex {state $return = __ <<"--"}
    0030 0039
    0041 0056
    003D
--


# 0-9, A-F. (RFC 4648)
sub IsBase16 {state $return = __ <<"--"}
    0030 0039
    0041 0046
--

# !"#$%&'()*+,-012345689@ABCDEFGHIJKLMNPQRSTUVXYZ[`abcdefhijklmpqr
# Note, no 'O', no 'W', no 'g', no 'n', no 'o'
sub IsBinHex {state $return = __ <<"--"}
    0021 002D
    0030 0039
    0040 004E
    0050 0056
    0058 005B
    0060 0066
    0068 006D
    0070 0072
--


our @EXPORT = map {@$_} values %EXPORT_TAGS;

1;

__END__

=pod

=head1 NAME

Regexp::CharClasses - Provide character classes

=head1 SYNOPSIS

 use Regexp::CharClasses;               # Import all.

 "..." =~ /\p{IsDigit0}/;
 "..." =~ /\P{IsThaiDigit}/;

 use Regexp::CharClasses qw [IsDigit2]; # Import a property.

 use Regexp::CharClasses ':perl';       # Properties tagged ':perl'

=head1 DESCRIPTION

Using the module C<Regexp::CharClasses> in your package allows
you to use several "Unicode Property" character classes in addition to
the standard ones. Such character classes are all of the form
C<\p{IsProperty}> (which matches a character adhering to the property) and
C<\P{IsProperty}> (which matches a character not adhering to the property).
For details, see L<perlrecharclass/Unicode Properties>.

By default, all the properties listed below will be imported in your namespace.
But you can specify which properties you want to import by giving them as
arguments to the C<use> line. Alternatively, you can import one or more tags.
The properties listed below will specify to which tags they belong.

=head2 Properties

The following properties are exported from C<Regexp::CharClasses>:

=over 2

=item C<\p{IsDigit0}>

=item C<\p{IsDigit1}>

=item C<\p{IsDigit2}>

=item C<\p{IsDigit3}>

=item C<\p{IsDigit4}>

=item C<\p{IsDigit5}>

=item C<\p{IsDigit6}>

=item C<\p{IsDigit7}>

=item C<\p{IsDigit8}>

=item C<\p{IsDigit9}>

Matches any digit 0 for C<\p{IsDigit0}>, any digit 1 for C<\p{IsDigit1}> etc, in
one of the following languages or scripts:
Latin, Arabic-Indic, Extended Arabic-Indic, Nko, Devanagari, Bengali,
Gurmukhi, Gujarati, Oriya, Tamil, Telugu, Kannada, Malayalam, Thai, Lao,
Tibetan, Myanmar, Khmer, Mongolian, Limbu, New Tai Lue, Balinese, Osmanya,
Fullwidth, Mathematical Bold, Mathematical Double-Struck,
Mathematical Sans-Serif, Mathematical Sans-Serif Bold, Mathematical Monospace.
The code points of the characters matched can be found by adding the 
digit being matched to the following list (in hex):

  0030  0660  06F0  07C0  0966  09E6  0A66  0AE6  0B66  0BE6  0C66 
  0CE6  0D66  0E50  0ED0  0F20  1040  17E0  1810  1946  19D0  1B50
  FF10 104A0 1D7CE 1D7D8 1D7E2 1D7EC 1D7F6

The properties are imported when asking for the tag C<:digits>.

=item C<\p{IsLatinDigit}>

=item C<\p{IsArabicIndicDigit}>

=item C<\p{IsExtendedArabicIndicDigit}>

=item C<\p{IsNkoDigit}>

=item C<\p{IsDevanagariDigit}>

=item C<\p{IsBengaliDigit}>

=item C<\p{IsGurmukhiDigit}>

=item C<\p{IsGujaratiDigit}>

=item C<\p{IsOriyaDigit}>

=item C<\p{IsTamilDigit}>

=item C<\p{IsTeluguDigit}>

=item C<\p{IsKannadaDigit}>

=item C<\p{IsMalayalamDigit}>

=item C<\p{IsThaiDigit}>

=item C<\p{IsLaoDigit}>

=item C<\p{IsTibetanDigit}>

=item C<\p{IsMyanmarDigit}>

=item C<\p{IsKhmerDigit}>

=item C<\p{IsMongolianDigit}>

=item C<\p{IsLimbuDigit}>

=item C<\p{IsNewTaiLueDigit}>

=item C<\p{IsBalineseDigit}>

=item C<\p{IsOsmanyaDigit}>

=item C<\p{IsFullwidthDigit}>

=item C<\p{IsMathematicalBoldDigit}>

=item C<\p{IsMathematicalSansSerifDigit}>

=item C<\p{IsMathematicalSansSerifBoldDigit}>

=item C<\p{IsMathematicalMonospaceDigit}>

These properties match the characters representing the digits 0 .. 9 in
the given script.

The properties are imported when asking for the tag C<:digits>.

=item C<\p{IsPerlSigil}>

This property matches all the characters that are sigils in Perl. It's
equivalent with C<[\$\@%&*]>. This property is imported when asking
for the tag C<:perl>.

=item C<\p{IsLeftParen}>

=item C<\p{IsRightParen}>

=item C<\p{IsParen}>

These properties match left (opening) parenthesis, right (closing) 
parenthesis, and just any parenthesis respectively. The classes are
equivalent to C<< [(<[{] >>, C<< [)>\]}] >> and C<< [()<>[\]{}] >>.
These properties are imported when asking for the tag C<:perl>

=item C<\p{IsLcVowel}>

=item C<\p{IsUcVowel}>

=item C<\p{IsVowel}>

These properties match vowels in the English language. C<\p{IsLcVowel}>
matches lowercase vowels, C<\p{IsUcVowel}> matches uppercase vowels, while
C<\p{IsVowel}> matches vowels in any case. The properties are equivalent to
the character classes C<[aeiou]>, C<[AEIOU]> and C<[aeiouAEIOU]>.

The properties are imported when asking for the tag C<:english>.

=item C<\p{IsLcConsonant}>

=item C<\p{IsUcConsonant}>

=item C<\p{IsConsonant}>

These properties match consonants in the English language.
C<\p{IsLcConsonant}> matches lowercase consonants, C<\p{IsUcConsonant}>
matches uppercase consonants, while C<\p{IsConsonant}> matches consonants
in any case. The properties are equivalent to the character classes
C<[bcdfghjklmnpqrstvwxyz]>, C<[BCDFGHJKLMNPQRSTVWXYZ]> and
C<[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ]>.

The properties are imported when asking for the tag C<:english>.

=item C<\p{IsUuencode}>

This property matches the characters used in uudecoding strings. Uudecode
uses 64 characters to encode, with space and accent grave interchangeable,
so this property matches 65 different characters; it's equivalent with the
character class S<C<< [ !"#\$%&'()*+,\-./0-9:;<=>?\@A-Z[\\\]^_`] >>>.

C<\p{IsUuencode}> is imported when asking for the tag C<:encode>.

=item C<\p{IsBase64}>

=item C<\p{IsBase64url}>

=item C<\p{IsBase32}>

=item C<\p{IsBase32hex}>

=item C<\p{IsBase16}>

These properties match the characters used in various encodings
as described in RFC 4648, of which base64 is the probably the best
known.  C<\p{IsBase64}> and C<\p{IsBase64url}> use 64 characters to
encode, C<\p{IsBase32}> and C<\p{IsBase32hex}> use 32 characters, and
C<\p{IsBase16}> use 16. All but C<\p{IsBase16}> use the C<=> character
for padding.  The properties are equivalent with the following character
classes: C<< [0-9A-Za-z+/=] >> (C<\p{IsBase64}>), C<< [0-9A-Za-z\-_=] >>
(C<\p{IsBase64url}>), C<< [2-7A-Z=] >> (C<\p{IsBase32}>), C<< [0-9A-V=] >>
(C<\p{IsBase32hex}>), and C<< [0-9A-F] >> (C<\p{IsBase16}>).

The properties are imported when asking for the tag C<:encode>.

=item C<\p{IsBinHex}>

This property matches the characters used when encoding a string using
the binhex method. The encoding uses 64 characters; it's equivalent with
the character class C<< [!"#\$%&'()*+,\-0-9\@A-NP-VX-Z[`a-fh-mp-r] >>.

C<\p{IsBinHex}> is imported when asking for the tag C<:encode>.

=back

=head1 EXAMPLES

 use Regexp::CharClasses;

 "[" =~ /\p{IsRightParen}/;    # Match
 "[" =~ /\p{IsLeftParen}/;     # No match
 "[" =~ /\p{IsParen}/;         # Match

 use charnames ":full";
 $thai5 = "\N{THAI DIGIT FIVE}";
 $thai5 =~ /\p{IsDigit5}/;     # Match
 $thai5 =~ /\P{IsDigit6}/;     # Match
 $thai5 =~ /\p{IsThaiDigit}/;  # Match

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 BUGS

Sometimes C<y> and C<w> are used as consonants in English.

=head1 DEVELOPMENT

The current sources of this module are found on github,
L<< git://github.com/Abigail/regexp--charclasses.git >>.

=head1 AUTHOR

Abigail L<< mailto:regexp-charclasses@abigail.be >>.

=head1 COPYRIGHT and LICENSE

This program is copyright 2008 - 2009 by Abigail.
 
Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
