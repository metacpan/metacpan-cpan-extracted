package Search::Tools::UTF8;
use strict;
use warnings;
use Carp;
use Search::Tools;    # XS stuff
use Encode;
use charnames ':full';
use Data::Dump qw( dump );
use base qw( Exporter );
our @EXPORT = qw(
    to_utf8
    is_valid_utf8
    is_flagged_utf8
    is_perl_utf8_string
    is_ascii
    is_latin1
    is_sane_utf8
    find_bad_utf8
    find_bad_ascii
    find_bad_latin1
    find_bad_latin1_report
    byte_length
    looks_like_cp1252
    fix_cp1252_codepoints_in_utf8
    debug_bytes
);

our $Debug = ( $ENV{PERL_DEBUG} && $ENV{PERL_DEBUG} > 2 ) ? 1 : 0;

our $VERSION = '1.007';

sub to_utf8 {
    my $str = shift;
    Carp::cluck("\$str is undefined") unless defined $str;

    my $charset = shift || 'iso-8859-1';

    # checks first
    if ( is_flagged_utf8($str) ) {
        $Debug and carp "string '$str' is flagged utf8 already";
        return $str;
    }
    if ( is_ascii($str) ) {
        Encode::_utf8_on($str);
        $Debug and carp "string '$str' is ascii; utf8 flag turned on";
        return $str;
    }
    if ( is_valid_utf8($str) ) {

        # we got here only because the flag was off and it wasn't ascii.
        # however, is_valid_utf8() claims that it is valid internal UTF8,
        # so just turn the flag on.
        Encode::_utf8_on($str);
        $Debug and carp "string '$str' is valid utf8; utf8 flag turned on";
        return $str;
    }

    $Debug
        and carp "converting $str from $charset -> utf8";
    my $c = Encode::decode( $charset, $str );
    $Debug and carp "converted $c";

    unless ( is_sane_utf8( $c, 1 ) ) {
        carp "not sane: $c";
    }

    return $c;
}

sub is_flagged_utf8 {
    return Encode::is_utf8( $_[0] );
}

my $re_bit = join "|",
    map { Encode::encode( "utf8", chr($_) ) } ( 127 .. 255 );

#binmode STDERR, ":utf8";
#print STDERR $re_bit;

sub is_sane_utf8 {
    my $string = shift;
    my $warnings = shift || $Debug || 0;

    my $is_insane = 0;
    while ( $string =~ /($re_bit)/go ) {

        # work out what the double encoded string was
        my $bytes = $1;

        my $index = $+[0] - length($bytes);
        my $codes = join '', map { sprintf '<%00x>', ord($_) } split //,
            $bytes;

        # what character does that represent?
        my $char = Encode::decode( "utf8", $bytes );
        my $ord  = ord($char);
        my $hex  = sprintf '%00x', $ord;
        $char = charnames::viacode($ord);

        # print out diagnostic messages
        if ($warnings) {

            warn(qq{Found dodgy chars "$codes" at char $index\n});
            if ( Encode::is_utf8($string) ) {
                warn("Chars in utf8 string look like utf8 byte sequence.");
            }
            else {
                warn("String not flagged as utf8...was it meant to be?\n");
            }
            warn(
                "Probably originally a $char char - codepoint $ord (dec), $hex (hex)\n"
            );

        }
        $is_insane++;
    }

    return $is_insane ? 0 : 1;
}

sub is_valid_utf8 {
    if (   is_latin1( $_[0] )
        && !is_ascii( $_[0] )
        && !is_perl_utf8_string( $_[0] ) )
    {
        return 0;
    }
    return is_perl_utf8_string( $_[0] );
}

sub find_bad_latin1_report {
    my $bad = find_bad_latin1(@_);
    if ($bad) {

        # explain why we failed
        my $char = substr( $_[0], $bad, 1 );
        my $dec  = ord($char);
        my $hex  = sprintf '%x', $dec;
        carp("byte $bad ($char) is not Latin1 (it's $dec dec / $hex hex)");
    }
    return $bad;
}

sub looks_like_cp1252 {
    if (   !is_latin1( $_[0] )
        && !is_ascii( $_[0] )
        && $_[0] =~ m/[\x80-\x9f]/ )
    {
        return 1;
    }
    return 0;
}

my %win1252 = (
    "\x80" => "\x{20AC}",    #EURO SIGN
    "\x81" => '',            #UNDEFINED
    "\x82" => "\x{201A}",    #SINGLE LOW-9 QUOTATION MARK
    "\x83" => "\x{0192}",    #LATIN SMALL LETTER F WITH HOOK
    "\x84" => "\x{201E}",    #DOUBLE LOW-9 QUOTATION MARK
    "\x85" => "\x{2026}",    #HORIZONTAL ELLIPSIS
    "\x86" => "\x{2020}",    #DAGGER
    "\x87" => "\x{2021}",    #DOUBLE DAGGER
    "\x88" => "\x{02C6}",    #MODIFIER LETTER CIRCUMFLEX ACCENT
    "\x89" => "\x{2030}",    #PER MILLE SIGN
    "\x8A" => "\x{0160}",    #LATIN CAPITAL LETTER S WITH CARON
    "\x8B" => "\x{2039}",    #SINGLE LEFT-POINTING ANGLE QUOTATION MARK
    "\x8C" => "\x{0152}",    #LATIN CAPITAL LIGATURE OE
    "\x8D" => '',            #UNDEFINED
    "\x8E" => "\x{017D}",    #LATIN CAPITAL LETTER Z WITH CARON
    "\x8F" => '',            #UNDEFINED
    "\x90" => '',            #UNDEFINED
    "\x91" => "\x{2018}",    #LEFT SINGLE QUOTATION MARK
    "\x92" => "\x{2019}",    #RIGHT SINGLE QUOTATION MARK
    "\x93" => "\x{201C}",    #LEFT DOUBLE QUOTATION MARK
    "\x94" => "\x{201D}",    #RIGHT DOUBLE QUOTATION MARK
    "\x95" => "\x{2022}",    #BULLET
    "\x96" => "\x{2013}",    #EN DASH
    "\x97" => "\x{2014}",    #EM DASH
    "\x98" => "\x{02DC}",    #SMALL TILDE
    "\x99" => "\x{2122}",    #TRADE MARK SIGN
    "\x9A" => "\x{0161}",    #LATIN SMALL LETTER S WITH CARON
    "\x9B" => "\x{203A}",    #SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
    "\x9C" => "\x{0153}",    #LATIN SMALL LIGATURE OE
    "\x9D" => '',            #UNDEFINED
    "\x9E" => "\x{017E}",    #LATIN SMALL LETTER Z WITH CARON
    "\x9F" => "\x{0178}",    #LATIN CAPITAL LETTER Y WITH DIAERESIS

);

# fix_latin (used in Transliterate) lacks the check for the
# prefixed \xc2 byte, but the UTF-8 encoding for these
# Windows codepoints has the leading \xc2 byte.
sub fix_cp1252_codepoints_in_utf8 {
    my $buf = shift;
    unless ( is_valid_utf8($buf) ) {
        my $badbyte = find_bad_utf8($buf);
        croak "bad UTF-8 byte(s) at $badbyte [ " . dump($buf) . " ]";
    }
    $Debug and warn "converting $buf\n";
    my $bytes = Encode::encode_utf8( to_utf8($buf) );
    $bytes =~ s/\xc2([\x80-\x9f])/$win1252{$1}/g;
    return to_utf8($bytes);
}

1;

__END__

=pod

=head1 NAME

Search::Tools::UTF8 - UTF8 string wrangling

=head1 SYNOPSIS

 use Search::Tools::UTF8;
 
 my $str = 'foo bar baz';
 
 print "bad UTF-8 sequence: " . find_bad_utf8($str)
    unless is_valid_utf8($str);
 
 print "bad ascii byte at position " . find_bad_ascii($str)
    unless is_ascii($str);
 
 print "bad latin1 byte at position " . find_bad_latin1($str)
    unless is_latin1($str);
 
=head1 DESCRIPTION

Search::Tools::UTF8 supplies common UTF8-related functions.


=head1 FUNCTIONS

=head2 byte_length( I<text> )

Returns the number of bytes in I<text> regardless of encoding.

=head2 is_valid_utf8( I<text> )

Returns true if I<text> is a valid sequence of UTF-8 bytes,
regardless of how Perl has it flagged (is_utf8 or not).

=head2 is_ascii( I<text> )

If I<text> contains no bytes above 127, then returns true (1). Otherwise,
returns false (0). Used by convert() internally to check I<text> prior
to transliterating.

=head2 is_latin1( I<text> )

Returns true if I<text> lies within the Latin1 charset.

B<NOTE:> Only Latin1 octets with a valid representable character
are checked. Octets in the range \x80 - \x9f are not considered valid Latin1
and if found in I<text>, is_latin1() will return false.

B<CAUTION:> A string of bytes can be both valid Latin1 and valid UTF-8, even
though the string doesn't represent the same Unicode codepoint(s). Example:

 my $str = "\x{d9}\x{a6}";  # same as \x{666}
 is_valid_utf8($str);       # returns true
 is_latin1($str);           # returns true

Thus is_latin1() (and likewise find_bad_latin1()) are not foolproof. Use them
in combination with is_flagged_utf8() to get a better test.

=head2 is_flagged_utf8( I<text> )

Returns true if Perl thinks I<text> is UTF-8. Same as Encode::is_utf8().

=head2 is_perl_utf8_string( I<text> )

Wrapper around the native Perl is_utf8_string() function. Called
by is_valid_utf8().

=head2 is_sane_utf8( I<text> [,I<warnings>] )

Will test for double-y encoded I<text>. Returns true if I<text> looks ok.
From Text::utf8 docs:

 Strings that are not utf8 always automatically pass.

Pass a second true param to get diagnostics on stderr.

=head2 find_bad_utf8( I<text> )

Returns string of bad bytes from I<text>. This of course assumes that I<text>
is not valid UTF-8, so use it like:

 croak "bad bytes: " . find_bad_utf8($str) 
    unless is_valid_utf8($str);
    
If I<text> is a valid UTF-8 string, returns undef.

=head2 find_bad_ascii( I<text> )

Returns position of first non-ASCII byte or -1 if I<text> is all ASCII.

=head2 find_bad_latin1( I<text> )

Returns position of first non-Latin1 byte or -1 if I<text> is valid Latin1.

=head2 find_bad_latin1_report( I<text> )

Returns position of first non-Latin1 byte (like find_bad_latin1())
and also carps about what the decimal and hex values of the bad byte are.

=head2 to_utf8( I<text>, I<charset> )

Shorthand for running I<text> through appropriate is_*() checks and then
converting to UTF-8 if necessary. Returns I<text> encoded and flagged as UTF-8.

Returns undef if for some reason the encoding failed or the result did not pass
is_sane_utf8().

=head2 looks_like_cp1252( I<text> )

This function tests that there are bytes in I<text>
between B<0x80> and B<0x9f> inclusive.
Those bytes are used by the Windows-1252 character set and include some
of the troublesome characters like curly quotes.

See also fix_cp1252_codepoints_in_utf8()
and the Search::Tools::Transliterate convert1252() method.

=head2 fix_cp1252_codepoints_in_utf8( I<text> )

The Windows-1252 codepoints between B<0x80> and B<0x9f> may be encoded
validly as UTF-8 but the Unicode standard does not map any characters
at those codepoints. fix_cp1252_codepoints_in_utf8() converts
a UTF-8 encoded string I<text> to map the suspect 1252 codepoints to
their correct Unicode representations.

Note that fix_cp1252_codepoints_in_utf8() is different from the fix_latin()
function used in Transliterate, which does not differentiate between
a Windows-1252 encoded string and a UTF-8 encoded string.

This function will croak if I<text> does not pass is_valid_utf8().

=head2 debug_bytes( I<text> )

Iterates over each byte in I<text>, printing byte, hex and decimal values
to stderr.

=head1 AUTHOR

Peter Karman C<< <karman@cpan.org> >>

Originally based on the HTML::HiLiter regular expression building code, 
by the same author, copyright 2004 by Cray Inc.

Thanks to Atomic Learning C<www.atomiclearning.com> 
for sponsoring the development of some of these modules.

Many of the UTF-8 tests come directly from Test::utf8.

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-tools at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Tools>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Tools


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Tools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Tools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Tools>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Tools/>

=back

=head1 COPYRIGHT

Copyright 2006-2009 by Peter Karman.

This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

HTML::HiLiter, SWISH::HiLiter, Class::XSAccessor, Text::Aspell

=cut
