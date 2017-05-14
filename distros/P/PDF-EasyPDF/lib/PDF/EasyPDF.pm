package PDF::EasyPDF;
use 5.0005;
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(inch mm);
our $VERSION = 0.04;

use utf8;

=head1 NAME

PDF::EasyPDF - PDF creation from a one-file module, with postscript-like controls

=head1 SYNOPSIS

use PDF::EasyPDF;

my $pdf = PDF::EasyPDF->new({file=>"mypdffile.pdf",x=>mm(297),y=>mm(210)});

$pdf->setStrokeColor("CC0000");

$pdf->setStrokeWidth(8);

$pdf->rectangle(mm(10),mm(10),mm(297-20),mm(210-20));

$pdf->setFillColor("FFCC00");

$pdf->filledRectangle(mm(20),mm(20),mm(297-40),mm(210-40));

$pdf->setFillColor("CC0000");

$pdf->setFontFamily("Helvetica-Bold");

$pdf->setFontSize(24);

$pdf->text(mm(105),mm(210-22.5),"PDF::EasyPDF Demo");

$pdf->lines(mm(85),mm(35),mm(90),mm(105),mm(95),mm(35),mm(100),mm(105),mm(105),mm(35),mm(110),mm(105));

$pdf->setStrokeColor("000099");

$pdf->curve(300,300,300,400,400,400,400,300);

$pdf->setStrokeColor("0066FF");

$pdf->setFillColor("00FFFF");

$pdf->polygon(100,100,250,200,250,400,200,500);

$pdf->filledPolygon(100,100,250,200,250,400,200,500);

$pdf->close;

=head1 DESCRIPTION

This module started life as a workaround, on discovering that PDF::API2 and friends are extremely tricky to compile using Activestate's PerlApp utility because of the large number of runtime modules and resource files they use. The module consists of a single .pm file. It produces small PDF files, partly because it only uses the 14 standard PDF fonts. Page content is implemented using a single stream object, and the controls are vaguely postscript-like.

=head1 AUTHOR

Mark Howe, E<lt>melonman@cpan.orgE<gt>

=head2 EXPORT

The C<mm> and C<inch> functions.

=cut

my $fonts = {"Times-Roman" => "TIM",
             "Times-Bold" => "TIMB",
             "Times-Italic" => "TIMI",
             "Times-BoldItalic" => "TIMBI",
             "Helvetica" => "HEL",
             "Helvetica-Bold" => "HELB",
             "Helvetica-Oblique" => "HELO",
             "Helvetica-BoldOblique" => "HELBO",
             "Courier" => "COU",
             "Courier-Bold" => "COUB",
             "Courier-Oblique" => "COUO",
             "Courier-BoldOblique" =>"COUBO",
             "Symbol" => "SYM",
             "ZapfDingbats" => "ZAP"};

my $standard_objects = <<STANDARD_OBJECTS;
1 0 obj
<< /Type /Catalog
   /Outlines 2 0 R
   /Pages 3 0 R
   >>
   endobj

2 0 obj
<< /Type Outlines
   /Count 0
   >>
   endobj

3 0 obj
<< /Type /Pages
   /Kids [4 0 R]
   /Count 1
   >>
   endobj

4 0 obj
<< /Type /Page
   /Parent 3 0 R
   /MediaBox [0 0 !!X!! !!Y!!]
   /Contents 20 0 R
   /Resources << /ProcSet 5 0 R
                 /Font << /TIM 6 0 R
                          /TIMB 7 0 R
                          /TIMI 8 0 R
                          /TIMBI 9 0 R
                          /HEL 10 0 R
                          /HELB 11 0 R
                          /HELO 12 0 R
                          /HELBO 13 0 R
                          /COU 14 0 R
                          /COUB 15 0 R
                          /COUO 16 0 R
                          /COUBO 17 0 R
                          /SYM 18 0 R
                          /ZAP 19 0 R
                          >>
              >>
   >>
   endobj

5 0 obj
   [/PDF /Text]
   endobj

6 0 obj
<< /Type /Font
   /Subtype /Type1
   /Name /TIM
   /BaseFont /Times-Roman
   /Encoding /MacRomanEncoding
   >>
   endobj

7 0 obj
<< /Type /Font
   /Subtype /Type1
   /Name /TIMB
   /BaseFont /Times-Bold
   /Encoding /MacRomanEncoding
   >>
   endobj

8 0 obj
<< /Type /Font
   /Subtype /Type1
   /Name /TIMI
   /BaseFont /Times-Italic
   /Encoding /MacRomanEncoding
   >>
   endobj

9 0 obj
<< /Type /Font
   /Subtype /Type1
   /Name /TIMBI
   /BaseFont /Times-BoldItalic
   /Encoding /MacRomanEncoding
   >>
   endobj

10 0 obj
<< /Type /Font
   /Subtype /Type1
   /Name /HEL
   /BaseFont /Helvetica
   /Encoding /MacRomanEncoding
   >>
   endobj

11 0 obj
<< /Type /Font
   /Subtype /Type1
   /Name /HELB
   /BaseFont /Helvetica-Bold
   /Encoding /MacRomanEncoding
   >>
   endobj

12 0 obj
<< /Type /Font
   /Subtype /Type1
   /Name /HELO
   /BaseFont /Helvetica-Oblique
   /Encoding /MacRomanEncoding
   >>
   endobj

13 0 obj
<< /Type /Font
   /Subtype /Type1
   /Name /HELBO
   /BaseFont /Helvetica-BoldOblique
   /Encoding /MacRomanEncoding
   >>
   endobj

14 0 obj
<< /Type /Font
   /Subtype /Type1
   /Name /COU
   /BaseFont /Courier
   /Encoding /MacRomanEncoding
   >>
   endobj

15 0 obj
<< /Type /Font
   /Subtype /Type1
   /Name /COUB
   /BaseFont /Courier-Bold
   /Encoding /MacRomanEncoding
   >>
   endobj

16 0 obj
<< /Type /Font
   /Subtype /Type1
   /Name /COUO
   /BaseFont /Courier-Oblique
   /Encoding /MacRomanEncoding
   >>
   endobj

17 0 obj
<< /Type /Font
   /Subtype /Type1
   /Name /COUBO
   /BaseFont /Courier-BoldOblique
   /Encoding /MacRomanEncoding
   >>
   endobj

18 0 obj
<< /Type /Font
   /Subtype /Type1
   /Name /SYM
   /BaseFont /Symbol
   /Encoding /MacRomanEncoding
   >>
   endobj

19 0 obj
<< /Type /Font
   /Subtype /Type1
   /Name /ZAP
   /BaseFont /ZapfDingbats
   /Encoding /MacRomanEncoding
   >>
   endobj

STANDARD_OBJECTS

my $content_object = <<CONTENT_OBJECT;
20 0 obj
<< /Length !!LENGTH!! >>
stream
!!STREAM!!endstream
endobj
CONTENT_OBJECT

=head1 METHODS

=cut

=head2 new({file, x, y})

Creates a new PDF::EasyPDF object. The arguments are passed as an anonymous hash to allow, eventually, for different combinations of arguments. I<filename> is the name of the PDF to be created (although nothing is output until the C<close> method is called. I<x> and I<y> are the x and y dimensions of the page in points (see the C<mm> and C<inch> functions for a more convenient way to specify page sizes).

=cut

sub new
{my $type = shift;
 my $hash = shift;
 my $self={};
 my @args = ('file','x','y');
 foreach my $arg (@args)
    {$self->{$arg} = $hash->{$arg}};
 $self->{stream} = "";
 $self->{font_name} = $fonts->{Courier};
 $self->{font_size} = 10;
 bless($self,$type);
 return $self};

=head2 close()

Writes a pdf file.

=cut

sub close
{my $self = shift;
 my @offsets = ();
 my $out="%PDF-1.4\n";
 foreach my $ob (split /\n\n+/,$standard_objects . $self->content_object)
    {if
      ($ob =~/!!LENGTH!!/)
      {$ob=~/stream\n(.*)endstream/s;
       my $length=length($1);
       $ob=~s/!!LENGTH!!/$length/e};
     $ob=~s/!!X!!/int($self->{x}+0.5)/e;
     $ob=~s/!!Y!!/int($self->{y}+0.5)/e;
     push @offsets,length($out);
     $out .= "$ob\n\n"};
 my $xrefoffset = length($out);
 $out .= sprintf "xref\n0 %i\n0000000000 65535 f \n",$#offsets+2;
 foreach (@offsets)
    {$out .= sprintf "%10.10i 00000 n \n",$_}
 $out .= sprintf "\n\ntrailer\n<< /Size %i\n /Root 1 0 R\n>>\nstartxref\n$xrefoffset\n%%%%EOF",$#offsets+2;
 open (EASYPDF,">$self->{file}") or die "EasyPDF could not write PDF file '$self->{file}' : $!";
 print EASYPDF $out;
 close EASYPDF}

sub content_object
{my $self = shift;
 my $ret=$content_object;
 $ret =~s/!!STREAM!!/$self->{stream}/s;
 return $ret}

=head2 fonts

Returns a list of supported fonts (currently the fourteen standard Adobe fonts).

=cut

sub fonts
{return sort keys %{$fonts}}

=head2 setStrokeColor(rrggbb);

Sets the stroke (more or less 'line') colour using an html-like rrggbb string, ie C<FFFF00> = bright yellow.

=cut

sub setStrokeColor
{my $self = shift;
 my ($r,$g,$b) = rrggbb(shift);
 $self->{stream} .= "$r $g $b RG\n"}

=head2 setFillColor(rrggbb)

Sets the fill colour (including the text colour).

=cut

sub setFillColor
{my $self = shift;
 my ($r,$g,$b) = rrggbb(shift);
 $self->{stream} .= "$r $g $b rg\n"}

sub rrggbb
{my $hexstring = shift;
 $hexstring =~/([0-9A-F][0-9A-F])([0-9A-F][0-9A-F])([0-9A-F][0-9A-F])/i;
 return (hex($1)/255,hex($2)/255,hex($3)/255)}

=head2 setStrokeWidth(width)

Sets the stroke (more or less 'line') width in points.

=cut

sub setStrokeWidth
{my $self = shift;
 my $w = shift;
 $self->{stream} .= "$w w\n"}

=head2 setFontFamily(fontname)

Sets the font.

=cut

sub setFontFamily
{my $self = shift;
 my $font = shift;
 die "Unknown font '$font'" unless defined $fonts->{$font};
 $self->{font_name} = $fonts->{$font}}

=head2 setFontSize(size)

Sets the font size in points

=cut

sub setFontSize
{my $self = shift;
 my $size = shift;
 $size+=0;
 die "Bad font size '$size'" unless $size > 0;
 $self->{font_size} = $size}

=head2 setDash(lengths)

Sets the dash pattern. Pass a list of numbers to set the alternating 'on' and 'off' lengths in points, or, with no arguments, to reset to a solid line

=cut

sub setDash
{my $self = shift;
 if
    (defined $_[1])
    {$self->{stream}.= "[ ";
     while
        (@_)
        {$self->{stream}.= shift(@_) . " "};
     $self->{stream} .= "] 0 d\n"}
    else
    {$self->{stream} .= "[] 0 d\n"}} 

=head2 setCap(style)

Set the cap style for the ends of lines. Options are C<round>, C<square> or C<butt>.

=cut

sub setCap
{my $self = shift;
 my $captype = shift;
 if
    (lc($captype) eq 'round')
    {$self->{stream}.= "1 J\n"}
    elsif
    ((lc($captype) eq 'square') or (lc($captype) eq 'projecting'))
    {$self->{stream} .= "2 J\n"}
    else
    {$self->{stream} .= "0 J\n"}}

=head2 setJoin(style)

Set the join style for lines. Options are C<round>, C<bevel> or C<miter>.

=cut

sub setJoin
{my $self = shift;
 my $captype = shift;
 if
    (lc($captype) eq 'round')
    {$self->{stream}.= "1 j\n"}
    elsif
    (lc($captype) eq 'bevel')
    {$self->{stream} .= "2 j\n"}
    else
    {$self->{stream} .= "0 j\n"}}

=head2 text(x,y,string)

Places text at x,y

=cut

sub text
{my $self = shift;
 my ($x,$y,$text) = @_;
 $self->{stream} .="BT\n/$self->{font_name} $self->{font_size} Tf\n$x $y Td\n($text) Tj\nET\n"}

=head2 lines(x1,y1,x2,y2, ...)

Prints one or more lines, using alternative x and y coordinates.

=cut

sub lines
{my $self = shift;
 my $startx = shift;
 my $starty = shift;
 $self->{stream} .= "$startx $starty m\n";
 while
   (@_)
   {my $nextx = shift(@_);
    my $nexty = shift(@_);
    $self->{stream} .= "$nextx $nexty l\n"};
 $self->{stream} .= "S\n"}

=head2 polygon(x1,y1,x2,y2, ...)

Prints a closed, unfilled polygon using alternative x and y coordinates.

=cut

sub polygon
{my $self = shift;
 my $startx = shift;
 my $starty = shift;
 $self->{stream} .= "$startx $starty m\n";
 while
   (@_)
   {my $nextx = shift(@_);
    my $nexty = shift(@_);
    $self->{stream} .= "$nextx $nexty l\n"};
 $self->{stream} .= "h\nS\n"}

=head2 filledPolygon(x1,y1,x2,y2, ...)

Prints a closed, filled polygon with no border using alternative x and y coordinates.

=cut

sub filledPolygon
{my $self = shift;
 my $startx = shift;
 my $starty = shift;
 $self->{stream} .= "$startx $starty m\n";
 while
   (@_)
   {my $nextx = shift(@_);
    my $nexty = shift(@_);
    $self->{stream} .= "$nextx $nexty l\n"};
 $self->{stream} .= "h\nf\n"}

=head2 curve(x1,y1,x2,y2,x3,y3,x4,y4)

Prints a bezier curve.

=cut

sub curve
{my $self = shift;
 my $startx = shift;
 my $starty = shift;
 $self->{stream} .= "$startx $starty m\n$_[0] $_[1] $_[2] $_[3] $_[4] $_[5] c\nS\n"}

=head2 filledCurve(x1,y1,x2,y2,x3,y3,x4,y4)

Prints a filled bezier curve without a border.

=cut

sub filledCurve
{my $self = shift;
 my $startx = shift;
 my $starty = shift;
 $self->{stream} .= "$startx $starty m\n$_[0] $_[1] $_[2] $_[3] $_[4] $_[5] c\nh\nf\n"}

=head2 closedCurve(x1,y1,x2,y2,x3,y3,x4,y4)

Prints an unfilled bezier curve, with the first and last points joined by a straight line.

=cut

sub closedCurve
{my $self = shift;
 my $startx = shift;
 my $starty = shift;
 $self->{stream} .= "$startx $starty m\n$_[0] $_[1] $_[2] $_[3] $_[4] $_[5] c\nh\nS\n"}

=head2 moveSegment(x,y)

Inserts a move operation (use to start new paths)

=cut

sub moveSegment
{my $self = shift;
 my $x = shift;
 my $y = shift;
 $self->{stream} .= "$x $y m\n"}

=head2 lineSegment(x,y)

Inserts a line segment

=cut

sub lineSegment
{my $self = shift;
 my $x = shift;
 my $y = shift;
 $self->{stream} .= "$x $y l\n"}

=head2 curveSegment(x,y)

Inserts a curve segment

=cut

sub curveSegment
{my $self = shift;
 $self->{stream} .= "$_[0] $_[1] $_[2] $_[3] $_[4] $_[5] c\n"}

=head2 closePath()

Closes a path

=cut

sub closePath
{my $self = shift;
 $self->{stream} .= "h\n"}

=head2 strokePath()

Strokes the path

=cut

sub strokePath
{my $self = shift;
 $self->{stream} .= "S\n"}

=head2 fillPath()

Fills the path using the non-zero winding number rule

=cut

sub fillPath
{my $self = shift;
 $self->{stream} .= "f\n"}

=head2 fillStarPath()

Fills the path using the odd-even winding rule (f*, hence the 'star')

=cut

sub fillStarPath
{my $self = shift;
 $self->{stream} .= "f*\n"}

=head2 fillAndStrokePath()

Fills the path using the non-zero winding number rule and then strokes it

=cut

sub fillAndStrokePath
{my $self = shift;
 $self->{stream} .= "B\n"}

=head2 fillStarAndStrokePath()

Fills the path using the odd-even winding rule and then fills it (B*, hence the 'star')

=cut

sub fillStarAndStrokePath
{my $self = shift;
 $self->{stream} .= "B*\n"}

=head2 rectangle(x1,y1,xsize,ysize)

Prints an unfilled rectangle.

=cut

sub rectangle
{my $self = shift;
 my ($x,$y,$dx,$dy) = @_;
 $self->{stream} .="$x $y $dx $dy re\nS\n"}

=head2 filledRectangle(x1,y1,xsize,ysize)

Prints a filled rectangle with no border.

=cut

sub filledRectangle
{my $self = shift;
 my ($x,$y,$dx,$dy) = @_;
 $self->{stream} .="$x $y $dx $dy re\nF\n"}

=head1 FUNCTIONS

=head2 inch(inches)

Converts inches into points

=cut

sub inch
{my $inches = shift;
 return $inches * 72}

=head2 mm(mms)

Converts millimetres into points

=cut

sub mm
{my $mm = shift;
 return ($mm/25.4) * 72}

=head1 BUGS

None known, but the methods do relatively little sanity checking, and there is absolutely no encoding yet for text (so it's probably impossible to print parentheses, for example).

=head1 COMING SOON

A first stab at encoding text, arrowheads.

=head1 PREVIOUS VERSIONS

B<0.04>: Consistent capitalisation of methods, generic arbitrary path drawing mechanism.
B<0.03>: Beat module into something approaching standard CPAN shape.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Mark Howe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
