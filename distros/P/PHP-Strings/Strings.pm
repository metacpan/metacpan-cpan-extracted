package PHP::Strings;
#line 1 Strings.tt
# vim: ft=perl
use strict;
use warnings FATAL => 'all';
our $VERSION = '0.28';

=head1 NAME

PHP::Strings - Implement some of PHP's string functions.

=head1 SYNOPSIS

    use PHP::Strings;

    my $slashed = addcslashes( $not_escaped, $charlist );
    my $wordcount = str_word_count( $string );
    my @words     = str_word_count( $string, 1 );
    my %positions = str_word_count( $string, 2 );
    my $clean = strip_tags( $html, '<a><b><i><u>' );
    my $unslashed = stripcslashes( '\a\b\f\n\r\xae' );


=head1 DESCRIPTION

PHP has many functions. This is one of the main problems with PHP.

People do, however, get used to said functions and when they come to a
better designed language they get lost because they have to implement
some of these somewhat vapid functions themselves.

So I wrote C<PHP::Strings>. It implements most of the strings functions
of PHP. Those it doesn't implement it describes how to do in native
Perl.

Any function that would be silly to implement has not been and has been
marked as such in this documentation. They will still be exportable, but
if you attempt to use said function you will get an error telling you to
read these docs.

=head1 RELATED READING

=over 4

=item *

"PHP in Contrast to Perl"
L<http://tnx.nl/php.txt>

=item *

"Experiences of Using PHP in Large Websites" by Aaron Crane, 2002
L<http://www.ukuug.org/events/linux2002/papers/html/php/>

=item *

"PHP Annoyances" by Neil de Carteret, 2002
L<http://n3dst4.com/articles/phpannoyances/>

=item *

"I hate PHP" by Keith Devens, 2003
L<http://keithdevens.com/weblog/archive/2003/Aug/13/HATE-PHP>

=item *

"PHP: A love and hate relationship" by Ivan Ristic, 2002
L<http://www.webkreator.com/php/community/php-love-and-hate.html>

=item *

"PHP Sucks"
L<http://czth.net/pH/PHPSucks>

=item *

Nathan Torkington's "list of PHP's shortcomings"
L<http://nntp.x.perl.org/group/perl.advocacy/1458>

=back

=head1 ERROR HANDLING

All arguments are checked using L<Params::Validate>. Bad arguments will
cause an error to be thrown. If you wish to catch it, use C<eval>.

Attempts to use functions I've decided to not implement (as distinct
from functions that aren't implemented because I've not gotten around to
either writing or deciding whether to write) will cause an error
displaying the documentation for said function.

=cut

use base qw( Exporter );
use Carp qw( croak );
use vars qw( %EXPORT_TAGS @EXPORT @EXPORT_OK @badeggs );
use Params::Validate qw( :all );
use Scalar::Util qw( looks_like_number );

use constant STRING => {
    type => SCALAR,
};
use constant INTEGER => {
    type => SCALAR,
    regex => qr{^\d+$}
};
use constant NUMBER => {
    type => SCALAR,
    callbacks => {
        'is a number' => sub {
            defined $_[0] and looks_like_number $_[0]
        }
    },
};

sub NUMBER_RANGE ($$) {
    my ($min, $max) = @_;
    return {
        %{+INTEGER},
        callbacks => {
            "Number between $min and $max" => sub {
                $_[0] =~ /^\d+$/ and $min <= $_[0] and $_[0] <= $max
            }
        }
    };
}

sub death
{
    local $_ = shift;
    s/^=.*$//gm;
    s/^\n+//g;
    s/\n+$//g;
    croak "\n$_\n\n";
}

=head1 EXPORTS

By default, nothing is exported.

Each function and constant can be exported by explicit name.

    use PHP::Strings qw( str_pad addcslashes );

To get a function and its associated constants as well, prefix them with a colon:

    use PHP::Strings qw( :str_pad );
    # This grabs str_pad, STR_PAD_LEFT, STR_PAD_BOTH, STR_PAD_RIGHT.

To export everything:

    use PHP::Strings qw( :all );

For more information on what you can add there, consult
L<Exporter/"Specialised Import Lists">.

=cut

@EXPORT_OK = map { @$_ } values %EXPORT_TAGS;

=head1 FUNCTIONS



=head2 addcslashes

L<http://www.php.net/addcslashes>


    my $slashed = addcslashes( $not_escaped, $charlist );

Returns a string with backslashes before characters that are listed
in C<$charlist>.


=cut




BEGIN { $EXPORT_TAGS{addcslashes} = [ qw(
    addcslashes 
) ] }

#line 0 fns/addcslashes.fn
sub addcslashes
{
    my ($str, $charlist) = validate_pos( @_,
        STRING, STRING,
    );

    my @patterns = split /(.\.\..)/, $charlist;
    for (@patterns) {
        if ( m/ \A (.)\.\.(.) \z /x ) {
            if ( ord $1 > ord $2 ) {
                $_ = "\Q$1$2.";
            } else {
                $_ = "\Q$1\E-\Q$2\E";
            }
        } else {
            $_ = "\Q$_";
        }
    }
    my $tr = join '', @patterns;
    $str =~ s/([$tr])/\\$1/g;

    return $str;
}



=head2 addslashes

L<http://www.php.net/addslashes>


=cut

sub addslashes {
    death(<<'EODEATH');

=pod

B<PHP::Strings::addslashes WILL NOT BE IMPLEMENTED>.

Returns a string with backslashes before characters that need to be
quoted in SQL queries. You should never need this function. I mean,
never.

L<DBI>, the standard method of accessing databases with perl, does all
this for you. It provides by a C<quote> method to escape anything, and
it provides placeholders and bind values so you don't even have to worry
about escaping. In PHP, PEAR DB also provides this facility.

L<DBI> is also aware that some databases don't escape in this method,
such as mssql which uses doubled characters to escape (like some
versions of BASIC). This function doesn't.

The less said about PHP's C<magic_quotes> "feature", the better.


=cut

EODEATH
}



BEGIN { push @badeggs, "addslashes" };


=head2 bin2hex

L<http://www.php.net/bin2hex>


=cut

sub bin2hex {
    death(<<'EODEATH');

=pod

B<PHP::Strings::bin2hex WILL NOT BE IMPLEMENTED>.

This is trivially implemented using L<pack|perlfunc/"pack">.

    my $hex = unpack "H*", $data;


=cut

EODEATH
}



BEGIN { push @badeggs, "bin2hex" };


=head2 chop

L<http://www.php.net/chop>


B<PHP::Strings::chop WILL NOT BE IMPLEMENTED>.


PHP's C<chop> function is an alias to its L<"rtrim"> function.

Perl has a builtin named L<chop|perlfunc/"chop">. Thus we do
not support the use of C<chop> as an alias to L<"rtrim">.


=cut


# No fn export due to clash with reserved perl keyword.


=head2 chr

L<http://www.php.net/chr>


B<PHP::Strings::chr WILL NOT BE IMPLEMENTED>.


PHP's and Perl's L<chr|perlfunc/"chr"> functions operate sufficiently
identically.

Note that PHP's claims an ASCII value as input. Perl assumes Unicode.
But ensure you see L<the documentation|perlfunc/"chr"> for a precise
definition.

Note that it returns B<one character>, which in some string
encodings may not necessarily be B<one byte>.


=cut


# No fn export due to clash with reserved perl keyword.


=head2 chunk_split

L<http://www.php.net/chunk_split>



Returns the given string, split into smaller chunks.

    my $split = chunk_split( $body [, $chunklen [, $end ] ] );

Where C<$body> is the data to split, C<$chunklen> is the optional length
of data between each split (default 76), and C<$end> is what to insert
both between each split (default C<"\r\n">) and on the end.

Also trivially implemented as a regular expression:

    $body =~ s/(.{$chunklen})/$1$end/sg;
    $body .= $end;


=cut




BEGIN { $EXPORT_TAGS{chunk_split} = [ qw(
    chunk_split 
) ] }

#line 0 fns/chunk_split.fn
sub chunk_split
{
    my ( $body, $chunklen, $end ) = validate_pos( @_,
        STRING,
        { %{+INTEGER}, optional => 1, default => 76 },
        { %{+STRING}, optional => 1, default => "\r\n" },
    );

    $body =~ s/(.{$chunklen})/$1$end/sg;
    $body .= $end;

    return $body;
}



=head2 convert_cyr_string

L<http://www.php.net/convert_cyr_string>


=cut

sub convert_cyr_string {
    death(<<'EODEATH');

=pod

B<PHP::Strings::convert_cyr_string WILL NOT BE IMPLEMENTED>.

Perl has the L<Encode> module to convert between character encodings.

=cut

EODEATH
}



BEGIN { push @badeggs, "convert_cyr_string" };


=head2 count_chars

L<http://www.php.net/count_chars>



A somewhat daft function that returns counts of characters in a string.

It's daft because it assumes characters have values in the range 0-255.
This is patently false in today's world of Unicode. In fact, the PHP
documentation for this function happily talks about characters in one
part and bytes in another, not realising the distinction.

So, I've implemented this function as if it were called C<count_bytes>.
It will count raw bytes, not characters.

Takes two arguments: the byte sequence to analyse and a 'mode' flag that
indicates what sort of return value to return. The default mode is C<0>.

   Mode  Return value
   ----  ------------
    0    Return hash of byte values and frequencies.
    1    As for 0, but hash does not contain bytes with frequency of 0.
    2    As for 0, but hash only contains bytes with frequency of 0.
    3    Return string composed of used byte-values.
    4    Return string composed of unused byte-values.

    my %freq = count_chars( $string, 1 );


=cut




BEGIN { $EXPORT_TAGS{count_chars} = [ qw(
    count_chars 
) ] }

#line 0 fns/count_chars.fn
sub count_chars
{
    my ( $input, $mode ) = validate_pos( @_,
        STRING,
        {
            %{+NUMBER_RANGE( 0, 4 )},
            optional => 1,
            default => 0
        },
    );

    if ( $mode < 3 ) # Frequency
    {
        use bytes;
        my %freq;
        @freq{0..255} = (0) x 256 if $mode != 1;
        $freq{ord $_}++ for split //, $input;
        if ( $mode == 2 ) {
            $freq{$_} and delete $freq{$_} for keys %freq;
        }
        return %freq;
    }
    else
    {
        my %freq = count_chars( $input, $mode-2 );
        return join '', map chr, sort keys %freq;
    }

    croak "Reached a line we should not have.";
}



=head2 crc32

L<http://www.php.net/crc32>


=cut

sub crc32 {
    death(<<'EODEATH');

=pod

B<PHP::Strings::crc32 WILL NOT BE IMPLEMENTED>.

See the L<String::CRC32> module.


=cut

EODEATH
}



BEGIN { push @badeggs, "crc32" };


=head2 crypt

L<http://www.php.net/crypt>


B<PHP::Strings::crypt WILL NOT BE IMPLEMENTED>.


PHP's crypt is the same as Perl's. Thus there's no need for
C<PHP::String> to provide an implementation.

The C<CRYPT_*> constants are not provided.


=cut


# No fn export due to clash with reserved perl keyword.


=head2 echo

L<http://www.php.net/echo>


=cut

sub echo {
    death(<<'EODEATH');

=pod

B<PHP::Strings::echo WILL NOT BE IMPLEMENTED>.

See L<perlfunc/"print">.

=cut

EODEATH
}



BEGIN { push @badeggs, "echo" };


=head2 explode

L<http://www.php.net/explode>


=cut

sub explode {
    death(<<'EODEATH');

=pod

B<PHP::Strings::explode WILL NOT BE IMPLEMENTED>.

Use the C<\Q> regex metachar and L<split|perlfunc/"split">.

    my @pieces = split /\Q$separator/, $string, $limit;

See L<perlfunc/"split"> for more details.

Note that C<split //> will split between every character, rather than
returning false. Note also that C<split "..."> is the same as
C<split /.../> which means to split everywhere three characters are
matched. The first argument to C<split> is always a regex.


=cut

EODEATH
}



BEGIN { push @badeggs, "explode" };


=head2 fprintf

L<http://www.php.net/fprintf>


=cut

sub fprintf {
    death(<<'EODEATH');

=pod

B<PHP::Strings::fprintf WILL NOT BE IMPLEMENTED>.

Perl's L<printf|perlfunc/"printf"> can be told to which file handle to
print.

    printf FILEHANDLE $format, @args;

See L<perlfunc/"printf"> and L<perlfunc/"print"> for details.


=cut

EODEATH
}



BEGIN { push @badeggs, "fprintf" };


=head2 get_html_translation_table

L<http://www.php.net/get_html_translation_table>


=cut

sub get_html_translation_table {
    death(<<'EODEATH');

=pod

B<PHP::Strings::get_html_translation_table WILL NOT BE IMPLEMENTED>.

Use the L<HTML::Entities> module to escape and unescape characters.

=cut

EODEATH
}



BEGIN { push @badeggs, "get_html_translation_table" };


=head2 hebrev

L<http://www.php.net/hebrev>


=cut

sub hebrev {
    death(<<'EODEATH');

=pod

B<PHP::Strings::hebrev WILL NOT BE IMPLEMENTED>.

Use the L<Encode> module to convert between character encodings.

=cut

EODEATH
}



BEGIN { push @badeggs, "hebrev" };


=head2 hebrevc

L<http://www.php.net/hebrevc>


=cut

sub hebrevc {
    death(<<'EODEATH');

=pod

B<PHP::Strings::hebrevc WILL NOT BE IMPLEMENTED>.

Use the L<Encode> module to convert between character encodings.

=cut

EODEATH
}



BEGIN { push @badeggs, "hebrevc" };


=head2 html_entity_decode

L<http://www.php.net/html_entity_decode>


=cut

sub html_entity_decode {
    death(<<'EODEATH');

=pod

B<PHP::Strings::html_entity_decode WILL NOT BE IMPLEMENTED>.

Use the L<HTML::Entities> module to decode character entities.

=cut

EODEATH
}



BEGIN { push @badeggs, "html_entity_decode" };


=head2 htmlentities

L<http://www.php.net/htmlentities>


=cut

sub htmlentities {
    death(<<'EODEATH');

=pod

B<PHP::Strings::htmlentities WILL NOT BE IMPLEMENTED>.

Use the L<HTML::Entities> module to encode character entities.

=cut

EODEATH
}



BEGIN { push @badeggs, "htmlentities" };


=head2 htmlspecialchars

L<http://www.php.net/htmlspecialchars>


=cut

sub htmlspecialchars {
    death(<<'EODEATH');

=pod

B<PHP::Strings::htmlspecialchars WILL NOT BE IMPLEMENTED>.

Use the L<HTML::Entities> module to encode character entities.

=cut

EODEATH
}



BEGIN { push @badeggs, "htmlspecialchars" };


=head2 implode

L<http://www.php.net/implode>


=cut

sub implode {
    death(<<'EODEATH');

=pod

B<PHP::Strings::implode WILL NOT BE IMPLEMENTED>.

See L<perlfunc/"join">. Note that join cannot accept its arguments in
either order because that's just not how Perl arrays and lists work.
Note also that the joining sequence is not optional.


=cut

EODEATH
}



BEGIN { push @badeggs, "implode" };


=head2 join

L<http://www.php.net/join>


B<PHP::Strings::join WILL NOT BE IMPLEMENTED>.


PHP's C<join> is an alias for C<implode>. See L<"implode">.


=cut


# No fn export due to clash with reserved perl keyword.


=head2 levenshtein

L<http://www.php.net/levenshtein>


=cut

sub levenshtein {
    death(<<'EODEATH');

=pod

B<PHP::Strings::levenshtein WILL NOT BE IMPLEMENTED>.

I have no idea why PHP has this function.

See L<Text::Levenshtein>, L<Text::LevenshteinXS>, L<String::Approx>,
L<Text::PHraseDistance> and probably any number of other modules on
CPAN.


=cut

EODEATH
}



BEGIN { push @badeggs, "levenshtein" };


=head2 ltrim

L<http://www.php.net/ltrim>


=cut

sub ltrim {
    death(<<'EODEATH');

=pod

B<PHP::Strings::ltrim WILL NOT BE IMPLEMENTED>.

As per L<perlfaq>:

    $string =~ s/^\s+//;

A basic glance through L<perlretut> or L<perlreref> should give you an
idea on how to change what characters get trimmed.


=cut

EODEATH
}



BEGIN { push @badeggs, "ltrim" };


=head2 md5

L<http://www.php.net/md5>


=cut

sub md5 {
    death(<<'EODEATH');

=pod

B<PHP::Strings::md5 WILL NOT BE IMPLEMENTED>.

See L<Digest::MD5> which provides a number of functions for computing
MD5 hashes from various sources and to various formats.

Note: the user notes for this function at http://www.php.net/md5 are
among the most unintentionally funny and misinformed I've read.


=cut

EODEATH
}



BEGIN { push @badeggs, "md5" };


=head2 md5_file

L<http://www.php.net/md5_file>


=cut

sub md5_file {
    death(<<'EODEATH');

=pod

B<PHP::Strings::md5_file WILL NOT BE IMPLEMENTED>.

The L<Digest::MD5> module provides sufficient support.

    use Digest::MD5;

    sub md5_file
    {
        my $filename = shift;
        my $ctx = Digest::MD5->new;
        open my $fh, '<', $filename or die $!;
        binmode( $fh );
        $ctx->addfile( $fh )->digest; # or hexdigest, or b64digest
    }

Despite providing that possible implementation just above, I've chosen to
not include it as an export due to the amount of flexibility of
L<Digest::MD5> and the number of ways you may want to get your file
handle. After all, you may want to use L<Digest::SHA1>, or
L<Digest::MD4> or some other digest mechanism.

Again, I wonder why PHP has the function as they so arbitrarily
hobble it.


=cut

EODEATH
}



BEGIN { push @badeggs, "md5_file" };


=head2 metaphone

L<http://www.php.net/metaphone>


=cut

sub metaphone {
    death(<<'EODEATH');

=pod

B<PHP::Strings::metaphone WILL NOT BE IMPLEMENTED>.

L<Text::Metaphone> and L<Text::DoubleMetaphone> and
L<Text::TransMetaphone> all provide metaphonic calculations.


=cut

EODEATH
}



BEGIN { push @badeggs, "metaphone" };


=head2 money_format

L<http://www.php.net/money_format>



sprintf for money.

=cut




BEGIN { $EXPORT_TAGS{money_format} = [ qw(
    money_format 
) ] }

#line 0 fns/money_format.fn
sub money_format
{
    my ( $format, @amounts ) = validate_with(
        params => \@_,
        allow_extra => 1,
        spec => [
            {
                type => SCALAR,
            },
            NUMBER,
        ]
    );

    my $rv = _strfmon( $format, @amounts );

    return $rv;
}



=head2 nl2br

L<http://www.php.net/nl2br>


=cut

sub nl2br {
    death(<<'EODEATH');

=pod

B<PHP::Strings::nl2br WILL NOT BE IMPLEMENTED>.

This is trivially implemented as:

    s,$,<br />,mg;


=cut

EODEATH
}



BEGIN { push @badeggs, "nl2br" };


=head2 nl_langinfo

L<http://www.php.net/nl_langinfo>


=cut

sub nl_langinfo {
    death(<<'EODEATH');

=pod

B<PHP::Strings::nl_langinfo WILL NOT BE IMPLEMENTED>.

L<I18N::Langinfo> has a C<langinfo> command that corresponds to PHP's
C<nl_langinfo> function.


=cut

EODEATH
}



BEGIN { push @badeggs, "nl_langinfo" };


=head2 number_format

L<http://www.php.net/number_format>



TBD

=cut




BEGIN { $EXPORT_TAGS{number_format} = [ qw(
    number_format 
) ] }

#line 0 fns/number_format.fn
sub number_format
{
    my ( $number, $decimals, $dec, $thousands ) = validate_pos( @_,
        NUMBER,
        { %{+NUMBER}, optional => 1 },
        { %{+STRING}, optional => 1, default => '.' },
        { %{+STRING}, optional => 1, default => ',' },
    );

    my $format = $decimals ? "%.${decimals}f" : "%d";

    my $formatted = 'XXX';

    return $formatted;
}



=head2 ord

L<http://www.php.net/ord>


B<PHP::Strings::ord WILL NOT BE IMPLEMENTED>.


See L<perlfunc/"ord">. Note that Perl returns Unicode value, not ASCII.

=cut


# No fn export due to clash with reserved perl keyword.


=head2 parse_str

L<http://www.php.net/parse_str>


=cut

sub parse_str {
    death(<<'EODEATH');

=pod

B<PHP::Strings::parse_str WILL NOT BE IMPLEMENTED>.

See instead the L<CGI> and L<URI> modules which handles that sort of
thing.


=cut

EODEATH
}



BEGIN { push @badeggs, "parse_str" };


=head2 print

L<http://www.php.net/print>


B<PHP::Strings::print WILL NOT BE IMPLEMENTED>.


See L<perlfunc/"print">.


=cut


# No fn export due to clash with reserved perl keyword.


=head2 printf

L<http://www.php.net/printf>


B<PHP::Strings::printf WILL NOT BE IMPLEMENTED>.


See L<perlfunc/"printf">.


=cut


# No fn export due to clash with reserved perl keyword.


=head2 quoted_printable_decode

L<http://www.php.net/quoted_printable_decode>


=cut

sub quoted_printable_decode {
    death(<<'EODEATH');

=pod

B<PHP::Strings::quoted_printable_decode WILL NOT BE IMPLEMENTED>.

L<MIME::QuotedPrint> provides functions for encoding and decoding
quoted-printable strings.


=cut

EODEATH
}



BEGIN { push @badeggs, "quoted_printable_decode" };


=head2 quotemeta

L<http://www.php.net/quotemeta>


B<PHP::Strings::quotemeta WILL NOT BE IMPLEMENTED>.


See L<perlfunc/"quotemeta">.

=cut


# No fn export due to clash with reserved perl keyword.


=head2 rtrim

L<http://www.php.net/rtrim>


=cut

sub rtrim {
    death(<<'EODEATH');

=pod

B<PHP::Strings::rtrim WILL NOT BE IMPLEMENTED>.

Another trivial regular expression:

    $string =~ s/\s+$//;

See the notes on L<"ltrim">.


=cut

EODEATH
}



BEGIN { push @badeggs, "rtrim" };


=head2 setlocale

L<http://www.php.net/setlocale>


=cut

sub setlocale {
    death(<<'EODEATH');

=pod

B<PHP::Strings::setlocale WILL NOT BE IMPLEMENTED>.

C<setlocale> is provided by the L<POSIX> module.

=cut

EODEATH
}



BEGIN { push @badeggs, "setlocale" };


=head2 sha1

L<http://www.php.net/sha1>


=cut

sub sha1 {
    death(<<'EODEATH');

=pod

B<PHP::Strings::sha1 WILL NOT BE IMPLEMENTED>.

See L<"md5">, mentally substituting L<Digest::SHA1> for L<Digest::MD5>,
although the user notes are not as funny.


=cut

EODEATH
}



BEGIN { push @badeggs, "sha1" };


=head2 sha1_file

L<http://www.php.net/sha1_file>


=cut

sub sha1_file {
    death(<<'EODEATH');

=pod

B<PHP::Strings::sha1_file WILL NOT BE IMPLEMENTED>.

See L<"md5_file">

=cut

EODEATH
}



BEGIN { push @badeggs, "sha1_file" };


=head2 similar_text

L<http://www.php.net/similar_text>



TBD

=cut




BEGIN { $EXPORT_TAGS{similar_text} = [ qw(
    similar_text 
) ] }

#line 0 fns/similar_text.fn
sub similar_text { croak "TBD" }


=head2 soundex

L<http://www.php.net/soundex>


=cut

sub soundex {
    death(<<'EODEATH');

=pod

B<PHP::Strings::soundex WILL NOT BE IMPLEMENTED>.

See L<Text::Soundex>, which also happens to be a core module.

=cut

EODEATH
}



BEGIN { push @badeggs, "soundex" };


=head2 sprintf

L<http://www.php.net/sprintf>


B<PHP::Strings::sprintf WILL NOT BE IMPLEMENTED>.


See L<perlfunc/"sprintf">.

=cut


# No fn export due to clash with reserved perl keyword.


=head2 sscanf

L<http://www.php.net/sscanf>


=cut

sub sscanf {
    death(<<'EODEATH');

=pod

B<PHP::Strings::sscanf WILL NOT BE IMPLEMENTED>.

This is a godawful function. You should be using regular expressions
instead. See L<perlretut> and L<perlre>.


=cut

EODEATH
}



BEGIN { push @badeggs, "sscanf" };


=head2 str_ireplace

L<http://www.php.net/str_ireplace>


=cut

sub str_ireplace {
    death(<<'EODEATH');

=pod

B<PHP::Strings::str_ireplace WILL NOT BE IMPLEMENTED>.

Use the C<s///> operator instead. See L<perlop> and L<perlre> for
details.


=cut

EODEATH
}



BEGIN { push @badeggs, "str_ireplace" };


=head2 str_pad

L<http://www.php.net/str_pad>



TBD

=cut




BEGIN { $EXPORT_TAGS{str_pad} = [ qw(
    str_pad STR_PAD_RIGHT STR_PAD_LEFT STR_PAD_BOTH 
) ] }

#line 0 fns/str_pad.fn
use constant STR_PAD_RIGHT => 1;
use constant STR_PAD_LEFT  => 2;
use constant STR_PAD_BOTH  => 3;

sub str_pad
{
    my ( $input, $length, $pad, $options ) = validate_pos( @_,
        STRING,
        INTEGER,
        { %{+STRING}, optional => 1, default => ' ' },
        { %{+INTEGER}, optional => 1, default => STR_PAD_RIGHT },
    );

    return $input if $length < length $input;

    # Work out where to place our string.
    my $start = 0;
    my $diff = $length - length $input;
    my $rv;

    if ( $options == STR_PAD_RIGHT )
    {
        my $padding = substr( $pad x $diff, 0, $diff );
        $rv = $input . $padding;
    }
    elsif ( $options == STR_PAD_LEFT )
    {
        my $padding = substr( $pad x $diff, 0, $diff );
        $rv = $padding . $input;
    }
    elsif ($options == STR_PAD_BOTH )
    {
        $rv = substr( $pad x $length, 0, $length );
        substr( $rv, $diff / 2, length $input ) = $input;
    }
    else
    {
        croak "Invalid 4th argument to str_pad";
    }

    $rv;
}



=head2 str_repeat

L<http://www.php.net/str_repeat>


=cut

sub str_repeat {
    death(<<'EODEATH');

=pod

B<PHP::Strings::str_repeat WILL NOT BE IMPLEMENTED>.

Instead, use the C<x> operator. See L<perlop> for details.

    my $by_ten = "-=" x 10;


=cut

EODEATH
}



BEGIN { push @badeggs, "str_repeat" };


=head2 str_replace

L<http://www.php.net/str_replace>


=cut

sub str_replace {
    death(<<'EODEATH');

=pod

B<PHP::Strings::str_replace WILL NOT BE IMPLEMENTED>.

See the C<s///> operator. L<perlop> and L<perlre> have details.


=cut

EODEATH
}



BEGIN { push @badeggs, "str_replace" };


=head2 str_rot13

L<http://www.php.net/str_rot13>


=cut

sub str_rot13 {
    death(<<'EODEATH');

=pod

B<PHP::Strings::str_rot13 WILL NOT BE IMPLEMENTED>.

This is rather trivially implemented as:

    $message =~ tr/A-Za-z/N-ZA-Mn-za-m/

(As per "Programming Perl", 3rd edition, section 5.2.4.)


=cut

EODEATH
}



BEGIN { push @badeggs, "str_rot13" };


=head2 str_shuffle

L<http://www.php.net/str_shuffle>



Implemented, against my better judgement. It's trivial, like so many of
the others.


=cut




BEGIN { $EXPORT_TAGS{str_shuffle} = [ qw(
    str_shuffle 
) ] }

#line 0 fns/str_shuffle.fn
sub str_shuffle
{
    require List::Util;
    my ( $string ) = validate_pos( @_, STRING );

    return join '', List::Util::shuffle split //, $string;
}



=head2 str_split

L<http://www.php.net/str_split>


=cut

sub str_split {
    death(<<'EODEATH');

=pod

B<PHP::Strings::str_split WILL NOT BE IMPLEMENTED>.

See L<perlfunc/"split"> for details.

    my @bits = split /(.{,$len})/, $string;


=cut

EODEATH
}



BEGIN { push @badeggs, "str_split" };


=head2 str_word_count

L<http://www.php.net/str_word_count>


    my $wordcount = str_word_count( $string );
    my @words     = str_word_count( $string, 1 );
    my %positions = str_word_count( $string, 2 );

With a single argument, returns the number of words in that string.
Equivalent to:

    my $wordcount = () = $string =~ m/(\S+)/g;

With 2 arguments, where the second is the value C<0>,
returns the same as with no second argument.

With 2 arguments, where the second is the value C<1>, returns
each of those words.
Equivalent to:

    my @words = $string =~ m/(\S+)/g;

With 2 arguments, where the second is the value C<2>,
returns a hash where the values are the words, and the
keys are their position in the string (offsets are 0
based).

If words are duplicated, then they are duplicated.
The definition of a word is anything that isn't a space.
When I say I<equivalent> above, I mean that's the exact
code this function uses.

This function should really be three different
functions, but as PHP already has over 3000, I
can only assume they wanted to restrain themselves.
Implementation wise, it is three different functions.
I just keep them in an array and dispatch appropriately.


=cut




BEGIN { $EXPORT_TAGS{str_word_count} = [ qw(
    str_word_count 
) ] }

#line 0 fns/str_word_count.fn

   my @str_word_count = (

       sub { 
           my $count = () = $_[0] =~ m/(\S+)/g;
           return $count;
       },

       sub {
           my @words = $_[0] =~ m/(\S+)/g;
           return @words;
       },

       sub {
           my %words;
           while ( $_[0] =~ m/(\S+)/g )
           {
               $words{ $-[1] } = $1;
           }
           return %words;
       },
   );

   sub str_word_count
   {
       my ( $string, $format ) = validate_pos( @_,
           STRING,
           {
               %{+NUMBER_RANGE( 0, $#str_word_count )},
               default => 0,
           }
       );

       return $str_word_count[$format]->( $string );
   }



=head2 strcasecmp

L<http://www.php.net/strcasecmp>


=cut

sub strcasecmp {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strcasecmp WILL NOT BE IMPLEMENTED>.

Equivalent to:

    lc($a) cmp lc($b)


=cut

EODEATH
}



BEGIN { push @badeggs, "strcasecmp" };


=head2 strchr

L<http://www.php.net/strchr>


=cut

sub strchr {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strchr WILL NOT BE IMPLEMENTED>.

See L<"strstr">

=cut

EODEATH
}



BEGIN { push @badeggs, "strchr" };


=head2 strcmp

L<http://www.php.net/strcmp>


=cut

sub strcmp {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strcmp WILL NOT BE IMPLEMENTED>.

Equivalent to:

    $a cmp $b


=cut

EODEATH
}



BEGIN { push @badeggs, "strcmp" };


=head2 strcoll

L<http://www.php.net/strcoll>


=cut

sub strcoll {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strcoll WILL NOT BE IMPLEMENTED>.

Equivalent to:

    use locale;

    $a cmp $b


=cut

EODEATH
}



BEGIN { push @badeggs, "strcoll" };


=head2 strcspn

L<http://www.php.net/strcspn>


=cut

sub strcspn {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strcspn WILL NOT BE IMPLEMENTED>.

Trivially equivalent to:

    my $cspn;
    $cspn = $-[0]-1 if $string =~ m/[chars]/;


=cut

EODEATH
}



BEGIN { push @badeggs, "strcspn" };


=head2 strip_tags

L<http://www.php.net/strip_tags>


    my $clean = strip_tags( $html, '<a><b><i><u>' );
You really want L<HTML::Scrubber>.

This function tries to return a string with all HTML
tags stripped from a given string. It errors on the
side of caution in case of incomplete or bogus tags.

You can use the optional second parameter to specify
tags which should not be stripped. 

For more control, use L<HTML::Scrubber>.


=cut




BEGIN { $EXPORT_TAGS{strip_tags} = [ qw(
    strip_tags 
) ] }

#line 0 fns/strip_tags.fn
sub strip_tags
{
    require HTML::Scrubber;
    require HTML::Entities;

    my ( $html, $allowed ) = validate_pos( @_,
        STRING,
        {
            %{+STRING},
            optional => 1,
            regex => qr{^(<\w+>)+$},
        },
    );

    my @allow = ();
    @allow = $allowed =~ /<(\w+)>/g if defined $allowed;

    my $scrubber = HTML::Scrubber->new(
        @allow ? ( allow => \@allow ) : ()
    );

    $scrubber->$_(1) for qw( comment process script style );

    $scrubber->default(
        undef,
        { '*' => 1 },
    );

    return HTML::Entities::decode_entities( $scrubber->scrub( $html ) );
}



=head2 stripcslashes

L<http://www.php.net/stripcslashes>


    my $unslashed = stripcslashes( '\a\b\f\n\r\xae' );

Returns a string with backslashes stripped off. Recognizes
C-like C<\n>, C<\r> ..., octal and hexadecimal representation.


=cut




BEGIN { $EXPORT_TAGS{stripcslashes} = [ qw(
    stripcslashes 
) ] }

#line 0 fns/stripcslashes.fn
sub stripcslashes
{
    my ($string) = validate_pos( @_, STRING );

    $string =~ s{
            \\([abfnrtv\\?'"])
            |
            \\(\d\d\d)
            |
            \\(x[[:xdigit:]]{2})
            |
            \\(x[[:xdigit:]])
    }{
        if ( $+ eq 'v' ) {
            "\013";
        } elsif (length $+ == 1) {
            eval qq{qq/\\$+/};
        } else {
            chr oct "0$+";
        }
    }exg ;

    return $string;
}



=head2 stripos

L<http://www.php.net/stripos>


=cut

sub stripos {
    death(<<'EODEATH');

=pod

B<PHP::Strings::stripos WILL NOT BE IMPLEMENTED>.

Trivially implemented as:
 
    my $pos    = index( lc $haystack, lc $needle );
    my $second = index( lc $haystack, lc $needle, $pos );

Note that unlike C<stripos>, C<index> returns C<-1> if
C<$needle> is not found. This makes testing much simpler.

If you want the additional behaviour of non-strings being
converted to integers and from there to characters of
that value, then you're silly. If you want to find a
character of particular value, explicitly use the
C<< L<chr|perlfunc/"chr"> >> function:

    my $charpos = index( lc $haystack, lc chr $char );


=cut

EODEATH
}



BEGIN { push @badeggs, "stripos" };


=head2 stripslashes

L<http://www.php.net/stripslashes>


=cut

sub stripslashes {
    death(<<'EODEATH');

=pod

B<PHP::Strings::stripslashes WILL NOT BE IMPLEMENTED>.

If you can think of a good reason for this function, you
have more imagination than I do.


=cut

EODEATH
}



BEGIN { push @badeggs, "stripslashes" };


=head2 stristr

L<http://www.php.net/stristr>


=cut

sub stristr {
    death(<<'EODEATH');

=pod

B<PHP::Strings::stristr WILL NOT BE IMPLEMENTED>.

Use L<substr()|perlfunc/"substr"> and L<index()|perlfunc/"index"> instead.

    my $strstr = substr( $haystack, index( lc $haystack, lc $needle ) );

Or a regex:

    my ( $strstr ) = $haystack =~ /(\Q$needle\E.*$)/si;


=cut

EODEATH
}



BEGIN { push @badeggs, "stristr" };


=head2 strlen

L<http://www.php.net/strlen>


=cut

sub strlen {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strlen WILL NOT BE IMPLEMENTED>.

See L<perldoc/"length">.


=cut

EODEATH
}



BEGIN { push @badeggs, "strlen" };


=head2 strnatcasecmp

L<http://www.php.net/strnatcasecmp>


=cut

sub strnatcasecmp {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strnatcasecmp WILL NOT BE IMPLEMENTED>.

See L<Sort::Naturally>.


=cut

EODEATH
}



BEGIN { push @badeggs, "strnatcasecmp" };


=head2 strnatcmp

L<http://www.php.net/strnatcmp>


=cut

sub strnatcmp {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strnatcmp WILL NOT BE IMPLEMENTED>.

See L<Sort::Naturally>.


=cut

EODEATH
}



BEGIN { push @badeggs, "strnatcmp" };


=head2 strncasecmp

L<http://www.php.net/strncasecmp>


=cut

sub strncasecmp {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strncasecmp WILL NOT BE IMPLEMENTED>.

Unnecessary. Perl is smart enough. Use
L<substr|perlfunc/"substr">.


=cut

EODEATH
}



BEGIN { push @badeggs, "strncasecmp" };


=head2 strncmp

L<http://www.php.net/strncmp>


=cut

sub strncmp {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strncmp WILL NOT BE IMPLEMENTED>.

Unnecessary. Perl is smart enough. Use
L<substr|perlfunc/"substr">.


=cut

EODEATH
}



BEGIN { push @badeggs, "strncmp" };


=head2 strpos

L<http://www.php.net/strpos>


=cut

sub strpos {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strpos WILL NOT BE IMPLEMENTED>.

This function is Perl's L<index|perlfunc/"index">
function, however C<index> has a sensible return value.


=cut

EODEATH
}



BEGIN { push @badeggs, "strpos" };


=head2 strrchr

L<http://www.php.net/strrchr>


=cut

sub strrchr {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strrchr WILL NOT BE IMPLEMENTED>.

See L<perlfunc/"rindex">. Note that all characters in
the C<$needle> are used: if you just want to find the
first character, then extract it.


=cut

EODEATH
}



BEGIN { push @badeggs, "strrchr" };


=head2 strrev

L<http://www.php.net/strrev>


=cut

sub strrev {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strrev WILL NOT BE IMPLEMENTED>.

See L<perlfunc/"reverse">. Note the note about scalar
context.

    my $derf = reverse "fred";
    print scalar reverse "fred";


=cut

EODEATH
}



BEGIN { push @badeggs, "strrev" };


=head2 strripos

L<http://www.php.net/strripos>


=cut

sub strripos {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strripos WILL NOT BE IMPLEMENTED>.

This is just getting silly.

See L<rindex|perlfunc/"rindex"> and L<lc|perlfunc/"lc">.


=cut

EODEATH
}



BEGIN { push @badeggs, "strripos" };


=head2 strrpos

L<http://www.php.net/strrpos>


=cut

sub strrpos {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strrpos WILL NOT BE IMPLEMENTED>.

See L<rindex|perlfunc/"rindex">.


=cut

EODEATH
}



BEGIN { push @badeggs, "strrpos" };


=head2 strstr

L<http://www.php.net/strstr>


=cut

sub strstr {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strstr WILL NOT BE IMPLEMENTED>.

Use L<substr()|perlfunc/"substr"> and L<index()|perlfunc/"index"> instead.

    my $strstr = substr( $haystack, index( $haystack, $needle ) );

Or a regex:

    my ( $strstr ) = $haystack =~ /(\Q$needle\E.*$)/s;


=cut

EODEATH
}



BEGIN { push @badeggs, "strstr" };


=head2 strtolower

L<http://www.php.net/strtolower>


=cut

sub strtolower {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strtolower WILL NOT BE IMPLEMENTED>.

See L<perlfunc/"lc">.


=cut

EODEATH
}



BEGIN { push @badeggs, "strtolower" };


=head2 strtoupper

L<http://www.php.net/strtoupper>


=cut

sub strtoupper {
    death(<<'EODEATH');

=pod

B<PHP::Strings::strtoupper WILL NOT BE IMPLEMENTED>.

See L<perlfunc/"uc">.


=cut

EODEATH
}



BEGIN { push @badeggs, "strtoupper" };


=head2 strtr

L<http://www.php.net/strtr>



This function, like many in PHP, is really two functions.

The first is the same as L<the tr operator|perlop/"tr">.
And you really should use C<tr> instead of this function.

The second is more complicated.


=cut




BEGIN { $EXPORT_TAGS{strtr} = [ qw(
    strtr 
) ] }

#line 0 fns/strtr.fn
sub _make_re_list
{
    return qr/@{[ join '|', map quotemeta, @_ ]}/;
}

sub _strtr_pairs
{
    my ( $string, $pairs ) = @_;
    my @alternates = reverse sort { length $a <=> length $b } keys %$pairs;

    # Exit quickly if we don't need to stay.
    return $string unless @alternates;

    my $regex = _make_re_list( @alternates );

    $string =~ s/($regex)/$pairs->{$1}/eg;
    
    return $string;
}

sub _strtr_tr
{
    my ( $string, $from, $to ) = @_;

    # Exit quickly if we don't need to stay.
    return $string unless length $from;

    # Ignore excess characters
    if ( length $from != length $to )
    {
        if ( length $to > length $from ) {
            substr( $to, (length $from) ) = "";
        } elsif ( length $from > length $to ) {
            substr( $from, (length $to) ) = "";
        }
    }

    eval "\$string =~ tr/$from/$to/, 1" or die $@;

    return $string;
}

sub strtr
{
    my ( $string, $from, $to ) = validate_pos( @_,
        STRING,
        STRING|HASHREF,
        {
            %{+STRING},
            optional => 1,
        },
    );

    if ( ref $from eq 'HASH' )
    {
        if ( not defined $to )
        {
            return _strtr_pairs( $string, $from );
        }
        else
        {
            croak "Parameter #3 to PHP::Strings::strtr ",
                "present when it should not be in 2-argument form.";
        }
    }
    elsif ( defined $from and not defined $to )
    {
        croak "Parameter #3 to PHP::Strings::strtr missing from".
            " 3-argument form.";
    }
    else
    {
        return _strtr_tr( $string, $from, $to );
    }
}



=head2 substr

L<http://www.php.net/substr>


B<PHP::Strings::substr WILL NOT BE IMPLEMENTED>.


See L<perlfunc/"substr">.


=cut


# No fn export due to clash with reserved perl keyword.


=head2 substr_compare

L<http://www.php.net/substr_compare>


=cut

sub substr_compare {
    death(<<'EODEATH');

=pod

B<PHP::Strings::substr_compare WILL NOT BE IMPLEMENTED>.

Use L<substr|perlfunc/"substr"> and
L<the C<cmp> operator|perlop/"Relational Operators">.


=cut

EODEATH
}



BEGIN { push @badeggs, "substr_compare" };


=head2 substr_count

L<http://www.php.net/substr_count>


=cut

sub substr_count {
    death(<<'EODEATH');

=pod

B<PHP::Strings::substr_count WILL NOT BE IMPLEMENTED>.

This is even in the FAQ.

L<http://faq.perl.org/perlfaq4.html#How_can_I_count_the_>

    my $count = () = $string =~ /regex/g;


=cut

EODEATH
}



BEGIN { push @badeggs, "substr_count" };


=head2 substr_replace

L<http://www.php.net/substr_replace>


=cut

sub substr_replace {
    death(<<'EODEATH');

=pod

B<PHP::Strings::substr_replace WILL NOT BE IMPLEMENTED>.

See L<perlfunc/"substr">.


=cut

EODEATH
}



BEGIN { push @badeggs, "substr_replace" };


=head2 trim

L<http://www.php.net/trim>


=cut

sub trim {
    death(<<'EODEATH');

=pod

B<PHP::Strings::trim WILL NOT BE IMPLEMENTED>.

Also in the FAQ.

L<http://faq.perl.org/perlfaq4.html#How_do_I_strip_blank>

See also L<"rtrim"> and L<"ltrim">.


=cut

EODEATH
}



BEGIN { push @badeggs, "trim" };


=head2 ucfirst

L<http://www.php.net/ucfirst>


B<PHP::Strings::ucfirst WILL NOT BE IMPLEMENTED>.


See L<perlfunc/"ucfirst">.


=cut


# No fn export due to clash with reserved perl keyword.


=head2 ucwords

L<http://www.php.net/ucwords>


=cut

sub ucwords {
    death(<<'EODEATH');

=pod

B<PHP::Strings::ucwords WILL NOT BE IMPLEMENTED>.

Another Perl FAQ.

L<http://faq.perl.org/perlfaq4.html#How_do_I_capitalize_>


=cut

EODEATH
}



BEGIN { push @badeggs, "ucwords" };


=head2 vprintf

L<http://www.php.net/vprintf>


=cut

sub vprintf {
    death(<<'EODEATH');

=pod

B<PHP::Strings::vprintf WILL NOT BE IMPLEMENTED>.

Unlike PHP, Perl isn't stupid. See L<printf|perlfunc/"printf">.


=cut

EODEATH
}



BEGIN { push @badeggs, "vprintf" };


=head2 vsprintf

L<http://www.php.net/vsprintf>


=cut

sub vsprintf {
    death(<<'EODEATH');

=pod

B<PHP::Strings::vsprintf WILL NOT BE IMPLEMENTED>.

Unlike PHP, Perl isn't stupid. See L<sprintf|perlfunc/"sprintf">.


=cut

EODEATH
}



BEGIN { push @badeggs, "vsprintf" };


=head2 wordwrap

L<http://www.php.net/wordwrap>


=cut

sub wordwrap {
    death(<<'EODEATH');

=pod

B<PHP::Strings::wordwrap WILL NOT BE IMPLEMENTED>.

See L<Text::Wrap>, a core module.


=cut

EODEATH
}



BEGIN { push @badeggs, "wordwrap" };
#line 214 Strings.tt

# ========================================================================

=head1 FUNCTIONS ACTUALLY IMPLEMENTED

Just in case you missed which functions were actually implemented
in that huge mass of unimplemented functions, here's the condensed list
of implemented functions:

=over 4


=item *

L<"addcslashes">

=item *

L<"chunk_split">

=item *

L<"count_chars">

=item *

L<"money_format">

=item *

L<"number_format">

=item *

L<"similar_text">

=item *

L<"str_pad">

=item *

L<"str_shuffle">

=item *

L<"str_word_count">

=item *

L<"strip_tags">

=item *

L<"stripcslashes">

=item *

L<"strtr">

=back

=head1 BAD EGGS

All functions that I think are worthless are still exportable, with the
exception of any that would clash with a Perl builtin function.

If you try to actually use said function, a big fat error will result.

=cut

BEGIN {
    $EXPORT_TAGS{$_} = [ $_ ] for @badeggs;
}

=begin _private

=head1 XS

Some functions are implemented in C. This is done either out of ease of
programming (L<"money_format"> is just a façade for strfmon(3)), or
because C is sometimes just the right tool (mainly in dealing with
individual character manipulation of strings).

=cut

require XSLoader;
XSLoader::load('PHP::Strings', $VERSION);

=end _private

=cut

1;

__END__

=head1 FOR THOSE WHO HAVE READ THIS FAR

Yes, this module is mostly a joke. I wrote a lot of it after
being asked for the hundredth time: What's the equivalent to
PHP's X in Perl?

That said, although it's a joke, I'm happy to receive
amendments, additions and such. It's incomplete at present,
and I would like to see it complete at some point.

In particular, the test suite needs a lot of work. (If you
feel like it. Hint Hint.)

If you want to implement some of the functions that I've
said will not be implemented, then I'll be happy to include
them. After all, what I think is worthless is my opinion.

=head1 BUGS, REQUESTS, COMMENTS

Log them via the CPAN RT system via the web or email:

    http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PHP-Strings
    ( shorter URL: http://xrl.us/4at )

    bug-php-strings@rt.cpan.org

This makes it much easier for me to track things and thus means
your problem is less likely to be neglected.

=head1 THANKS

Andy Lester (PETDANCE) for taking care of Iain's modules.

Juerd Waalboer (JUERD) for suggesting a link, and the assorted regex
functions.

Matthew Persico (PERSICOM) for the idea of having the
functions give their documentation as their error.

=head1 LICENCE AND COPYRIGHT

PHP::Strings modifications from version 0.27 are copyright 
E<copy> Petras Kudaras. All rights reserved.

PHP::Strings is copyright E<copy> Iain Truskett, 2003. All rights
reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.000 or,
at your option, any later version of Perl 5 you may have available.

The full text of the licences can be found in the F<Artistic> and
F<COPYING> files included with this module, or in L<perlartistic> and
L<perlgpl> as supplied with Perl 5.8.1 and later.

=head1 AUTHORS

Iain Truskett <spoon@cpan.org>
Petras Kudaras <kudarasp@cpan.org>

=head1 SEE ALSO

L<perl>, L<php>.

=cut
