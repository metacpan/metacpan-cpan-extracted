package Search::Tools::XML;
use Moo;
use Carp;
use Search::Tools;    # XS required
use Search::Tools::UTF8;

use namespace::autoclean;

our $VERSION = '1.007';

=pod

=head1 NAME

Search::Tools::XML - methods for playing nice with XML and HTML

=head1 SYNOPSIS

 use Search::Tools::XML;

 my $class = 'Search::Tools::XML';

 my $text = 'the "quick brown" fox';

 my $xml = $class->start_tag('foo');

 $xml .= $class->utf8_safe( $text );

 $xml .= $class->end_tag('foo');

 # $xml: <foo>the &#34;quick brown&#34; fox</foo>

 $xml = $class->escape( $xml );

 # $xml: &lt;foo&gt;the &amp;#34;quick brown&amp;#34; fox&lt;/foo&gt;

 $xml = $class->unescape( $xml );

 # $xml: <foo>the "quick brown" fox</foo>

 my $plain = $class->no_html( $xml );

 # $plain eq $text


=head1 DESCRIPTION

B<IMPORTANT:> The API for escape() and unescape() has changed as of version 0.16.
The text is no longer modified in place, as this was less intuitive.

Search::Tools::XML provides utility methods for dealing with XML and HTML.
There isn't really anything new here that CPAN doesn't provide via HTML::Entities
or similar modules. The difference is convenience: the most common methods you
need for search apps are in one place with no extra dependencies.

B<NOTE:> To get full UTF-8 character set from chr() you must be using Perl >= 5.8.
This affects things like the unescape* methods.

=head1 VARIABLES

=head2 %HTML_ents

Complete map of all named HTML entities to their decimal values.

=cut

# regexp for what constitutes whitespace in an HTML doc
# it's not as simple as \s|&nbsp; so we define it separately
my @white_hex_pts = qw(
    0009
    000a
    000b
    000c
    000d
    0020
    00a0
    2000
    2001
    2002
    2003
    2004
    2005
    2006
    2007
    2008
    2009
    200a
    200b
    2028
    2029
    202f
    205f
    2060
    3000
);

my @whitesp = ( '\s', '&nbsp;' );

# NOTE that the pound sign # needs escaping because we use
# the 'x' flag in our regexp.

for my $w (@white_hex_pts) {
    push @whitesp, sprintf( "&\\#x%s;", $w );                # hex entity
    push @whitesp, sprintf( "&\\#%s;",  hex($w) );           # dec entity
    push @whitesp, sprintf( "\\%s",     chr( hex($w) ) );    # byte value
}

my $HTML_WHITESPACE = join( '|', @whitesp );
my $WHITESPACE = join( '|', map { chr( hex($_) ) } @white_hex_pts );

# HTML entity table
# this just removes a dependency on another module...

our %HTML_ents = (
    quot     => 34,
    amp      => 38,
    apos     => 39,
    'lt'     => 60,
    'gt'     => 62,
    nbsp     => 160,
    iexcl    => 161,
    cent     => 162,
    pound    => 163,
    curren   => 164,
    yen      => 165,
    brvbar   => 166,
    sect     => 167,
    uml      => 168,
    copy     => 169,
    ordf     => 170,
    laquo    => 171,
    not      => 172,
    shy      => 173,
    reg      => 174,
    macr     => 175,
    deg      => 176,
    plusmn   => 177,
    sup2     => 178,
    sup3     => 179,
    acute    => 180,
    micro    => 181,
    para     => 182,
    middot   => 183,
    cedil    => 184,
    sup1     => 185,
    ordm     => 186,
    raquo    => 187,
    frac14   => 188,
    frac12   => 189,
    frac34   => 190,
    iquest   => 191,
    Agrave   => 192,
    Aacute   => 193,
    Acirc    => 194,
    Atilde   => 195,
    Auml     => 196,
    Aring    => 197,
    AElig    => 198,
    Ccedil   => 199,
    Egrave   => 200,
    Eacute   => 201,
    Ecirc    => 202,
    Euml     => 203,
    Igrave   => 204,
    Iacute   => 205,
    Icirc    => 206,
    Iuml     => 207,
    ETH      => 208,
    Ntilde   => 209,
    Ograve   => 210,
    Oacute   => 211,
    Ocirc    => 212,
    Otilde   => 213,
    Ouml     => 214,
    'times'  => 215,
    Oslash   => 216,
    Ugrave   => 217,
    Uacute   => 218,
    Ucirc    => 219,
    Uuml     => 220,
    Yacute   => 221,
    THORN    => 222,
    szlig    => 223,
    agrave   => 224,
    aacute   => 225,
    acirc    => 226,
    atilde   => 227,
    auml     => 228,
    aring    => 229,
    aelig    => 230,
    ccedil   => 231,
    egrave   => 232,
    eacute   => 233,
    ecirc    => 234,
    euml     => 235,
    igrave   => 236,
    iacute   => 237,
    icirc    => 238,
    iuml     => 239,
    eth      => 240,
    ntilde   => 241,
    ograve   => 242,
    oacute   => 243,
    ocirc    => 244,
    otilde   => 245,
    ouml     => 246,
    divide   => 247,
    oslash   => 248,
    ugrave   => 249,
    uacute   => 250,
    ucirc    => 251,
    uuml     => 252,
    yacute   => 253,
    thorn    => 254,
    yuml     => 255,
    OElig    => 338,
    oelig    => 339,
    Scaron   => 352,
    scaron   => 353,
    Yuml     => 376,
    fnof     => 402,
    circ     => 710,
    tilde    => 732,
    Alpha    => 913,
    Beta     => 914,
    Gamma    => 915,
    Delta    => 916,
    Epsilon  => 917,
    Zeta     => 918,
    Eta      => 919,
    Theta    => 920,
    Iota     => 921,
    Kappa    => 922,
    Lambda   => 923,
    Mu       => 924,
    Nu       => 925,
    Xi       => 926,
    Omicron  => 927,
    Pi       => 928,
    Rho      => 929,
    Sigma    => 931,
    Tau      => 932,
    Upsilon  => 933,
    Phi      => 934,
    Chi      => 935,
    Psi      => 936,
    Omega    => 937,
    alpha    => 945,
    beta     => 946,
    gamma    => 947,
    delta    => 948,
    epsilon  => 949,
    zeta     => 950,
    eta      => 951,
    theta    => 952,
    iota     => 953,
    kappa    => 954,
    lambda   => 955,
    mu       => 956,
    nu       => 957,
    xi       => 958,
    omicron  => 959,
    pi       => 960,
    rho      => 961,
    sigmaf   => 962,
    sigma    => 963,
    tau      => 964,
    upsilon  => 965,
    phi      => 966,
    chi      => 967,
    psi      => 968,
    omega    => 969,
    thetasym => 977,
    upsih    => 978,
    piv      => 982,
    ensp     => 8194,
    emsp     => 8195,
    thinsp   => 8201,
    zwnj     => 8204,
    zwj      => 8205,
    lrm      => 8206,
    rlm      => 8207,
    ndash    => 8211,
    mdash    => 8212,
    lsquo    => 8216,
    rsquo    => 8217,
    sbquo    => 8218,
    ldquo    => 8220,
    rdquo    => 8221,
    bdquo    => 8222,
    dagger   => 8224,
    Dagger   => 8225,
    bull     => 8226,
    hellip   => 8230,
    permil   => 8240,
    prime    => 8242,
    Prime    => 8243,
    lsaquo   => 8249,
    rsaquo   => 8250,
    oline    => 8254,
    frasl    => 8260,
    euro     => 8364,
    image    => 8465,
    weierp   => 8472,
    real     => 8476,
    trade    => 8482,
    alefsym  => 8501,
    larr     => 8592,
    uarr     => 8593,
    rarr     => 8594,
    darr     => 8595,
    harr     => 8596,
    crarr    => 8629,
    lArr     => 8656,
    uArr     => 8657,
    rArr     => 8658,
    dArr     => 8659,
    hArr     => 8660,
    forall   => 8704,
    part     => 8706,
    exist    => 8707,
    empty    => 8709,
    nabla    => 8711,
    isin     => 8712,
    notin    => 8713,
    ni       => 8715,
    prod     => 8719,
    'sum'    => 8721,
    'minus'  => 8722,
    lowast   => 8727,
    radic    => 8730,
    prop     => 8733,
    infin    => 8734,
    ang      => 8736,
    'and'    => 8743,
    'or'     => 8744,
    cap      => 8745,
    cup      => 8746,
    int      => 8747,
    there4   => 8756,
    sim      => 8764,
    cong     => 8773,
    asymp    => 8776,
    ne       => 8800,
    equiv    => 8801,
    le       => 8804,
    ge       => 8805,
    sub      => 8834,
    sup      => 8835,
    nsub     => 8836,
    sube     => 8838,
    supe     => 8839,
    oplus    => 8853,
    otimes   => 8855,
    perp     => 8869,
    sdot     => 8901,
    lceil    => 8968,
    rceil    => 8969,
    lfloor   => 8970,
    rfloor   => 8971,
    lang     => 9001,
    rang     => 9002,
    loz      => 9674,
    spades   => 9824,
    clubs    => 9827,
    hearts   => 9829,
    diams    => 9830,
);

my %char2entity = ();
while ( my ( $e, $n ) = each(%HTML_ents) ) {
    my $char = chr($n);
    $char2entity{$char} = "&$e;";
}
delete $char2entity{q/'/};    # only one-way decoding

# Fill in missing entities
# TODO does this only work under latin1 locale?
for ( 0 .. 255 ) {
    next if exists $char2entity{ chr($_) };
    $char2entity{ chr($_) } = "&#$_;";
}

=head1 METHODS

The following methods may be accessed either as object or class methods.

=head2 new

Create a Search::Tools::XML object.

=cut

=head2 tag_re

Returns a qr// regex for matching a SGML (XML, HTML, etc) tag.

=cut

sub tag_re {qr/<[^>]+>/s}

=head2 html_whitespace

Returns a regex for all whitespace characters and
HTML whitespace entities.

=cut

sub html_whitespace {$HTML_WHITESPACE}

=head2 char2ent_map

Returns a hash reference to the class data mapping chr() values to their
numerical entity equivalents.

=cut

sub char2ent_map { \%char2entity }

=head2 looks_like_html( I<string> )

Returns true if I<string> appears to have HTML-like markup in it.

Aliases for this method include:

=over

=item looks_like_xml

=item looks_like_markup

=back

=cut

sub looks_like_html { return $_[1] =~ m/[<>]|&[\#\w]+;/o }
*looks_like_xml    = \&looks_like_html;
*looks_like_markup = \&looks_like_html;

=head2 start_tag( I<string> [, I<\%attr> ] )

=head2 end_tag( I<string> )

Returns I<string> as a tag, either start or end. I<string> will be escaped for any non-valid
chars using tag_safe().

If I<\%attr> is passed, XML-safe attributes are generated using attr_safe().

=head2 singleton( I<string> [, I<\%attr> ] )

Like start_tag() but includes the closing slash.

=cut

sub start_tag { "<" . tag_safe( $_[1] ) . $_[0]->attr_safe( $_[2] ) . ">" }
sub end_tag   { "</" . tag_safe( $_[1] ) . ">" }
sub singleton { "<" . tag_safe( $_[1] ) . $_[0]->attr_safe( $_[2] ) . "/>" }

=pod

=head2 tag_safe( I<string> )

Create a valid XML tag name, escaping/omitting invalid characters.

Example:

    my $tag = Search::Tools::XML->tag_safe( '1 * ! tag foo' );
    # $tag == '______tag_foo'

=cut

sub tag_safe {
    my $t = pop;

    return '_' unless length $t;

    $t =~ s/::/_/g;    # single colons ok, but doubles are not
    $t =~ s/[^-\.\w:]/_/g;
    $t =~ s/^(\d)/_$1/;

    return $t;
}

=head2 attr_safe( I<\%attr> )

Returns stringified I<\%attr> as XML attributes.

=cut

sub attr_safe {
    my $self = shift;
    my $attr = shift;
    return '' unless defined $attr;
    if ( ref $attr ne "HASH" ) {
        croak "attributes must be a hash ref";
    }
    my @xml = ('');    # force space at start in return
    for my $name ( sort keys %$attr ) {
        my $val = _escape_xml( $attr->{$name},
            is_flagged_utf8( $attr->{$name} ) );
        push @xml, tag_safe($name) . qq{="$val"};
    }
    return join( ' ', @xml );
}

=pod

=head2 utf8_safe( I<string> )

Return I<string> with special XML chars and all
non-ASCII chars converted to numeric entities.

This is escape() on steroids. B<Do not use them both on the same text>
unless you know what you're doing. See the SYNOPSIS for an example.

=head2 escape_utf8

Alias for utf8_safe().

=cut

*escape_utf8 = \&utf8_safe;

sub utf8_safe {
    my $t = pop;
    $t = '' unless defined $t;

    # converts all low chars except \t \n and \r
    # to space because XML spec disallows <32
    $t =~ s,[\x00-\x08\x0b-\x0c\x0e-\x1f], ,g;

    $t =~ s{([^\x09\x0a\x0d\x20\x21\x23-\x25\x28-\x3b\x3d\x3F-\x5B\x5D-\x7E])}
            {'&#'.(ord($1)).';'}eg;

    return $t;
}

=head2 no_html( I<text> [, I<normalize_whitespace>] )

no_html() is a brute-force method for removing all tags and entities
from I<text>. A simple regular expression is used, so things like
nested comments and the like will probably break. If you really
need to reliably filter out the tags and entities from a HTML text, use
HTML::Parser or similar.

I<text> is returned with no markup in it.

If I<normalize_whitespace> is true (defaults to false) then
all whitespace is normalized away to ASCII space (U+0020).
This can be helpful if you have Unicode entities representing 
line breaks or other layout instructions.

=cut

sub no_html {
    my $class                = shift;
    my $text                 = shift;
    my $normalize_whitespace = shift || 0;
    if ( !defined $text ) {
        croak "text required";
    }
    my $re = $class->tag_re;
    $text =~ s,$re,,g;
    $text = $class->unescape($text);
    if ($normalize_whitespace) {
        $text =~ s/\s+/ /g;
    }
    return $text;
}

=head2 strip_html

An alias for no_html().

=head2 strip_markup

An alias for no_html().

=cut

*strip_html   = \&no_html;
*strip_markup = \&no_html;

=head2 escape( I<text> )

Similar to escape() functions in more famous CPAN modules, but without the
added dependency. escape() will convert the special XML chars (><'"&) to their
named entity equivalents.

The escaped I<text> is returned.

B<IMPORTANT:> The API for this method has changed as of version 0.16. I<text>
is no longer modified in-place.

As of version 0.27 escape() is written in C/XS for speed.

=cut

sub escape {
    my $text = pop;
    return unless defined $text;
    return _escape_xml( $text, is_flagged_utf8($text) );
}

=head2 unescape( I<text> )

Similar to unescape() functions in more famous CPAN modules, but without the added
dependency. unescape() will convert all entities to their chr() equivalents.

B<NOTE:> unescape() does more than reverse the effects of escape(). It attempts
to resolve B<all> entities, not just the special XML entities (><'"&).

B<IMPORTANT:> The API for this method has changed as of version 0.16.
I<text> is no longer modified in-place.

=cut

sub unescape {
    my $text = pop;
    $text = unescape_named($text);
    $text = unescape_decimal($text);
    return $text;
}

=head2 unescape_named( I<text> )

Replace all named HTML entities with their chr() equivalents.

Returns modified copy of I<text>.

=cut

sub unescape_named {
    my $t = pop;
    if ( defined($t) ) {

        # named entities - check first to see if it is worth looping
        if ( $t =~ m/&[a-zA-Z0-9]+;/ ) {
            for my $e ( keys %HTML_ents ) {
                my $dec = $HTML_ents{$e};
                if ( my $n = $t =~ s/&$e;/chr($dec)/eg ) {

                #warn "replaced $e ($dec) -> $HTML_ents{$e} $n times in text";
                }
            }
        }
    }
    return $t;
}

=head2 unescape_decimal( I<text> )

Replace all decimal entities with their chr() equivalents.

Returns modified copy of I<text>.

=cut

sub unescape_decimal {
    my $t = pop;

    # resolve numeric entities as best we can
    $t =~ s/&#(\d+);/chr($1)/ego if defined($t);
    return $t;
}

=head2 perl_to_xml( I<ref> [, I<options>] )

Similar to the XML::Simple XMLout() feature, perl_to_xml()
will take a Perl data structure I<ref> and convert it to XML.

I<options> should be a hashref with the following supported key/value pairs:

=over

=item root I<value>

The root element. If I<value> is a string, it is used as the tag name. If
I<value> is a hashref, two keys are required:

=over

=item tag

String indicating the element name.

=item attrs

Hash ref of attribute key/value pairs (see start_tag()).

=back

=item wrap_array I<1|0>

If B<wrap_array> is true (the default), arrayref items are wrapped
in an additional XML tag, keeping the array items enclosed in a logical set.
If B<wrap_array> is false, each item in the array is treated individually.
See B<strip_plural> below for the naming convention for arrayref items.

=item strip_plural I<1|0>

The B<strip_plural> option interacts with the B<wrap_array> option.

If B<strip_plural> is a true value and not a CODE ref,
any trailing C<s> character will be stripped from the enclosing tag name
whenever an array of hashrefs is found. Example:

 my $data = {
    values => [
        {   two   => 2,
            three => 3,
        },
        {   four => 4,
            five => 5,
        },
    ],
 };

 my $xml = $utils->perl_to_xml($data, {
    root            => 'data',
    wrap_array      => 1,
    strip_plural    => 1,
 });

 # $xml DOM will look like:

 <data>
  <values>
   <value>
    <three>3</three>
    <two>2</two>
   </value>
   <value>
    <five>5</five>
    <four>4</four>
   </value>
  </values>
 </data>

Obviously stripping the final C<s> will not always render sensical tag names.
Pass a CODE ref instead, expecting one value (the tag name) and returning the
tag name to use:

 my $xml = $utils->perl_to_xml($data, {
    root            => 'data',
    wrap_array      => 1,
    strip_plural    => sub {
        my $tag = shift;
        $tag =~ s/foo/BAR/;
        return $tag;
    },
 });

=item escape I<1|0>

If B<escape> is false, strings within the B<ref> value will not be passed
through escape(). Default is true.

=back

=cut

=head2 perl_to_xml( I<ref>, I<root_element> [, I<strip_plural> ][, I<do_not_escape>] )

This second usage is deprecated and here for backwards compatability only.
Use the named key/value I<options> instead. Readers of your code (including you!) will
thank you.

=cut

sub _make_singular {
    my ($t) = @_;
    $t =~ s/ies$/y/i;
    return $t if ( $t =~ s/ses$/s/i );
    return $t if ( $t =~ /[aeiouy]ss$/i );
    $t =~ s/s$//i;
    return length $t ? $t : $_[0];
}

sub perl_to_xml {
    my $self = shift;
    my $perl = shift;

    my ( $root, $wrap_array, $strip_plural, $escape );
    if ( ref $_[0] eq 'HASH' and !exists $_[0]->{tag} ) {
        my %opts = %{ $_[0] };
        $root         = delete $opts{root}         || '_root';
        $strip_plural = delete $opts{strip_plural} || 0;
        $wrap_array   = delete $opts{wrap_array};
        $wrap_array = 1 unless defined $wrap_array;
        $escape     = delete $opts{escape};
        $escape     = 1 unless defined $escape;
    }
    else {
        $root         = shift || '_root';
        $strip_plural = shift || 0;
        $escape       = shift;

        # backcompat means we need to reverse logic
        if ( defined $escape and $escape == 1 ) {
            $escape = 0;
        }
        elsif ( defined $escape and $escape == 0 ) {
            $escape = 1;
        }
        elsif ( !defined $escape ) {
            $escape = 1;
        }

        $wrap_array = 1;    # old behavior
    }
    unless ( defined $perl ) {
        croak "perl data struct required";
    }

    if ( $strip_plural and ref($strip_plural) ne 'CODE' ) {
        $strip_plural = \&_make_singular;
    }

    my ( $root_tag, $attrs );
    if ( ref $root ) {
        $root_tag = delete $root->{tag} or croak 'tag key required in root';
        $attrs = delete $root->{attrs} or croak 'attrs key required in root';
    }
    else {
        $root_tag = $root;
        $attrs    = {};
    }

    if ( !ref $perl ) {
        return
              $self->start_tag( $root_tag, $attrs )
            . ( $escape ? $self->utf8_safe($perl) : $perl )
            . $self->end_tag($root_tag);
    }

    my $xml = $self->start_tag( $root_tag, $attrs );
    $self->_ref_to_xml( $perl, '', \$xml, $strip_plural, $escape,
        $wrap_array );
    $xml .= $self->end_tag($root_tag);
    return $xml;
}

sub _ref_to_xml {
    my ( $self, $perl, $root, $xml_ref, $strip_plural, $escape, $wrap_array )
        = @_;
    my $type = ref $perl;
    if ( !$type ) {
        ( $$xml_ref .= $self->start_tag($root) )
            if length($root);
        $$xml_ref .= ( $escape ? $self->utf8_safe($perl) : $perl );
        ( $$xml_ref .= $self->end_tag($root) )
            if length($root);

        #$$xml_ref .= "\n";    # just for debugging
    }
    elsif ( $type eq 'SCALAR' ) {
        $self->_scalar_to_xml( $perl, $root, $xml_ref, $strip_plural,
            $escape, $wrap_array );
    }
    elsif ( $type eq 'ARRAY' ) {
        $self->_array_to_xml( $perl, $root, $xml_ref, $strip_plural,
            $escape, $wrap_array );
    }
    elsif ( $type eq 'HASH' ) {
        $self->_hash_to_xml( $perl, $root, $xml_ref, $strip_plural, $escape,
            $wrap_array );
    }
    else {
        # assume blessed object, force it to stringify as a scalar
        $self->_scalar_to_xml( "$perl", $root, $xml_ref, $strip_plural,
            $escape, $wrap_array );
    }

}

sub _array_to_xml {
    my ( $self, $perl, $root, $xml_ref, $strip_plural, $escape, $wrap_array )
        = @_;
    for my $thing (@$perl) {
        if (    ref $thing
            and ( ref $thing eq 'ARRAY' or ref $thing eq 'HASH' )
            and length($root)
            and $wrap_array )
        {
            #warn "<$root> ref $thing == " . ref($thing);
            $$xml_ref .= $self->start_tag($root);
        }
        $self->_ref_to_xml( $thing, $root, $xml_ref, $strip_plural, $escape,
            $wrap_array );
        if (    ref $thing
            and ( ref $thing eq 'ARRAY' or ref $thing eq 'HASH' )
            and length($root)
            and $wrap_array )
        {
            #warn "</$root> ref $thing == " . ref($thing);
            $$xml_ref .= $self->end_tag($root);
        }
    }
}

sub _hash_to_xml {
    my ( $self, $perl, $root, $xml_ref, $strip_plural, $escape, $wrap_array )
        = @_;
    for my $key ( keys %$perl ) {
        my $thing = $perl->{$key};
        if ( ref $thing ) {
            my $key_to_pass = $key;
            my %attr;
            if ( ref $thing eq 'ARRAY' && $strip_plural ) {
                $key_to_pass = $strip_plural->($key_to_pass);
                $attr{count} = scalar @$thing;
            }
            if ( ref $thing ne 'ARRAY' or $wrap_array ) {
                $$xml_ref .= $self->start_tag( $key, \%attr );
            }
            $self->_ref_to_xml(
                $thing,        $key_to_pass, $xml_ref,
                $strip_plural, $escape,      $wrap_array
            );
            if ( ref $thing ne 'ARRAY' or $wrap_array ) {
                $$xml_ref .= $self->end_tag($key);
            }

            #$$xml_ref .= "\n";                  # just for debugging
        }
        else {
            $self->_ref_to_xml( $thing, $key, $xml_ref, $strip_plural,
                $escape, $wrap_array );
        }
    }
}

sub _scalar_to_xml {
    my ( $self, $perl, $root, $xml_ref, $strip_plural, $escape, $wrap_array )
        = @_;
    $$xml_ref
        .= $self->start_tag($root)
        . ( $escape ? $self->utf8_safe($perl) : $perl )
        . $self->end_tag($root);

    #$$xml_ref .= "\n";    # just for debugging
}

=head2 tidy( I<xmlstring> )

Attempts to indent I<xmlstring> correctly to make
it more legible.

Returns the I<xmlstring> tidied up.

B<WARNING> This is an experimental feature. It might be
really slow or eat your XML. You have been warned.

=cut

sub tidy {
    my $xml    = pop;
    my $level  = 2;
    my $indent = 0;
    my @tidy   = ();

    # normalize tag breaks
    $xml =~ s,>\s*<,>\n<,gs;

    my @xmlarr = split( m/\n/, $xml );

    # shift off declaration
    if ( scalar(@xmlarr) and $xmlarr[0] =~ m/^<\?\s*xml/ ) {
        push @tidy, shift(@xmlarr);
    }

    my $count = 0;
    for my $el (@xmlarr) {

        if ( $count == 1 ) {
            $indent = 2;
        }
        if ( $count == scalar(@xmlarr) - 1 ) {
            $indent = 0;
        }

        #warn "el: $el\n";

        # singletons get special treatment
        if ( $el =~ m/^<([\w])+[^>]*\/>$/ ) {

            push @tidy, ( ' ' x $indent ) . $el;
        }

        # match opening tag
        elsif ( $el =~ m/^<([\w])+[^>]*>$/ ) {

            #warn "open $indent\n";
            push @tidy, ( ' ' x $indent ) . $el;
            $indent += $level;
        }
        else {
            if ( $el =~ m/^<\// ) {

                #warn "close $indent\n";
                $indent -= $level;    # closing tag
            }
            if ( $indent < 0 ) {
                $indent += $level;
            }
            push @tidy, ( ' ' x $indent ) . $el;
        }

        #warn "indent = $indent\n";

        #Data::Dump::dump \@tidy;
        $count++;
    }

    return join( "\n", @tidy );

}

1;
__END__

=head1 AUTHOR

Peter Karman C<< <karman@cpan.org> >>

Originally based on the HTML::HiLiter regular expression building code,
by the same author, copyright 2004 by Cray Inc.

Thanks to Atomic Learning C<www.atomiclearning.com>
for sponsoring the original development of these modules.

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
