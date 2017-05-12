<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
version="1.0">

<!--

=head1 pod2axpoint.xsl

=head1 NAME

pod2axpoint.xsl - Stylesheet to convert XMLified POD to AxPoint format

=head1 SYNOPSIS

Use Perl to generate XML from POD:

  use XML::SAX::Writer;
  use Pod::SAX;
  my $source = shift(@ARGV) or die;
  my $output = shift (@ARGV) || \*STDOUT;
  my $p = Pod::SAX->new({Handler => XML::SAX::Writer->new()});
  $p->parse_uri($source);

No perl needed to transform the result to axpoint:

  xsltproc pod2axpoint.xsl foo.pod.xml > foo.axp

Finally transform that with the axpoint script to PDF:

  axpoint foo.axp foo.pdf

=head1 DESCRIPTION

Pod is convenient to write markup.

AxPoint is a powerful, prominent presentation
markup.

This XSLT stylesheet attempts to close the gap between POD and
AxPoint.

It is meant only for a subset of POD, not all of it. The idea is to
let you write presentations in POD to convert to axpoint format, not
to convert any POD document to a presentation. Actually, it fails on a
broad variety of real world POD documents.

It is also meant only for a subset of AxPoint. The C<transition>
attribute for the C<title>, C<slide>, and C<point> element are not
accessible through POD directives. Nor is the C<metadata> section or
the C<image>, C<colour>, C<table>, C<rect>, C<circle>, C<ellipse>,
C<line>, and C<text> elements. To make these options available, it is
necessary to edit the stylesheet itself.

=head1 CONFIGURATION

You are expected to edit pod2axpoint.xsl to contain the speaker,
organisation, etc., maybe a background image, or other metadata.

=head1 DEMO

A C<=head1> in the POD starts a new slide and sets the title. The very
first C<=head1> sets the headline on the title page. Anything between
the first and the second C<=head1> is ignored. Edit the stylesheet
metadata section to fill the titlepage. Every paragraph is a point.
There are other ways to generate points too:

=head2 This is the content of a head2 tag

=head3 This is the content of a head3 tag

=over 4

=item An item after an over 4

And a paragraph within this item. As a paragraph is a point itself, we
enter recursion here and the point gets a deeper level.

=item Another item, the last one on this slide

=back

=head1 DEMO (cont'd)

A paragraph with B<bold> text, I<italic> text, some C<$code+@code>, all
of them produced with the POD inline tags. The next paragraph is
indented POD, so that it must be rendered as source code:

    sub foo { @{[[1,2]]} };
    my ($one,$two) = @{foo()};
    # my ($list) = foo(); my ($one,$two) = @$list;
    print "1[$one] 2[$two]\n";

And this is the third (and last) paragraph on this slide.

=head1 DEMO (cont'd)

=over 2

=item Enjoy nesting (the item)

Enjoy nesting (the paragraph)

=over 4

=item Enjoy nesting next level (the item)

Enjoy nesting next level (the paragraph)

=over 6

=item Enjoy nesting 3rd (the item)

Enjoy nesting 3rd (the paragraph)

=back

=back

=back

=head1 This Manpage as Slideshow

In the root directory of the Pod::SAX distribution, run

    make pdf

and all conversions will happen, finally acroread will be called to
display the slideshow.

=cut

-->

<xsl:output method="xml" indent="yes"/>

<xsl:key name="headings"
 match="/pod/para|
        /pod/head2|
        /pod/head3|
        /pod/verbatim|
        /pod/orderedlist|
        /pod/itemizedlist"
 use="generate-id(preceding::head1[1])"/>

<xsl:template match="/">
<slideshow>
  <title><xsl:value-of select="/pod/head1[1]"/></title>
  <metadata>
    <speaker>Ask Bjorn Hansen</speaker>
    <email>ask@perl.org</email>
  </metadata>

  <xsl:apply-templates select="/pod/head1[position() > 1]"/>

</slideshow>
</xsl:template>

<xsl:template match="head1">
  <xsl:variable name="this-id">
    <xsl:value-of select="generate-id(.)"/>
  </xsl:variable>

    <slide>
      <title><xsl:apply-templates/></title>
      <xsl:apply-templates select="key('headings', $this-id)"/>
    </slide>
</xsl:template>

<xsl:template match="verbatim">
  <source-code>
  <xsl:apply-templates/>
  </source-code>
</xsl:template>

<xsl:template match="head2">
  <point><b><i>
  <xsl:apply-templates/>
  </i></b></point>
</xsl:template>

<xsl:template match="head3">
  <point><b>
  <xsl:apply-templates/>
  </b></point>
</xsl:template>

<xsl:template match="itemizedlist|orderedlist">
  <xsl:param name="level" select="1" />
  <xsl:apply-templates>
    <xsl:with-param name="level" select="$level" />
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="listitem">
  <xsl:param name="level" select="1" />
  <xsl:for-each select="node()">
    <xsl:choose>
      <xsl:when test="name(.) = 'para'
                      or name(.) = 'listitem'
                      or name(.) = 'itemizedlist'
                      or name(.) = 'orderedlist'">
        <xsl:if test="$level &lt; 3">
          <xsl:apply-templates select=".">
            <xsl:with-param name="level" select="$level + 1" />
          </xsl:apply-templates>
        </xsl:if>
        <xsl:if test="$level &gt;= 3">
          <xsl:apply-templates select=".">
            <xsl:with-param name="level" select="$level" />
          </xsl:apply-templates>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="c" select="normalize-space(.)" />
        <xsl:if test="$c">
          <point>
            <xsl:attribute name="level">
              <xsl:value-of select="$level" />
            </xsl:attribute>
            <xsl:value-of select="$c" />
          </point>
          <xsl:apply-templates />
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>
</xsl:template>

<xsl:template match="para">
  <xsl:param name="level" select="1" />
  <xsl:variable name='preceder' select="name(preceding-sibling::*[position() = 1])"/>
  <xsl:choose>
    <xsl:when test="$preceder = 'markup'">
      <!-- ignore the paragraph in a =for section -->
    </xsl:when>
    <xsl:otherwise>
      <point>
        <xsl:attribute name="level">
          <xsl:value-of select="$level" />
        </xsl:attribute>
        <xsl:apply-templates />
      </point>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="link">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="B">
  <b><xsl:apply-templates/></b>
</xsl:template>

<xsl:template match="C">
  <span style="font-family: monospace">
  <xsl:apply-templates/>
  </span>
</xsl:template>

<xsl:template match="I">
  <i><xsl:apply-templates/></i>
</xsl:template>

<xsl:template match="F">
  <xsl:apply-templates/>
</xsl:template>

</xsl:stylesheet>
