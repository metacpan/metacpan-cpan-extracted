package SVG::Rasterize::Regexes;
use strict;
use warnings;

use Exporter 'import';

# $Id: Regexes.pm 6632 2011-04-30 00:09:38Z powergnom $

=head1 NAME

C<SVG::Rasterize::Regexes> - Commonly used regular expressions

=head1 VERSION

Version 0.003007

=cut

our $VERSION = '0.003007';

our @EXPORT    = qw();
our @EXPORT_OK = qw($WSP
		    $CWSP
                    %RE_PACKAGE
                    %RE_XML
                    %RE_URI
                    %RE_NUMBER
                    %RE_LENGTH
                    %RE_PAINT
                    %RE_TRANSFORM
                    %RE_VIEW_BOX
                    %RE_PATH
                    %RE_DASHARRAY
                    %RE_POLY
                    %RE_TEXT);

our %EXPORT_TAGS = (all           => [@EXPORT, @EXPORT_OK],
		    whitespace    => [qw($WSP $CWSP)],
                    attributes    => [qw(%RE_XML
                                         %RE_URI
                                         %RE_NUMBER
                                         %RE_LENGTH
                                         %RE_PAINT
                                         %RE_TRANSFORM
                                         %RE_VIEW_BOX
                                         %RE_PATH
                                         %RE_DASHARRAY
                                         %RE_POLY
                                         %RE_TEXT)]);

our $WSP  = qr/[\x{20}\x{9}\x{D}\x{A}]/;
our $CWSP = qr/(?:$WSP+\,?$WSP*|\,$WSP*)/;

our %RE_PACKAGE = ();
{
    my $package_part = qr/[a-zA-Z][a-zA-Z0-9\_]*/;
    
    $RE_PACKAGE{p_PACKAGE_NAME} =
	qr/^$package_part(?:\:\:$package_part)*$/;
}

# XML stuff (the white space would probably also fit in here, but I
# do not think that I will change that).
our %RE_XML = ();
$RE_XML{NAME_START_CHAR} = qr/[\:a-zA-Z\_]/;
$RE_XML{NAME_CHAR}       = qr/[\:a-zA-Z\_\-\.0-9]/;
$RE_XML{NAME}            = qr/$RE_XML{NAME_START_CHAR}$RE_XML{NAME_CHAR}*/;
$RE_XML{p_NAME}          = qr/^$RE_XML{NAME}$/;
$RE_XML{NMTOKEN}         = qr/$RE_XML{NAME_CHAR}+/;
$RE_XML{p_NMTOKEN}       = qr/^$RE_XML{NMTOKEN}$/;

# URI stuff
# $RE_URI{FULL_URI} and its components except $RE_URI{FRAGMENT}
# (which would be just .*) are taken from RFC2396.
# Note that they are lax with respect to the characters occuring in
# the components. These expressions can be used to split a URI into
# its components, but before those are used they should be further
# validated.
our %RE_URI = ();
$RE_URI{SCHEME}    = qr/[^\:\/\?\#]+/;
$RE_URI{AUTHORITY} = qr/[^\/\?\#]*/;
$RE_URI{PATH}      = qr/[^\?\#]*/;
$RE_URI{QUERY}     = qr/[^\#]*/;
$RE_URI{FRAGMENT}  = qr/(?:$RE_XML{NAME}|xpointer\(id\($RE_XML{NAME}\)\))/;
$RE_URI{FULL_URI}  = qr/(?:$RE_URI{SCHEME}\:)?
                        (?:\/\/$RE_URI{AUTHORITY})?
                        (?:$RE_URI{PATH})
                        (?:\?$RE_URI{QUERY})?
                        (?:\#$RE_URI{FRAGMENT})?/x;
$RE_URI{LOCAL_URI} = qr/\#$RE_URI{FRAGMENT}/;
$RE_URI{URI}       = qr/(?:$RE_URI{FULL_URI}|$RE_URI{LOCAL_URI})/;
$RE_URI{p_URI}     = qr/^$RE_URI{URI}$/;

# numbers and lengths
our %RE_NUMBER = ();
our %RE_LENGTH = ();
$RE_NUMBER{NNINTEGER}    = qr/\+?\d+/;
$RE_NUMBER{p_NNINTEGER}  = qr/^$RE_NUMBER{NNINTEGER}$/;
$RE_NUMBER{INTEGER}      = qr/[\+\-]?$RE_NUMBER{NNINTEGER}/;
$RE_NUMBER{p_INTEGER}    = qr/^$RE_NUMBER{INTEGER}$/;
$RE_NUMBER{w_INTEGER}    = qr/^$WSP*$RE_NUMBER{INTEGER}$WSP*$/;

$RE_NUMBER{NNFRACTION}   = qr/\+?(?:\d*\.\d+|\d+\.)/;
$RE_NUMBER{FRACTION}     = qr/[\+\-]?$RE_NUMBER{NNFRACTION}/;
$RE_NUMBER{p_FRACTION}   = qr/^$RE_NUMBER{FRACTION}$/;
$RE_NUMBER{w_FRACTION}   = qr/^$WSP*$RE_NUMBER{FRACTION}$WSP*$/;
$RE_NUMBER{EXPONENT}     = qr/[eE][\+\-]?\d+/;
$RE_NUMBER{NNFLOAT}      = qr/(?:$RE_NUMBER{NNFRACTION}
                                $RE_NUMBER{EXPONENT}?
                               |$RE_NUMBER{NNINTEGER}
                                $RE_NUMBER{EXPONENT})/x;
$RE_NUMBER{FLOAT}        = qr/[\+\-]?$RE_NUMBER{NNFLOAT}/;
$RE_NUMBER{p_FLOAT}      = qr/^$RE_NUMBER{FLOAT}$/;
$RE_NUMBER{w_FLOAT}      = qr/^$WSP*$RE_NUMBER{FLOAT}$WSP*$/;
$RE_NUMBER{P_NNNUMBER}   = qr/(?:$RE_NUMBER{NNFRACTION}
                               |$RE_NUMBER{NNINTEGER})/x;
$RE_NUMBER{p_P_NNNUMBER} = qr/^$RE_NUMBER{P_NNNUMBER}$/;
$RE_NUMBER{w_P_NNNUMBER} = qr/^$WSP*$RE_NUMBER{P_NNNUMBER}$WSP*$/;
$RE_NUMBER{P_NUMBER}     = qr/[\+\-]?$RE_NUMBER{P_NNNUMBER}/;
$RE_NUMBER{p_P_NUMBER}   = qr/^$RE_NUMBER{P_NUMBER}$/;
$RE_NUMBER{w_P_NUMBER}   = qr/^$WSP*$RE_NUMBER{P_NUMBER}$WSP*$/;
$RE_NUMBER{A_NNNUMBER}   = qr/(?:$RE_NUMBER{NNFLOAT}
                             |$RE_NUMBER{NNINTEGER})/x;
$RE_NUMBER{p_A_NNNUMBER} = qr/^$RE_NUMBER{A_NNNUMBER}$/;
$RE_NUMBER{w_A_NNNUMBER} = qr/^$WSP*$RE_NUMBER{A_NNNUMBER}$WSP*$/;
$RE_NUMBER{A_NUMBER}     = qr/[\+\-]?$RE_NUMBER{A_NNNUMBER}/;
$RE_NUMBER{p_A_NUMBER}   = qr/^$RE_NUMBER{A_NUMBER}$/;
$RE_NUMBER{w_A_NUMBER}   = qr/^$WSP*$RE_NUMBER{A_NUMBER}$WSP*$/;

$RE_LENGTH{UNIT}           = qr/(?:em|ex|px|pt|pc|cm|mm|in|\%)/;
$RE_LENGTH{ABS_UNIT}       = qr/(?:px|pt|pc|cm|mm|in)/;
$RE_LENGTH{P_LENGTH}       = qr/$RE_NUMBER{P_NUMBER}$RE_LENGTH{UNIT}?/;
$RE_LENGTH{p_P_LENGTH}     = qr/^$RE_LENGTH{P_LENGTH}$/;
$RE_LENGTH{w_P_LENGTH}     = qr/^$WSP*$RE_LENGTH{P_LENGTH}$WSP*$/;
$RE_LENGTH{ABS_P_LENGTH}   = qr/$RE_NUMBER{P_NUMBER}
                                $RE_LENGTH{ABS_UNIT}?/x;
$RE_LENGTH{p_ABS_P_LENGTH} = qr/^$RE_LENGTH{ABS_P_LENGTH}$/;
$RE_LENGTH{w_ABS_P_LENGTH} = qr/^$WSP*$RE_LENGTH{ABS_P_LENGTH}$WSP*$/;
$RE_LENGTH{A_LENGTH}       = qr/$RE_NUMBER{A_NUMBER}$RE_LENGTH{UNIT}?/;
$RE_LENGTH{p_A_LENGTH}     = qr/^$RE_LENGTH{A_LENGTH}$/;
$RE_LENGTH{w_A_LENGTH}     = qr/^$WSP*$RE_LENGTH{A_LENGTH}$WSP*$/;
$RE_LENGTH{ABS_A_LENGTH}   = qr/$RE_NUMBER{A_NUMBER}
                                $RE_LENGTH{ABS_UNIT}?/x;
$RE_LENGTH{p_ABS_A_LENGTH} = qr/^$RE_LENGTH{ABS_A_LENGTH}$/;
$RE_LENGTH{w_ABS_A_LENGTH} = qr/^$WSP*$RE_LENGTH{ABS_A_LENGTH}$WSP*$/;

$RE_LENGTH{p_A_LENGTHS}    = qr/^$RE_LENGTH{A_LENGTH}
                                 (?:$CWSP$RE_LENGTH{A_LENGTH})*$/x;
$RE_LENGTH{LENGTHS_SPLIT}  = qr/$CWSP/;

# paint (fill and stroke)
our %RE_PAINT = ();
{
    my $rgbe = qr/[\+\-]?\d+\%?/;

    $RE_PAINT{RGB}      = qr/rgb\($WSP*$rgbe$WSP*\,
                                  $WSP*$rgbe$WSP*\,
                                  $WSP*$rgbe$WSP*\)/x;
    $RE_PAINT{HEX}      = qr/\#[a-fA-F0-9]{3}(?:[a-fA-F0-9]{3})?/;
    $RE_PAINT{NAME}     = qr/[a-z]+/;
    $RE_PAINT{COLOR}    = qr/(?:$RE_PAINT{RGB}|
                                $RE_PAINT{HEX}|
                                $RE_PAINT{NAME})/x;
    $RE_PAINT{p_COLOR}  = qr/^$RE_PAINT{COLOR}$/;
    $RE_PAINT{ICC_SPEC} = qr/icc-color\($WSP*.*?
                             (?:$WSP*\,$WSP*$RE_NUMBER{A_NUMBER})*
                             $WSP*\)/x;
    $RE_PAINT{DIRECT}   = qr/(?:none
                              |currentColor
                              |$RE_PAINT{COLOR}
                               (?:$WSP+$RE_PAINT{ICC_SPEC})?
                              |inherit)/x;
    $RE_PAINT{p_DIRECT} = qr/^$RE_PAINT{DIRECT}$/;
    $RE_PAINT{URI}      = qr/url\($RE_URI{URI}\)
                                  (?:$WSP*$RE_PAINT{DIRECT})?/x;
    $RE_PAINT{PAINT}    = qr/(?:$RE_PAINT{URI}|$RE_PAINT{DIRECT})/;
    $RE_PAINT{p_PAINT}  = qr/^$RE_PAINT{PAINT}$/;

    $RE_PAINT{RGB_SPLIT} = qr/^rgb\($WSP*($rgbe)$WSP*\,
                                    $WSP*($rgbe)$WSP*\,
                                    $WSP*($rgbe)$WSP*\)$/x;
    $RE_PAINT{ICC_SPLIT} = qr/^($RE_PAINT{COLOR})$WSP+
                               ($RE_PAINT{ICC_SPEC})$/x;
    $RE_PAINT{HEX_SPLIT} = qr/^\#([a-fA-F0-9]{1,2})
                                 ([a-fA-F0-9]{1,2})
                                 ([a-fA-F0-9]{1,2})$/x;
    $RE_PAINT{URI_SPLIT} = qr/^(url\($RE_URI{URI}\))$WSP*
                               ($RE_PAINT{DIRECT})?$/x;
}

# attribute stuff

# transform
# The following regular expressions are basically a one-to-one
# translation of the Backus Naur form given in the SVG
# specification on
# http://www.w3.org/TR/SVG11/coords.html#TransformAttribute
# There is the following identifier correspondence:
# transform-list          - $TRANSFORM_LIST
# transforms              - $TRANSFORM_SPLIT
# transform               - $tf
# matrix                  - $ma
# translate               - $tr
# scale                   - $sc
# rotate                  - $ro
# skewX                   - $sx
# skewY                   - $sy
# number                  - $A_NUMBER
# comma-wsp               - $CWSP
# wsp                     - $WSP
# integer-constant        - $INTEGER,  implicit
# floating-point-constant - $FLOAT,    implicit
# fractional-constant     - $FRACTION, implicit
# exponent                - $EXPONENT, implicit
# sign                    - optimized away
#
# digit, digit sequence, and comma are used directly.
# The definition allows some "weird" numbers like 001 or 00.1,
# but this is what the specification says.
# If any of these REs are changed, 010_geometry.t should be
# changed accordingly.

our %RE_TRANSFORM = ();
{
    my  $nu           = $RE_NUMBER{A_NUMBER};
    my  $wnu          = qr/$WSP*$nu/;
    my  $ma           = qr/matrix$WSP*\($WSP*(?:$nu$CWSP){5}$nu$WSP*\)/;
    my  $tr           = qr/translate$WSP*\($wnu(?:$CWSP$nu)?$WSP*\)/;
    my  $sc           = qr/scale$WSP*\($wnu(?:$CWSP$nu)?$WSP*\)/;
    my  $ro           = qr/rotate$WSP*\($wnu(?:(?:$CWSP$nu){2})?$WSP*\)/;
    my  $sx           = qr/skewX$WSP*\($wnu$WSP*\)/;
    my  $sy           = qr/skewY$WSP*\($wnu$WSP*\)/;
    my  $tf           = qr/(?:$ma|$tr|$sc|$ro|$sx|$sy)/;
    my  $tfm          = qr/$tf(?:$CWSP$tf)*/;
    my  $tfn          = qr/(?:matrix|translate|scale|rotate|skewX|skewY)/;

    %RE_TRANSFORM =
	(p_TRANSFORM_LIST  => qr/^$tfm$/,
	 TRANSFORM_SPLIT   => qr/($tf)(?:$CWSP($tfm))?/,
	 TRANSFORM_CAPTURE => qr/($tfn)$WSP*
                                 \($WSP*($nu(?:$CWSP$nu)*)$WSP*\)/x);
}

# viewBox and pAR
our %RE_VIEW_BOX = ();
{
    my $nu = $RE_NUMBER{A_NUMBER};

    $RE_VIEW_BOX{p_VIEW_BOX} = qr/^($nu)$CWSP($nu)$CWSP($nu)$CWSP($nu)$/;
    $RE_VIEW_BOX{ALIGN}      = qr/(none
                                   |x(?:Min|Mid|Max)Y(?:Min|Mid|Max))/x;
    $RE_VIEW_BOX{MOS}        = qr/(meet|slice)/;
    $RE_VIEW_BOX{p_PAR}      = qr/^(?:defer\ +)?
                                  (?:$RE_VIEW_BOX{ALIGN}
                                   \ +$RE_VIEW_BOX{MOS}
                                   |$RE_VIEW_BOX{ALIGN})$/x;
}

# path data
# The following regular expressions are basically a one-to-one
# translation of the Backus Naur form given in the SVG
# specification on
# http://www.w3.org/TR/SVG11/paths.html#PathDataBNF
# There is the following identifier correspondence:
# svg-path                                   - $p_PATH_LIST
# moveto-drawto-command-groups               - $pcgm
# moveto-drawto-command-group                - $pcg
# drawto-commands                            - $dtm
# drawto-command                             - $dt
# moveto                                     - $mt
# moveto-argument-sequence                   - $mas
# closepath                                  - $cl
# lineto                                     - $lt
# lineto-argument-sequence                   - $las
# horizontal-lineto                          - $hlt
# horizontal-lineto-argument-sequence        - $hlas
# vertical-lineto                            - $vlt
# vertical-lineto-argument-sequence          - $vlas
# curveto                                    - $ct
# curveto-argument-sequence                  - $cas
# curveto-argument                           - $ca
# smooth-curveto                             - $sct
# smooth-curveto-argument-sequence           - $scas
# smooth-curveto-argument                    - $sca
# quadratic-bezier-curveto                   - $qb
# quadratic-bezier-curveto-argument-sequence - $qbas
# smooth-quadratic-bezier-curveto            - $sqb
# elliptical-arc                             - $ea
# elliptical-arc-argument-sequence           - $eaas
# elliptical-arc-argument                    - $eaa
# coordinate-pair                            - $cp

our %RE_PATH = ();
{
    my  $fl      = qr/[01]/;
    my  $cp      = qr/$RE_NUMBER{A_NUMBER}$CWSP?$RE_NUMBER{A_NUMBER}/;
    my  $mas     = qr/$cp(?:$CWSP?$cp)*/;
    my  $mt      = qr/(?:M|m)$WSP*$mas/;
    my  $cl      = qr/(?:Z|z)/;
#    my  $las     = $mas;  # if changed check carefully all below
    my  $lt      = qr/(?:L|l)$WSP*$mas/;
    my  $hlas    = qr/$RE_NUMBER{A_NUMBER}(?:$CWSP?$RE_NUMBER{A_NUMBER})*/;
    my  $hlt     = qr/(?:H|h)$WSP*$hlas/;
#    my  $vlas    = $hlas;  # if changed check carefully all below
    my  $vlt     = qr/(?:V|v)$WSP*$hlas/;
    my  $ca      = qr/$cp$CWSP?$cp$CWSP?$cp/;
    my  $cas     = qr/$ca(?:$CWSP?$ca)*/;
    my  $ct      = qr/(?:C|c)$WSP*$cas/;
    my  $sca     = qr/$cp$CWSP?$cp/;
    my  $scas    = qr/$sca(?:$CWSP?$sca)*/;
    my  $sct     = qr/(?:S|s)$WSP*$scas/;
#    my  $qbas    = $scas;  # if changed check carefully all below
    my  $qb      = qr/(?:Q|q)$WSP*$scas/;
#    my  $sqbas   = $mas;  # if changed check carefully all below
    my  $sqb     = qr/(?:T|t)$WSP*$mas/;
    my  $eaa     = qr/$RE_NUMBER{A_NNNUMBER}$CWSP?
                      $RE_NUMBER{A_NNNUMBER}$CWSP?
                      $RE_NUMBER{A_NUMBER}$CWSP
                      $fl$CWSP$fl$CWSP
                      $cp/x;
    my  $eaas    = qr/$eaa(?:$CWSP?$eaa)*/;
    my  $ea      = qr/(?:A|a)$WSP*$eaas/;
    my  $dt      = qr/(?:$cl|$lt|$hlt|$vlt|$ct|$sct|$qb|$sqb|$ea)/;
    my  $dtm     = qr/$dt(?:$WSP*$dt)*/;        # draw to multiple
    my  $pcg     = qr/$mt(?:$WSP*$dtm)?/;       # path command group

    $RE_PATH{p_PATH_LIST} = qr/^$pcg(?:$WSP*$pcg)*$/;
    $RE_PATH{s_PATH_LIST} = qr/^$pcg(?:$WSP*$pcg)*/;
    $RE_PATH{MAS_SPLIT}   = qr/^($RE_NUMBER{A_NUMBER})$CWSP?
                                ($RE_NUMBER{A_NUMBER})$CWSP?
                                ($mas?)$/x;
    $RE_PATH{LAS_SPLIT}   = $RE_PATH{MAS_SPLIT};
    $RE_PATH{HLAS_SPLIT}  = qr/^($RE_NUMBER{A_NUMBER})$CWSP?
                                ($hlas?)$/x;
    $RE_PATH{VLAS_SPLIT}  = $RE_PATH{HLAS_SPLIT};
    $RE_PATH{CAS_SPLIT}   = qr/^($RE_NUMBER{A_NUMBER})$CWSP?
                                ($RE_NUMBER{A_NUMBER})$CWSP?
                                ($RE_NUMBER{A_NUMBER})$CWSP?
                                ($RE_NUMBER{A_NUMBER})$CWSP?
                                ($RE_NUMBER{A_NUMBER})$CWSP?
                                ($RE_NUMBER{A_NUMBER})$CWSP?
                                ($cas?)$/x;
    $RE_PATH{SCAS_SPLIT}  = qr/^($RE_NUMBER{A_NUMBER})$CWSP?
                                ($RE_NUMBER{A_NUMBER})$CWSP?
                                ($RE_NUMBER{A_NUMBER})$CWSP?
                                ($RE_NUMBER{A_NUMBER})$CWSP?
                                ($scas?)$/x;
    $RE_PATH{QBAS_SPLIT}  = $RE_PATH{SCAS_SPLIT};
    $RE_PATH{SQBAS_SPLIT} = $RE_PATH{MAS_SPLIT};
    $RE_PATH{EAAS_SPLIT}  = qr/^($RE_NUMBER{A_NNNUMBER})$CWSP?
                                ($RE_NUMBER{A_NNNUMBER})$CWSP?
                                ($RE_NUMBER{A_NUMBER})$CWSP
                                ($fl)$CWSP($fl)$CWSP
                                ($RE_NUMBER{A_NUMBER})$CWSP?
                                ($RE_NUMBER{A_NUMBER})$CWSP?
                                ($eaas?)$/x;
}

# stroke-dasharray
our %RE_DASHARRAY = ();
$RE_DASHARRAY{p_DASHARRAY} = qr/^$RE_LENGTH{A_LENGTH}
                                 (?:$WSP*\,$WSP*$RE_LENGTH{A_LENGTH})*$/x;
$RE_DASHARRAY{SPLIT}       = qr/$WSP*\,$WSP*/;

# polyline / polygon
our %RE_POLY = ();
{
    my  $cp = qr/$RE_NUMBER{A_NUMBER}$CWSP?$RE_NUMBER{A_NUMBER}/;
    my  $pm = qr/$cp(?:$CWSP$cp)*/;  # point multiple
    $RE_POLY{p_POINTS_LIST} = qr/^$WSP*$pm$WSP*$/;
    $RE_POLY{s_POINTS_LIST} = qr/^$WSP*$pm$WSP*/;
    $RE_POLY{POINTS_SPLIT}  = qr/^($RE_NUMBER{A_NUMBER})$CWSP?
                                  ($RE_NUMBER{A_NUMBER})$CWSP?
                                  ($pm?)$/x;
}

# text
our %RE_TEXT = ();
{
    my $as = qr/(?:xx-small
                  |x-small
                  |small
                  |medium
                  |large
                  |x-large
                  |xx-large)/x;
    my $rs = qr/(?:smaller|larger)/;
    $RE_TEXT{p_FONT_SIZE} = qr/^(?:$as|$rs|$RE_LENGTH{A_LENGTH})$/;
}

1;


__END__

=pod

=head1 DESCRIPTION

This package offers a set of regular expressions for export. Many of
them are precompiled into downstream expressions, therefore changing
them would probably not have the desired outcome. Therefore they are
also not documented in full detail, see the code for the details.

=head2 C<A> versus C<P>

Floating point number expressions are divided into C<A> (for
attribute) and C<P> (for property) versions,
e.g. C<$RE_NUMBER{A_FLOAT}> and C<$RE_NUMBER{P_FLOAT}>. The reason
for that is that apparently, the C<CSS> specification prohibits
floating point numbers in scientific notation
(e.g. C<3e-7>). However, the C<XML> standard allows such numbers in
attribute values. Currently, however, C<SVG::Rasterize> does not
make use of this distinction and always uses the C<A>
version. Therefore, it will not complain if you provide a number in
scientific notation within a C<style> attribute although strictly,
this is forbidden by the specification. This may or may not change
in the future.

=head2 C<p>, C<w>, and C<s>

The regular expressions from this package might be used to build
more complex expressions, but are also used to validate values which
should match the expression fully (not a substring). Therefore, some
expressions have C<p> (for pure) and C<w> (for white space)
versions. If C<$RE> is an expression then C<$p_RE> will be
C<qr/^$RE$/>, and C<$w_RE> will be C<qr/^$WSP*$RE$WSP*$/>.

The validation expressions for path data and points lists of
C<polyline> and C<polygon> elements also have a C<s> (for start)
version. The background is that they are supposed to be rendered up
to the erroneous part. If they match fully is only found out when
they are split up into parts.

=head1 LIST OF EXPRESSIONS

Two expressions are exported directly as scalars, the other ones are
organized in a set of hashes:

=over 4

=item * $WSP  = qr/[\x{20}\x{9}\x{D}\x{A}]/

This is one white space character as defined by the C<SVG>
specification (inherited from C<XML> I suppose). The character class
consists of C<SPACE>, C<TAB>, C<CR>, and C<LF>.

=item * $CWSP = qr/(?:$WSP+\,?$WSP*|\,$WSP*)/

White space or comma, possibly surrounded by white space.

=item * %RE_PACKAGE

Currently, this hash contains only one entry:

    $RE_PACKAGE{p_PACKAGE_NAME} =
	qr/^$package_part(?:\:\:$package_part)*$/;

where C<$package_part> is a lexical variable with the value
C<qr/[a-zA-Z][a-zA-Z0-9\_]*/>.

Package names given to some methods in this distribution have to
match this regular expression. I am not sure which package names
exactly are allowed. If you know where in the Perl manpages or the
Camel book this is described, please point me to it. If this pattern
is too strict for your favourite package name, you can change this
variable.

=item * %RE_XML

Expressions for C<XML> Names and Nmtokens, see
L<http://www.w3.org/TR/2006/REC-xml11-20060816/#xml-names>.
Currently, only the C<ASCII> subset of allowed characters is allowed
here because I do not know how to build efficient regular
expressions supporting the huge allowed character class.

=item * %RE_URI

Expressions to parse C<URI>s. Largely inspired by an expression
given in L<RFC2396|http://www.ietf.org/rfc/rfc2396.txt>. These
expressions can be used to recognize a C<URI> and split it into its
pieces, but not for validation. It is enough for now, though.

=item * %RE_NUMBER

Contains expressions for integer and floating point numbers. The
reasons for building own regular expressions are that the format is
specified in terms of a Backus Naur form in the C<SVG>
specification, e.g. here:
L<http://www.w3.org/TR/SVG11/coords.html#TransformAttribute>. Note
that these expressions allow leading zeroes like '00030' or
'000.123'.

=item * %RE_LENGTH

Lengths in C<SVG> consist of a number and optionally a length
unit. See L<Units|SVG::Rasterize/Units> in C<SVG::Rasterize>.

=item * %RE_PAINT

Expressions for C<paint> attributes (see
L<http://www.w3.org/TR/SVG11/painting.html#SpecifyingPaint>).

=item * %RE_TRANSFORM

Regular expressions required to parse values of the C<transform>
attribute. These expressions are constructed according to the
Backus Naur form at
L<http://www.w3.org/TR/SVG11/coords.html#TransformAttribute>.

=item * %RE_VIEW_BOX

Regular expressions required to parse values of the C<viewBox> and
C<preserveAspectRatio> attributes.

=item * %RE_PATH

Regular expressions required to parse path data strings. These
expressions are constructed according to the Backus Naur form at
L<http://www.w3.org/TR/SVG11/paths.html#PathDataBNF>.

=item * %RE_DASHARRAY

Regular expressions required to parse values of the
C<stroke-dasharray> property.

=item * %RE_POLY

Regular expressions required to parse values of the C<points>
attribute of C<polyline> and C<polygon> elements. These expressions
are constructed according to the Backus Naur form at
L<http://www.w3.org/TR/SVG11/shapes.html#PointsBNF>.

=item * %RE_TEXT

Regular expressions required to parse values associated with text
that have a more complex structure, e.g. the C<font-size> attribute.

=back


=head1 C<EXPORT_TAGS>

The following export tags can be used like

  use SVG::Rasterize::Regexes qw(:whitespace);

=over 4

=item * C<:all>

=item * C<:whitespace>

C<$WSP> and C<$CWSP>.

=item * C<:attributes>

C<%RE_NUMBER>, C<%RE_LENGTH>, C<%RE_PAINT>, C<%RE_TRANSFORM>,
C<%RE_VIEW_BOX>, C<%RE_PATH>, C<%RE_DASHARRAY>, C<%RE_POLY>.

=back

=head1 SEE ALSO

=over 4

=item * L<SVG::Rasterize|SVG::Rasterize>

=back


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify
it under the terms of either: the GNU General Public License as
published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
