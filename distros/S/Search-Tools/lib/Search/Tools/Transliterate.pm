package Search::Tools::Transliterate;
use Moo;
extends 'Search::Tools::Object';
use Search::Tools::UTF8;
use Carp;
use Encode;
use Encoding::FixLatin qw( fix_latin );
use Data::Dump qw( dump );

has 'ebit' => ( is => 'rw', default => sub {1} );
has 'map' => ( is => 'ro' );

our $VERSION = '1.007';

=pod

=head1 NAME

Search::Tools::Transliterate - transliterations of UTF-8 chars

=head1 SYNOPSIS

 my $tr = Search::Tools::Transliterate->new();
 print $tr->convert( 'some string of utf8 chars' );
 
=head1 DESCRIPTION

Search::Tools::Transliterate transliterates UTF-8 characters
to single-byte equivalents. It is based on the transmap project
by Markus Kuhn http://www.cl.cam.ac.uk/~mgk25/.

B<NOTE:> All the I<is_*> encoding check methods that existed in this class prior
to version 0.05 were moved to Search::Tools::UTF8 and refactored as functions,
many using XS for speed improvements.


=head1 METHODS

=head2 new

Create new instance. Takes the following optional parameters:

=over

=item map

Customize the character mapping. Should be a hashref. See map() method.

=item ebit

Allow convert() to use full native 8bit characters for transliterating, 
rather than only 7bit ASCII. The default is true (1). Set to 0 to disable.
B<NOTE:> This must be set in new(). Changing via the accessor
after new() will have no effect on map().

=back

=head2 BUILD

Called internally by new().

=head2 map

Access the transliteration character map. Example:

 use Search::Tools::Transliterate;
 my $tr = Search::Tools::Transliterate->new;
 $tr->map->{mychar} = 'my transliteration';
 print $tr->convert('mychar');  # prints 'my transliteration'

NOTE: The map() method is an accessor only. You can not pass in a new map.


=head2 convert( I<text> )

Returns UTF-8 I<text> converted with all single bytes, transliterated according
to %Map. Will croak if I<text> is not valid UTF-8, so if in doubt, check first with
is_valid_utf8() in Search::Tools::UTF8.

=head2 convert1252( I<text> )

Returns UTF-8 I<text> converted to all single byte characters,
transliterated with convert() and the Windows 1252 characters in the range
B<0x80> and B<0x9f> inclusive. 

The 1252 codepoints are converted first to
their UTF-8 counterparts per 
http://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1252.TXT
using Encoding::FixLatin::fix_latin() and then 
I<text> is run through convert().

Note that I<text> is checked with the looks_like_cp1252() function from
Search::Tools::UTF8 before calling fix_latin().

=head1 BUGS

You might consider the whole attempt as a bug. It's really an attempt to 
accomodate applications that don't support Unicode. Perhaps we shouldn't even
try. But for things like curly quotes and other 'smart' punctuation, it's often
helpful to render the UTF-8 character as B<something> rather than just letting
a character without a direct translation slip into the ether.

That said, if a character has no mapping (and there are plenty that do not)
a single space will be used.

=head1 AUTHOR

Peter Karman C<< <karman@cpan.org> >>

Originally based on the HTML::HiLiter regular expression building code, 
by the same author, copyright 2004 by Cray Inc.

Thanks to Atomic Learning C<www.atomiclearning.com> 
for sponsoring the development of some of these modules.

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

Copyright 2006-2010 by Peter Karman.

This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

Search::Tools::UTF8, Unicode::Map, Encode, Test::utf8, Encoding::FixLatin

=cut

# must memoize <DATA> the first time since if we call new()
# more than once, <DATA> has already been iterated over
# and _init_map() will end up returning empty hash.
my %MAP;

sub _init_map {
    my $self = shift;

    return {%MAP} if %MAP;

    while (<DATA>) {
        chomp;
        next unless m/^<U/;
        my ( $from, $to ) = (m/^(<U.+?>)\ (.+)$/);
        if ( !defined $to ) {
            warn "Undefined mapping for $_\n";
            next;
        }
        my @o = split( /;/, $to );
        $MAP{ _Utag_to_chr($from) } = _Utag_to_chr( $o[0] );
    }

    return {%MAP};
}

sub _Utag_to_chr {
    my $t = shift;

    # cruft
    $t =~ s/[<>"]+//g;

    $t =~ s,U([0-9A-F]+),chr( hex($1) ),oge;
    return $t;
}

sub BUILD {
    my $self = shift;

    my $map = $self->_init_map;

    # add/override 8bit chars
    if ( $self->ebit ) {
        $self->debug and warn "ebit on\n";
        for ( 128 .. 255 ) {
            my $c = chr($_);
            $self->debug and warn "chr $_ -> $c\n";
            $map->{$c} = $c;
        }
    }

    if ( $self->{map} ) {
        $map->{$_} = $self->{map}->{$_} for keys %{ $self->{map} };
    }
    $self->{map} = $map;
}

# benchmark shows this is 244% faster than previous version.
sub convert {
    my ( $self, $buf ) = @_;
    my $newbuf = '';

    # don't bother unless we have non-ascii bytes
    return $buf if is_ascii($buf);

    # make sure we've got valid UTF-8 to start with
    unless ( is_valid_utf8($buf) ) {
        my $badbyte = find_bad_utf8($buf);
        croak "bad UTF-8 byte(s) at $badbyte [ " . dump($buf) . " ]";
    }

    # an alternate algorithm. no idea if it is faster.
    # it depends on Perl's utf8 char matching (.)
    # which should work if locale is correct, afaik.
    my $map = $self->map;

    $self->debug and warn "converting $buf\n";
    while ( $buf =~ m/(.)/gso ) {
        my $char = $1;
        $self->debug and warn "$char\n";
        if ( is_ascii($char) ) {
            $self->debug and warn "$char is_ascii\n";
            $newbuf .= $char;
        }
        elsif ( !exists $map->{$char} ) {
            $self->debug and warn "$char not in map\n";
            $newbuf .= ' ';
        }
        else {
            $self->debug and warn "transliterate $char => $map->{$char}\n";
            $newbuf .= $map->{$char};
        }

    }

    return $newbuf;
}

sub convert1252 {
    my ( $self, $buf ) = @_;

    # don't bother unless we have non-ascii bytes
    return $buf if is_ascii($buf);

    $self->debug and warn "converting $buf\n";
    my $newbuf = looks_like_cp1252($buf) ? fix_latin($buf) : $buf;
    return $self->convert($newbuf);
}

1;

# map taken directly from
# http://www.cl.cam.ac.uk/~mgk25/download/transtab.tar.gz
# by Markus Kuhn

__DATA__
<U0027> <U2019>
<U0060> <U201B>;<U2018>
<U00A0> <U0020>
<U00A1> <U0021>
<U00A2> <U0063>
<U00A3> "<U0047><U0042><U0050>"
<U00A5> <U0059>
<U00A6> <U007C>
<U00A7> <U0053>
<U00A8> <U0022>
<U00A9> "<U0028><U0063><U0029>";<U0063>
<U00AA> <U0061>
<U00AB> "<U003C><U003C>"
<U00AC> <U002D>
<U00AD> <U002D>
<U00AE> "<U0028><U0052><U0029>"
<U00AF> <U002D>
<U00B0> <U0020>
<U00B1> "<U002B><U002F><U002D>"
<U00B2> "<U005E><U0032>";<U0032>
<U00B3> "<U005E><U0033>";<U0033>
<U00B4> <U0027>
<U00B5> <U03BC>;<U0075>
<U00B6> <U0050>
<U00B7> <U002E>
<U00B8> <U002C>
<U00B9> "<U005E><U0031>";<U0031>
<U00BA> <U006F>
<U00BB> "<U003E><U003E>"
<U00BC> "<U0020><U0031><U002F><U0034>"
<U00BD> "<U0020><U0031><U002F><U0032>"
<U00BE> "<U0020><U0033><U002F><U0034>"
<U00BF> <U003F>
<U00C0> <U0041>
<U00C1> <U0041>
<U00C2> <U0041>
<U00C3> <U0041>
<U00C4> "<U0041><U0065>";<U0041>
<U00C5> "<U0041><U0061>";<U0041>
<U00C6> "<U0041><U0045>";<U0041>
<U00C7> <U0043>
<U00C8> <U0045>
<U00C9> <U0045>
<U00CA> <U0045>
<U00CB> <U0045>
<U00CC> <U0049>
<U00CD> <U0049>
<U00CE> <U0049>
<U00CF> <U0049>
<U00D0> <U0044>
<U00D1> <U004E>
<U00D2> <U004F>
<U00D3> <U004F>
<U00D4> <U004F>
<U00D5> <U004F>
<U00D6> "<U004F><U0065>";<U004F>
<U00D7> <U0078>
<U00D8> <U004F>
<U00D9> <U0055>
<U00DA> <U0055>
<U00DB> <U0055>
<U00DC> "<U0055><U0065>";<U0055>
<U00DD> <U0059>
<U00DE> "<U0054><U0068>"
<U00DF> "<U0073><U0073>";<U03B2>
<U00E0> <U0061>
<U00E1> <U0061>
<U00E2> <U0061>
<U00E3> <U0061>
<U00E4> "<U0061><U0065>";<U0061>
<U00E5> "<U0061><U0061>";<U0061>
<U00E6> "<U0061><U0065>";<U0061>
<U00E7> <U0063>
<U00E8> <U0065>
<U00E9> <U0065>
<U00EA> <U0065>
<U00EB> <U0065>
<U00EC> <U0069>
<U00ED> <U0069>
<U00EE> <U0069>
<U00EF> <U0069>
<U00F0> <U0064>
<U00F1> <U006E>
<U00F2> <U006F>
<U00F3> <U006F>
<U00F4> <U006F>
<U00F5> <U006F>
<U00F6> "<U006F><U0065>";<U006F>
<U00F7> <U003A>
<U00F8> <U006F>
<U00F9> <U0075>
<U00FA> <U0075>
<U00FB> <U0075>
<U00FC> "<U0075><U0065>";<U0075>
<U00FD> <U0079>
<U00FE> "<U0074><U0068>"
<U00FF> <U0079>
<U0100> <U0041>
<U0101> <U0061>
<U0102> <U0041>
<U0103> <U0061>
<U0104> <U0041>
<U0105> <U0061>
<U0106> <U0043>
<U0107> <U0063>
<U0108> "<U0043><U0068>";<U0043>
<U0109> "<U0063><U0068>";<U0063>
<U010A> <U0043>
<U010B> <U0063>
<U010C> <U0043>
<U010D> <U0063>
<U010E> <U0044>
<U010F> <U0064>
<U0110> <U0044>
<U0111> <U0064>
<U0112> <U0045>
<U0113> <U0065>
<U0114> <U0045>
<U0115> <U0065>
<U0116> <U0045>
<U0117> <U0065>
<U0118> <U0045>
<U0119> <U0065>
<U011A> <U0045>
<U011B> <U0065>
<U011C> "<U0047><U0068>";<U0047>
<U011D> "<U0067><U0068>";<U0067>
<U011E> <U0047>
<U011F> <U0067>
<U0120> <U0047>
<U0121> <U0067>
<U0122> <U0047>
<U0123> <U0067>
<U0124> "<U0048><U0068>";<U0048>
<U0125> "<U0068><U0068>";<U0068>
<U0126> <U0048>
<U0127> <U0068>
<U0128> <U0049>
<U0129> <U0069>
<U012A> <U0049>
<U012B> <U0069>
<U012C> <U0049>
<U012D> <U0069>
<U012E> <U0049>
<U012F> <U0069>
<U0130> <U0049>
<U0131> <U0069>
<U0132> "<U0049><U004A>"
<U0133> "<U0069><U006A>"
<U0134> "<U004A><U0068>";<U004A>
<U0135> "<U006A><U0068>";<U006A>
<U0136> <U004B>
<U0137> <U006B>
<U0138> <U006B>
<U0139> <U004C>
<U013A> <U006C>
<U013B> <U004C>
<U013C> <U006C>
<U013D> <U004C>
<U013E> <U006C>
<U013F> "<U004C><U00B7>";"<U004C><U002E>";<U004C>
<U0140> "<U006C><U00B7>";"<U006C><U002E>";<U006C>
<U0141> <U004C>
<U0142> <U006C>
<U0143> <U004E>
<U0144> <U006E>
<U0145> <U004E>
<U0146> <U006E>
<U0147> <U004E>
<U0148> <U006E>
<U0149> "<U0027><U006E>"
<U014A> "<U004E><U0047>";<U004E>
<U014B> "<U006E><U0067>";<U006E>
<U014C> <U004F>
<U014D> <U006F>
<U014E> <U004F>
<U014F> <U006F>
<U0150> <U004F>
<U0151> <U006F>
<U0152> "<U004F><U0045>"
<U0153> "<U006F><U0065>"
<U0154> <U0052>
<U0155> <U0072>
<U0156> <U0052>
<U0157> <U0072>
<U0158> <U0052>
<U0159> <U0072>
<U015A> <U0053>
<U015B> <U0073>
<U015C> "<U0053><U0068>";<U0053>
<U015D> "<U0073><U0068>";<U0073>
<U015E> <U0053>
<U015F> <U0073>
<U0160> <U0053>
<U0161> <U0073>
<U0162> <U0054>
<U0163> <U0074>
<U0164> <U0054>
<U0165> <U0074>
<U0166> <U0054>
<U0167> <U0074>
<U0168> <U0055>
<U0169> <U0075>
<U016A> <U0055>
<U016B> <U0075>
<U016C> <U0055>
<U016D> <U0075>
<U016E> <U0055>
<U016F> <U0075>
<U0170> <U0055>
<U0171> <U0075>
<U0172> <U0055>
<U0173> <U0075>
<U0174> <U0057>
<U0175> <U0077>
<U0176> <U0059>
<U0177> <U0079>
<U0178> <U0059>
<U0179> <U005A>
<U017A> <U007A>
<U017B> <U005A>
<U017C> <U007A>
<U017D> <U005A>
<U017E> <U007A>
<U017F> <U0073>
<U0192> <U0066>
<U0218> <U015E>;<U0053>
<U0219> <U015F>;<U0073>
<U021A> <U0162>;<U0054>
<U021B> <U0163>;<U0074>
<U02B9> <U2032>;<U0027>
<U02BB> <U2018>
<U02BC> <U2019>;<U0027>
<U02BD> <U201B>
<U02C6> <U005E>
<U02C8> <U0027>
<U02C9> <U00AF>
<U02CC> <U002C>
<U02D0> <U003A>
<U02DA> <U00B0>
<U02DC> <U007E>
<U02DD> <U0022>
<U0374> <U0027>
<U0375> <U002C>
<U037E> <U003B>
<U1E02> <U0042>
<U1E03> <U0062>
<U1E0A> <U0044>
<U1E0B> <U0064>
<U1E1E> <U0046>
<U1E1F> <U0066>
<U1E40> <U004D>
<U1E41> <U006D>
<U1E56> <U0050>
<U1E57> <U0070>
<U1E60> <U0053>
<U1E61> <U0073>
<U1E6A> <U0054>
<U1E6B> <U0074>
<U1E80> <U0057>
<U1E81> <U0077>
<U1E82> <U0057>
<U1E83> <U0077>
<U1E84> <U0057>
<U1E85> <U0077>
<U1EF2> <U0059>
<U1EF3> <U0079>
<U2000> <U0020>
<U2001> "<U0020><U0020>"
<U2002> <U0020>
<U2003> "<U0020><U0020>"
<U2004> <U0020>
<U2005> <U0020>
<U2006> <U0020>
<U2007> <U0020>
<U2008> <U0020>
<U2009> <U0020>
<U200A> ""
<U200B> ""
<U200C> ""
<U200D> ""
<U200E> ""
<U200F> ""
<U2010> <U002D>
<U2011> <U002D>
<U2012> <U002D>
<U2013> <U002D>
<U2014> "<U002D><U002D>"
<U2015> "<U002D><U002D>"
<U2016> "<U007C><U007C>"
<U2017> <U005F>
<U2018> <U0027>
<U2019> <U0027>
<U201A> <U0027>
<U201B> <U0027>
<U201C> <U0022>
<U201D> <U0022>
<U201E> <U0022>
<U201F> <U0022>
<U2020> <U002B>
<U2021> "<U002B><U002B>"
<U2022> <U006F>
<U2023> <U003E>
<U2024> <U002E>
<U2025> "<U002E><U002E>"
<U2026> "<U002E><U002E><U002E>"
<U2027> <U002D>
<U202A> ""
<U202B> ""
<U202C> ""
<U202D> ""
<U202E> ""
<U202F> <U0020>
<U2030> "<U0020><U0030><U002F><U0030><U0030>"
<U2032> <U0027>
<U2033> <U0022>
<U2034> "<U0027><U0027><U0027>"
<U2035> <U0060>
<U2036> "<U0060><U0060>"
<U2037> "<U0060><U0060><U0060>"
<U2039> <U003C>
<U203A> <U003E>
<U203C> "<U0021><U0021>"
<U203E> <U002D>
<U2043> <U002D>
<U2044> <U002F>
<U2048> "<U003F><U0021>"
<U2049> "<U0021><U003F>"
<U204A> <U0037>
<U2070> "<U005E><U0030>";<U0030>
<U2074> "<U005E><U0034>";<U0034>
<U2075> "<U005E><U0035>";<U0035>
<U2076> "<U005E><U0036>";<U0036>
<U2077> "<U005E><U0037>";<U0037>
<U2078> "<U005E><U0038>";<U0038>
<U2079> "<U005E><U0039>";<U0039>
<U207A> "<U005E><U002B>";<U002B>
<U207B> "<U005E><U002D>";<U002D>
<U207C> "<U005E><U003D>";<U003D>
<U207D> "<U005E><U0028>";<U0028>
<U207E> "<U005E><U0029>";<U0029>
<U207F> "<U005E><U006E>";<U006E>
<U2080> "<U005F><U0030>";<U0030>
<U2081> "<U005F><U0031>";<U0031>
<U2082> "<U005F><U0032>";<U0032>
<U2083> "<U005F><U0033>";<U0033>
<U2084> "<U005F><U0034>";<U0034>
<U2085> "<U005F><U0035>";<U0035>
<U2086> "<U005F><U0036>";<U0036>
<U2087> "<U005F><U0037>";<U0037>
<U2088> "<U005F><U0038>";<U0038>
<U2089> "<U005F><U0039>";<U0039>
<U208A> "<U005F><U002B>";<U002B>
<U208B> "<U005F><U002D>";<U002D>
<U208C> "<U005F><U003D>";<U003D>
<U208D> "<U005F><U0028>";<U0028>
<U208E> "<U005F><U0029>";<U0029>
<U20AC> "<U0045><U0055><U0052>";<U0045>
<U2100> "<U0061><U002F><U0063>"
<U2101> "<U0061><U002F><U0073>"
<U2103> "<U00B0><U0043>";<U0043>
<U2105> "<U0063><U002F><U006F>"
<U2106> "<U0063><U002F><U0075>"
<U2109> "<U00B0><U0046>";<U0046>
<U2113> <U006C>
<U2116> "<U004E><U00BA>";"<U004E><U006F>"
<U2117> "<U0028><U0050><U0029>"
<U2120> "<U005B><U0053><U004D><U005D>"
<U2121> "<U0054><U0045><U004C>"
<U2122> "<U005B><U0054><U004D><U005D>"
<U2126> <U03A9>;"<U006F><U0068><U006D>";<U004F>
<U212A> <U004B>
<U212B> <U00C5>
<U212E> <U0065>
<U2153> "<U0020><U0031><U002F><U0033>"
<U2154> "<U0020><U0032><U002F><U0033>"
<U2155> "<U0020><U0031><U002F><U0035>"
<U2156> "<U0020><U0032><U002F><U0035>"
<U2157> "<U0020><U0033><U002F><U0035>"
<U2158> "<U0020><U0034><U002F><U0035>"
<U2159> "<U0020><U0031><U002F><U0036>"
<U215A> "<U0020><U0035><U002F><U0036>"
<U215B> "<U0020><U0031><U002F><U0038>"
<U215C> "<U0020><U0033><U002F><U0038>"
<U215D> "<U0020><U0035><U002F><U0038>"
<U215E> "<U0020><U0037><U002F><U0038>"
<U215F> "<U0020><U0031><U002F>"
<U2160> <U0049>
<U2161> "<U0049><U0049>"
<U2162> "<U0049><U0049><U0049>"
<U2163> "<U0049><U0056>"
<U2164> <U0056>
<U2165> "<U0056><U0049>"
<U2166> "<U0056><U0049><U0049>"
<U2167> "<U0056><U0049><U0049><U0049>"
<U2168> "<U0049><U0058>"
<U2169> <U0058>
<U216A> "<U0058><U0049>"
<U216B> "<U0058><U0049><U0049>"
<U216C> <U004C>
<U216D> <U0043>
<U216E> <U0044>
<U216F> <U004D>
<U2170> <U0069>
<U2171> "<U0069><U0069>"
<U2172> "<U0069><U0069><U0069>"
<U2173> "<U0069><U0076>"
<U2174> <U0076>
<U2175> "<U0076><U0069>"
<U2176> "<U0076><U0069><U0069>"
<U2177> "<U0076><U0069><U0069><U0069>"
<U2178> "<U0069><U0078>"
<U2179> <U0078>
<U217A> "<U0078><U0069>"
<U217B> "<U0078><U0069><U0069>"
<U217C> <U006C>
<U217D> <U0063>
<U217E> <U0064>
<U217F> <U006D>
<U2190> "<U003C><U002D>"
<U2191> <U005E>
<U2192> "<U002D><U003E>"
<U2193> <U0076>
<U2194> "<U003C><U002D><U003E>"
<U21D0> "<U003C><U003D>"
<U21D2> "<U003D><U003E>"
<U21D4> "<U003C><U003D><U003E>"
<U2212> <U2013>;<U002D>
<U2215> <U002F>
<U2216> <U005C>
<U2217> <U002A>
<U2218> <U006F>
<U2219> <U00B7>
<U221E> "<U0069><U006E><U0066>"
<U2223> <U007C>
<U2225> "<U007C><U007C>"
<U2236> <U003A>
<U223C> <U007E>
<U2260> "<U002F><U003D>"
<U2261> <U003D>
<U2264> "<U003C><U003D>"
<U2265> "<U003E><U003D>"
<U226A> "<U003C><U003C>"
<U226B> "<U003E><U003E>"
<U2295> "<U0028><U002B><U0029>"
<U2296> "<U0028><U002D><U0029>"
<U2297> "<U0028><U0078><U0029>"
<U2298> "<U0028><U002F><U0029>"
<U22A2> "<U007C><U002D>"
<U22A3> "<U002D><U007C>"
<U22A6> "<U007C><U002D>"
<U22A7> "<U007C><U003D>"
<U22A8> "<U007C><U003D>"
<U22A9> "<U007C><U007C><U002D>"
<U22C5> <U00B7>
<U22C6> <U002A>
<U22D5> <U0023>
<U22D8> "<U003C><U003C><U003C>"
<U22D9> "<U003E><U003E><U003E>"
<U22EF> "<U002E><U002E><U002E>"
<U2329> <U003C>
<U232A> <U003E>
<U2400> "<U004E><U0055><U004C>"
<U2401> "<U0053><U004F><U0048>"
<U2402> "<U0053><U0054><U0058>"
<U2403> "<U0045><U0054><U0058>"
<U2404> "<U0045><U004F><U0054>"
<U2405> "<U0045><U004E><U0051>"
<U2406> "<U0041><U0043><U004B>"
<U2407> "<U0042><U0045><U004C>"
<U2408> "<U0042><U0053>"
<U2409> "<U0048><U0054>"
<U240A> "<U004C><U0046>"
<U240B> "<U0056><U0054>"
<U240C> "<U0046><U0046>"
<U240D> "<U0043><U0052>"
<U240E> "<U0053><U004F>"
<U240F> "<U0053><U0049>"
<U2410> "<U0044><U004C><U0045>"
<U2411> "<U0044><U0043><U0031>"
<U2412> "<U0044><U0043><U0032>"
<U2413> "<U0044><U0043><U0033>"
<U2414> "<U0044><U0043><U0034>"
<U2415> "<U004E><U0041><U004B>"
<U2416> "<U0053><U0059><U004E>"
<U2417> "<U0045><U0054><U0042>"
<U2418> "<U0043><U0041><U004E>"
<U2419> "<U0045><U004D>"
<U241A> "<U0053><U0055><U0042>"
<U241B> "<U0045><U0053><U0043>"
<U241C> "<U0046><U0053>"
<U241D> "<U0047><U0053>"
<U241E> "<U0052><U0053>"
<U241F> "<U0055><U0053>"
<U2420> "<U0053><U0050>"
<U2421> "<U0044><U0045><U004C>"
<U2423> <U005F>
<U2424> "<U004E><U004C>"
<U2425> "<U002F><U002F><U002F>"
<U2426> <U003F>
<U2460> "<U0028><U0031><U0029>";<U0031>
<U2461> "<U0028><U0032><U0029>";<U0032>
<U2462> "<U0028><U0033><U0029>";<U0033>
<U2463> "<U0028><U0034><U0029>";<U0034>
<U2464> "<U0028><U0035><U0029>";<U0035>
<U2465> "<U0028><U0036><U0029>";<U0036>
<U2466> "<U0028><U0037><U0029>";<U0037>
<U2467> "<U0028><U0038><U0029>";<U0038>
<U2468> "<U0028><U0039><U0029>";<U0039>
<U2469> "<U0028><U0031><U0030><U0029>"
<U246A> "<U0028><U0031><U0031><U0029>"
<U246B> "<U0028><U0031><U0032><U0029>"
<U246C> "<U0028><U0031><U0033><U0029>"
<U246D> "<U0028><U0031><U0034><U0029>"
<U246E> "<U0028><U0031><U0035><U0029>"
<U246F> "<U0028><U0031><U0036><U0029>"
<U2470> "<U0028><U0031><U0037><U0029>"
<U2471> "<U0028><U0031><U0038><U0029>"
<U2472> "<U0028><U0031><U0039><U0029>"
<U2473> "<U0028><U0032><U0030><U0029>"
<U2474> "<U0028><U0031><U0029>";<U0031>
<U2475> "<U0028><U0032><U0029>";<U0032>
<U2476> "<U0028><U0033><U0029>";<U0033>
<U2477> "<U0028><U0034><U0029>";<U0034>
<U2478> "<U0028><U0035><U0029>";<U0035>
<U2479> "<U0028><U0036><U0029>";<U0036>
<U247A> "<U0028><U0037><U0029>";<U0037>
<U247B> "<U0028><U0038><U0029>";<U0038>
<U247C> "<U0028><U0039><U0029>";<U0039>
<U247D> "<U0028><U0031><U0030><U0029>"
<U247E> "<U0028><U0031><U0031><U0029>"
<U247F> "<U0028><U0031><U0032><U0029>"
<U2480> "<U0028><U0031><U0033><U0029>"
<U2481> "<U0028><U0031><U0034><U0029>"
<U2482> "<U0028><U0031><U0035><U0029>"
<U2483> "<U0028><U0031><U0036><U0029>"
<U2484> "<U0028><U0031><U0037><U0029>"
<U2485> "<U0028><U0031><U0038><U0029>"
<U2486> "<U0028><U0031><U0039><U0029>"
<U2487> "<U0028><U0032><U0030><U0029>"
<U2488> "<U0031><U002E>";<U0031>
<U2489> "<U0032><U002E>";<U0032>
<U248A> "<U0033><U002E>";<U0033>
<U248B> "<U0034><U002E>";<U0034>
<U248C> "<U0035><U002E>";<U0035>
<U248D> "<U0036><U002E>";<U0036>
<U248E> "<U0037><U002E>";<U0037>
<U248F> "<U0038><U002E>";<U0038>
<U2490> "<U0039><U002E>";<U0039>
<U2491> "<U0031><U0030><U002E>"
<U2492> "<U0031><U0031><U002E>"
<U2493> "<U0031><U0032><U002E>"
<U2494> "<U0031><U0033><U002E>"
<U2495> "<U0031><U0034><U002E>"
<U2496> "<U0031><U0035><U002E>"
<U2497> "<U0031><U0036><U002E>"
<U2498> "<U0031><U0037><U002E>"
<U2499> "<U0031><U0038><U002E>"
<U249A> "<U0031><U0039><U002E>"
<U249B> "<U0032><U0030><U002E>"
<U249C> "<U0028><U0061><U0029>";<U0061>
<U249D> "<U0028><U0062><U0029>";<U0062>
<U249E> "<U0028><U0063><U0029>";<U0063>
<U249F> "<U0028><U0064><U0029>";<U0064>
<U24A0> "<U0028><U0065><U0029>";<U0065>
<U24A1> "<U0028><U0066><U0029>";<U0066>
<U24A2> "<U0028><U0067><U0029>";<U0067>
<U24A3> "<U0028><U0068><U0029>";<U0068>
<U24A4> "<U0028><U0069><U0029>";<U0069>
<U24A5> "<U0028><U006A><U0029>";<U006A>
<U24A6> "<U0028><U006B><U0029>";<U006B>
<U24A7> "<U0028><U006C><U0029>";<U006C>
<U24A8> "<U0028><U006D><U0029>";<U006D>
<U24A9> "<U0028><U006E><U0029>";<U006E>
<U24AA> "<U0028><U006F><U0029>";<U006F>
<U24AB> "<U0028><U0070><U0029>";<U0070>
<U24AC> "<U0028><U0071><U0029>";<U0071>
<U24AD> "<U0028><U0072><U0029>";<U0072>
<U24AE> "<U0028><U0073><U0029>";<U0073>
<U24AF> "<U0028><U0074><U0029>";<U0074>
<U24B0> "<U0028><U0075><U0029>";<U0075>
<U24B1> "<U0028><U0076><U0029>";<U0076>
<U24B2> "<U0028><U0077><U0029>";<U0077>
<U24B3> "<U0028><U0078><U0029>";<U0078>
<U24B4> "<U0028><U0079><U0029>";<U0079>
<U24B5> "<U0028><U007A><U0029>";<U007A>
<U24B6> "<U0028><U0041><U0029>";<U0041>
<U24B7> "<U0028><U0042><U0029>";<U0042>
<U24B8> "<U0028><U0043><U0029>";<U0043>
<U24B9> "<U0028><U0044><U0029>";<U0044>
<U24BA> "<U0028><U0045><U0029>";<U0045>
<U24BB> "<U0028><U0046><U0029>";<U0046>
<U24BC> "<U0028><U0047><U0029>";<U0047>
<U24BD> "<U0028><U0048><U0029>";<U0048>
<U24BE> "<U0028><U0049><U0029>";<U0049>
<U24BF> "<U0028><U004A><U0029>";<U004A>
<U24C0> "<U0028><U004B><U0029>";<U004B>
<U24C1> "<U0028><U004C><U0029>";<U004C>
<U24C2> "<U0028><U004D><U0029>";<U004D>
<U24C3> "<U0028><U004E><U0029>";<U004E>
<U24C4> "<U0028><U004F><U0029>";<U004F>
<U24C5> "<U0028><U0050><U0029>";<U0050>
<U24C6> "<U0028><U0051><U0029>";<U0051>
<U24C7> "<U0028><U0052><U0029>";<U0052>
<U24C8> "<U0028><U0053><U0029>";<U0053>
<U24C9> "<U0028><U0054><U0029>";<U0054>
<U24CA> "<U0028><U0055><U0029>";<U0055>
<U24CB> "<U0028><U0056><U0029>";<U0056>
<U24CC> "<U0028><U0057><U0029>";<U0057>
<U24CD> "<U0028><U0058><U0029>";<U0058>
<U24CE> "<U0028><U0059><U0029>";<U0059>
<U24CF> "<U0028><U005A><U0029>";<U005A>
<U24D0> "<U0028><U0061><U0029>";<U0061>
<U24D1> "<U0028><U0062><U0029>";<U0062>
<U24D2> "<U0028><U0063><U0029>";<U0063>
<U24D3> "<U0028><U0064><U0029>";<U0064>
<U24D4> "<U0028><U0065><U0029>";<U0065>
<U24D5> "<U0028><U0066><U0029>";<U0066>
<U24D6> "<U0028><U0067><U0029>";<U0067>
<U24D7> "<U0028><U0068><U0029>";<U0068>
<U24D8> "<U0028><U0069><U0029>";<U0069>
<U24D9> "<U0028><U006A><U0029>";<U006A>
<U24DA> "<U0028><U006B><U0029>";<U006B>
<U24DB> "<U0028><U006C><U0029>";<U006C>
<U24DC> "<U0028><U006D><U0029>";<U006D>
<U24DD> "<U0028><U006E><U0029>";<U006E>
<U24DE> "<U0028><U006F><U0029>";<U006F>
<U24DF> "<U0028><U0070><U0029>";<U0070>
<U24E0> "<U0028><U0071><U0029>";<U0071>
<U24E1> "<U0028><U0072><U0029>";<U0072>
<U24E2> "<U0028><U0073><U0029>";<U0073>
<U24E3> "<U0028><U0074><U0029>";<U0074>
<U24E4> "<U0028><U0075><U0029>";<U0075>
<U24E5> "<U0028><U0076><U0029>";<U0076>
<U24E6> "<U0028><U0077><U0029>";<U0077>
<U24E7> "<U0028><U0078><U0029>";<U0078>
<U24E8> "<U0028><U0079><U0029>";<U0079>
<U24E9> "<U0028><U007A><U0029>";<U007A>
<U24EA> "<U0028><U0030><U0029>";<U0030>
<U2500> <U002D>
<U2501> <U003D>
<U2502> <U007C>
<U2503> <U007C>
<U2504> <U002D>
<U2505> <U003D>
<U2506> <U007C>
<U2507> <U007C>
<U2508> <U002D>
<U2509> <U003D>
<U250A> <U007C>
<U250B> <U007C>
<U250C> <U002B>
<U250D> <U002B>
<U250E> <U002B>
<U250F> <U002B>
<U2510> <U002B>
<U2511> <U002B>
<U2512> <U002B>
<U2513> <U002B>
<U2514> <U002B>
<U2515> <U002B>
<U2516> <U002B>
<U2517> <U002B>
<U2518> <U002B>
<U2519> <U002B>
<U251A> <U002B>
<U251B> <U002B>
<U251C> <U002B>
<U251D> <U002B>
<U251E> <U002B>
<U251F> <U002B>
<U2520> <U002B>
<U2521> <U002B>
<U2522> <U002B>
<U2523> <U002B>
<U2524> <U002B>
<U2525> <U002B>
<U2526> <U002B>
<U2527> <U002B>
<U2528> <U002B>
<U2529> <U002B>
<U252A> <U002B>
<U252B> <U002B>
<U252C> <U002B>
<U252D> <U002B>
<U252E> <U002B>
<U252F> <U002B>
<U2530> <U002B>
<U2531> <U002B>
<U2532> <U002B>
<U2533> <U002B>
<U2534> <U002B>
<U2535> <U002B>
<U2536> <U002B>
<U2537> <U002B>
<U2538> <U002B>
<U2539> <U002B>
<U253A> <U002B>
<U253B> <U002B>
<U253C> <U002B>
<U253D> <U002B>
<U253E> <U002B>
<U253F> <U002B>
<U2540> <U002B>
<U2541> <U002B>
<U2542> <U002B>
<U2543> <U002B>
<U2544> <U002B>
<U2545> <U002B>
<U2546> <U002B>
<U2547> <U002B>
<U2548> <U002B>
<U2549> <U002B>
<U254A> <U002B>
<U254B> <U002B>
<U254C> <U002D>
<U254D> <U003D>
<U254E> <U007C>
<U254F> <U007C>
<U2550> <U003D>
<U2551> <U007C>
<U2552> <U002B>
<U2553> <U002B>
<U2554> <U002B>
<U2555> <U002B>
<U2556> <U002B>
<U2557> <U002B>
<U2558> <U002B>
<U2559> <U002B>
<U255A> <U002B>
<U255B> <U002B>
<U255C> <U002B>
<U255D> <U002B>
<U255E> <U002B>
<U255F> <U002B>
<U2560> <U002B>
<U2561> <U002B>
<U2562> <U002B>
<U2563> <U002B>
<U2564> <U002B>
<U2565> <U002B>
<U2566> <U002B>
<U2567> <U002B>
<U2568> <U002B>
<U2569> <U002B>
<U256A> <U002B>
<U256B> <U002B>
<U256C> <U002B>
<U256D> <U002B>
<U256E> <U002B>
<U256F> <U002B>
<U2570> <U002B>
<U2571> <U002F>
<U2572> <U005C>
<U2573> <U0058>
<U257C> <U002D>
<U257D> <U007C>
<U257E> <U002D>
<U257F> <U007C>
<U25CB> <U006F>
<U25E6> <U006F>
<U2605> <U002A>
<U2606> <U002A>
<U2612> <U0058>
<U2613> <U0058>
<U2639> "<U003A><U002D><U0028>"
<U263A> "<U003A><U002D><U0029>"
<U263B> "<U0028><U002D><U003A>"
<U266D> <U0062>
<U266F> <U0023>
<U2701> "<U0025><U003C>"
<U2702> "<U0025><U003C>"
<U2703> "<U0025><U003C>"
<U2704> "<U0025><U003C>"
<U270C> <U0056>
<U2713> <U221A>
<U2714> <U221A>
<U2715> <U0078>
<U2716> <U0078>
<U2717> <U0058>
<U2718> <U0058>
<U2719> <U002B>
<U271A> <U002B>
<U271B> <U002B>
<U271C> <U002B>
<U271D> <U002B>
<U271E> <U002B>
<U271F> <U002B>
<U2720> <U002B>
<U2721> <U002A>
<U2722> <U002B>
<U2723> <U002B>
<U2724> <U002B>
<U2725> <U002B>
<U2726> <U002B>
<U2727> <U002B>
<U2729> <U002A>
<U272A> <U002A>
<U272B> <U002A>
<U272C> <U002A>
<U272D> <U002A>
<U272E> <U002A>
<U272F> <U002A>
<U2730> <U002A>
<U2731> <U002A>
<U2732> <U002A>
<U2733> <U002A>
<U2734> <U002A>
<U2735> <U002A>
<U2736> <U002A>
<U2737> <U002A>
<U2738> <U002A>
<U2739> <U002A>
<U273A> <U002A>
<U273B> <U002A>
<U273C> <U002A>
<U273D> <U002A>
<U273E> <U002A>
<U273F> <U002A>
<U2740> <U002A>
<U2741> <U002A>
<U2742> <U002A>
<U2743> <U002A>
<U2744> <U002A>
<U2745> <U002A>
<U2746> <U002A>
<U2747> <U002A>
<U2748> <U002A>
<U2749> <U002A>
<U274A> <U002A>
<U274B> <U002A>
<UFB00> "<U0066><U0066>"
<UFB01> "<U0066><U0069>"
<UFB02> "<U0066><U006C>"
<UFB03> "<U0066><U0066><U0069>"
<UFB04> "<U0066><U0066><U006C>"
<UFB05> "<U017F><U0074>";"<U0073><U0074>"
<UFB06> "<U0073><U0074>"
<UFEFF> ""
<UFFFD> <U003F>
