package VSG::VCD::Format;

=head1 NAME

SVG::VCD::Format - format of .vcd (vertebral column description) files

=head1 SYNOPSIS

 *width: 800
 *height: 565
 Taxon: Apatosaurus louisae
 Specimen: CM 3018
 Citation: Gilmore 1936:195 and plates 24-25
 Data: -----YVVVVVVVVV|VVVuuunnn-

=head1 DESCRIPTION

Vertebral Column Description (VCD) format is line-oriented. Each line
has a self-contained meaning.

Comments are introduced by a hash character (C<#>) and run to the end
of the line. They are ignored.

Leading and trailing whitespace are ignored.

Blank lines (including those consisting only of spaces and/or
comments) ignored.

All other lines fall into one of two categories:

=over 4

=item Configuration settings

These lines begin with an asterisk (C<*>). Each such line is of the
form C<*>I<property>C<:> I<value>. It sets the named property to the
specified value. Valid properties and their meanings are described
below.

=item Taxon data

All other lines are data. Each such line is of the form
I<property>C<:> I<value> with no leading asterisk. It provides data
about a specific taxon in the vertebral column diagram. Data is
described in detail below.

=back

Lines that do not match of either of these forms are invalid.

=head1 DATA

=over 4

=item C<Taxon>

Specifies the name of a taxon which will appear in the diagram.  The
data for each taxon begins with a C<Taxon> line. Following this, any
or all of the other three data lines may follow in any order.

=item C<Specimen>

Indicates the specimen number of the individual that is
described. Useful when multiple individuals of the same taxon are
included.

=item C<Citation>

Specifies the source of the observations in the C<Data> line:
typically either a citation of a published descriptive paper, or
"personal observation". At present, this is not used: the intention is
that a future version of VertFigure will include it in an auto-generated
caption.

=item C<Data>

Specifies the information about the individual vertebrae of the column
in question. The state of each vertebra is specified by a single
character, which can be anything at all. The way those states are
illustrated depends on how they are described by the
C<state->I<char>C<-color>
and
C<state->I<char>C<-polygon>
configuration settings described below. These can be configured in
such as way as to represent cervicals vs. dorsals, pneumatic
vs. apneumatic vertebrae, bifid vs. simple neural spines, or whatever
other characteristic is of interest.

Two characters in the data are special:

First, the hyphen (C<->) indicates that no data is available for the
vertebra in question, so nothing is drawn.

Second, the vertical bar (C<|>) indicates the anchor point: a position
within the vertebral column that is particular interest, such as the
cervicodorsal transition, or the dorsosacral transition. The anchor
points of all the vertebral columns will be horizontally aligned in
the output.

For consistency, in the configuration settings below this anchor point
is always referred to as the "cervico-dorsal" transition, the
vertebrae before it are referred to as "cervicals" and those after it
as "dorsals". But since these terms do not appear in the output, the
anchor point may be used as a different transition.

=back

=head1 CONFIGURATION SETTINGS

Each of these properties has a single global setting, which applies
across all taxa in the diagram. If a setting is set for a second time,
the new value replaces the old.

The following settings are recognised:

=over 4

=item C<background> I<color>

If specified, then the emitted SVG file has a solid background in the
specified colour; otherwise, it is transparent.

The value can be any string that is interpreted as identifying a color
in SVG -- for example, a name such as C<red> or an RGB triple such as
C<rgb(0,193,252)>.
See http://www.w3.org/TR/SVG11/types.html#Color

=item C<box-color> I<color> [default: C<grey>]

The color of the boxes that outline each vertebra. Can be removed
altogether by setting it to the same as the background colour.

=item C<cervical-height> I<length>

The height of the boxes drawn to contain "cervical" vertebrae,
i.e. those before the anchor point.

The value can be any string that is interpreted as identifying a
length in SVG -- for example,
C<2em>,
C<100px>
or
C<2.4cm>.
See http://www.w3.org/TR/SVG11/types.html#Length

=item C<cervical-width> I<length>

The width of the boxes drawn to contain "cervical" vertebrae,
i.e. those before the anchor point.

=item C<cervico-dorsal-color> I<color>

If specified, this is the colour in which the vertical line through
the cervical-dorsal anchor points of the aligned vertebral columns is
drawn; otherwise, no line is drawn.

=item C<cervico-dorsal-offset> I<length>

The offset of the cervico-dorsal anchor point across the area of the
drawing. Should between 0 and I<width>.

=item C<dorsal-height-gradient> I<length>

If defined, the height of each successive dorsal vertebra exceeds that
of its predecessor by the specified amount. Can be used to produce
increasingly tall (or increasingly short if negative) dorsal
vertebrae.

There is currently no corresponding C<cervical-height-gradient>
setting.

=item C<dorsal-height> I<length>


The height of the boxes drawn to contain "dorsal" vertebrae,
i.e. those after the anchor point.

=item C<dorsal-width> I<length>

The width of the boxes drawn to contain "dorsal" vertebrae,
i.e. those after the anchor point.

=item C<font-family> I<font>

The font family to be used for captions, including taxa and specimen
numbers. Taxon names are rendered in the italic variant of the font,
specimen numbers in the regular font. To inhibit the use of italics
for a taxon name (e.g. because it's a clade or family rather than a
genus or species), precede it with a forward slash (C</>).

The font family may be specified by a list of family-names, as in SVG
and CSS.
See http://www.w3.org/TR/SVG11/types.html#DataTypeListOfFamilyNames

=item C<font-size> I<length>

The font size to be used for captions.

=item C<height> I<length>

The height of the entire picture to be generated.

=item C<state-X-color> I<color>

The states of individual vertebra, represented by single characters
and indicated by C<Data> lines, are defined by C<state-X-color> and
C<state-X-polygon> pairs of settings. C<state-X-color> specifies what
color to use for drawing vertebrae of the state corresponding with the
characters I<X>.

=item C<state-X-polygon> I<list-of-points>

This specifies how vertebrae with state I<X> are drawn within their
boxes. It is specified as a space-separated sequence of I<x>,I<y>
pairs, each representing a point within a notional 1.0-by-1.0 space; a
polyline between each of these points in order and returning to the
first point is drawn and filled in the colour specified by the
corresponding C<state-X-color> setting.

The x-coordinate runs from left to right; the y-coordinate runs from
top to bottom.

Examples:

C<0,0 0,1 1,1 1,0> simply fills the box with solid color.

C<0,0 0.5,1 1,0> draws a triangle pointing downwards.

C<0.1,0.3 0.9,0.5 0.1,0.7> draws a small, narrow triangle pointing to
the right.

=item C<taxon-height> I<length>

The vertical spacing between consecutive taxa.

=item C<text-y-offset> I<length> [default: C<0>]

The distance to move text (i.e. taxon-and-specimen captions) down the
drawing relative to the vertebrae (or up if the offset is
negative). This can be useful to tweak alignment depending on what
font-family and size are used.

=item C<width> I<length>

The width of the entire picture to be generated.

=back

=head1 EXAMPLES

See
C<examples/bifurcation/bifurcation.vcd>
and
C<examples/pbj/pbj.vcd>
in the distributon. (Note that the latter must be preprocessed by the
m4 macro processor.)

=head1 SEE ALSO

VertFigure - program for translating VCD files into SVG.

=head1 AUTHOR

Copyright (C) 2013-2014 by Mike Taylor E<lt>mike@miketaylor.org.ukE<gt>

=head1 LICENSE

GNU General Public Licence v3.0

=cut


1;
