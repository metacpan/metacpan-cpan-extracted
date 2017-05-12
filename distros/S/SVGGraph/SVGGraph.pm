package SVGGraph;

use strict;
use warnings;
use utf8;
our $VERSION = '0.07';

sub new()
{
  my $self = shift;
  return bless {}, $self;
}

sub CreateGraph()
{
  ### First element of @_ is a reference to the element that called this subroutine
  my $self = shift;
  ### Second is a reference to a hash with options
  my $options = shift;
  ### The options passed in the anonymous hash are optional so create a default value first
  my $horiUnitDistance = 20;
  if ($$options{'horiunitdistance'})
  {
    $horiUnitDistance = $$options{'horiunitdistance'};
  }
  my $graphType = 'spline';
  if ($$options{'graphtype'})
  {
    $graphType = $$options{'graphtype'};
  }
  ### The rest are references to arrays with references to arrays with x and y values
  my @xyArrayRefs = @_;
  ### Check if the color ($xyArrayRefs[$i]->[3]) is provided. If not, choose black
  for (my $i = 0; $i < @xyArrayRefs; $i++)
  {
    unless ($xyArrayRefs[$i]->[3])
    {
      $xyArrayRefs[$i]->[3] = '#000000';
    }
  }
  ### Declare the $minX as the lowest value of x in the arrays, same for $minY, $maxX and $maxY
  my $minX = $xyArrayRefs[0]->[0]->[0]; ### Equivalent to ${${$xyArrayRefs[0]}[0]}[0];
  my $minY = $xyArrayRefs[0]->[1]->[0];
  my $maxX = $minX;
  my $maxY = $minY;
  ### Then really search for the lowest and highest value of x and y
  for (my $i = 0; $i < @xyArrayRefs; $i++)
  {
    for (my $j = 0; $j < @{$xyArrayRefs[$i]->[0]}; $j++)
    {
      if ($xyArrayRefs[$i]->[0]->[$j] > $maxX)
      {
        $maxX = $xyArrayRefs[$i]->[0]->[$j];
      }
      if ($xyArrayRefs[$i]->[0]->[$j] < $minX)
      {
        $minX = $xyArrayRefs[$i]->[0]->[$j];
      }
      if ($xyArrayRefs[$i]->[1]->[$j] > $maxY)
      {
        $maxY = $xyArrayRefs[$i]->[1]->[$j];
      }
      if ($xyArrayRefs[$i]->[1]->[$j] < $minY)
      {
        $minY = $xyArrayRefs[$i]->[1]->[$j];
      }
    }
  }
  ### If max equals min, change them artificially
  if ($maxX == $minX)
  {
    $maxX += 1;
  }
  if ($maxY == $minY)
  {
    $maxY += 1;
  }
  ### Calculate all dimensions neccessary to create the Graph
  ### Height of the total svg image in pixels:
  my $imageHeight = 400;
  if ($$options{'imageheight'})
  {
    $imageHeight = $$options{'imageheight'};
  }
  ### Width of the verticabar or dots in the graph
  my $barWidth = 3;
  if ($$options{'barwidth'})
  {
    $barWidth = $$options{'barwidth'};
  }
  ### Distance between the sides of the gris and the sides of the image:
  my $cornerDistance = 50;
  ### Since svg counts from the top left corner of the image, we translate all coordinates vertically in pixels:
  my $vertTranslate = $imageHeight - $cornerDistance;
  ### The width of the grid in pixels:
  my $gridWidth = $horiUnitDistance * ($maxX - $minX);
  ### The height of the grid in pixels:
  my $gridHeight = $imageHeight - 2 * $cornerDistance;
  ### The width of the whole svg image:
  my $imageWidth = $gridWidth + (4 * $cornerDistance);
  ### The horizontal space between vertical gridlines in pixels:
  my $xGridDistance = 20;
  ### The vertical space between horizontal gridlines in pixels:
  my $yGridDistance = 30;

  ### Now initiate the svg graph by declaring some general stuff.
  my $svg .= <<"  EOF";
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 20000303 Stylable//EN" "http://www.w3.org/TR/2000/03/WD-SVG-20000303/DTD/svg-20000303-stylable.dtd">
<svg width="$imageWidth" height="$imageHeight">
<defs>
  EOF
  if ($graphType eq 'spline')
  {
    for (my $i = 0; $i < @xyArrayRefs; $i++)
    {
      $svg .= $self->CreateDot(0, 0, $barWidth, $xyArrayRefs[$i]->[3], $i);
    }
  }
  $svg .= <<"  EOF";
<style type="text/css"><![CDATA[
.nx
{
  text-anchor: middle;
  font-size: 8;
}
.ny
{
  text-anchor: end;
  font-size: 8;
}
.g
{
  stroke: #000000;
  fill: none;
  stroke-width: 0.5;
  stroke-dasharray:4 4;
}
]]></style>
</defs>
<g id="grid" transform="translate($cornerDistance, $vertTranslate)">
  EOF

  ### make x- and y axes
  $svg .= "<path d=\"M0,0H-5 0 V 5 " . (-1 * $gridHeight) . " h -5 10 -5 V 0H" . $gridWidth . " V 5 -5 0 H 0\" style=\"fill: none; stroke: #000000;\"/>\n";

  ### print numbers on y axis and horizontal gridlines
  ### First calculate the width between the gridlines in y-units, not in pixels
  my $deltaYUnits = $self->NaturalRound ($yGridDistance * ($maxY - $minY) / $gridHeight);
  ### Adjust $minX and $maxX so the gridlines and numbers startand end in a whole and nice number.
  $minY = int ($minY / $deltaYUnits - 0.999999999999) * $deltaYUnits;
  $maxY = int ($maxY / $deltaYUnits + 0.999999999999) * $deltaYUnits;
  ### Calculate the number of pixels each units stands for.
  my $yPixelsPerUnit = ($gridHeight / ($maxY - $minY));
  my $deltaYPixels = $deltaYUnits * $yPixelsPerUnit;
  ### Calculate the amount of gridlines and therefore the amount of numbers on the y-axis
  my $yNumberOfNumbers = int ($gridHeight / $deltaYPixels) + 1;
  ### Draw the numbers and the gridlines
  for (my $i = 0; $i < $yNumberOfNumbers; $i++)
  {
    my $YValue = sprintf ("%1.2f", (-1 * $i * $deltaYPixels)) + 0;
    ### numbers
    $svg .= "<text x=\"-5\" y=\"" . ($YValue + 2) . "\" class=\"ny\">" . ($minY + $i * $deltaYUnits) . "</text>\n";
    ### gridline
    if ($i != 0)
    {
      $svg .= "<line x1=\"0\" y1=\"$YValue\" x2=\"$gridWidth\" y2=\"$YValue\" class=\"g\"/>\n";
    }
  }

  ### print numbers on x axis and vertical gridlines
  my $deltaXUnits = $self->NaturalRound ($xGridDistance * ($maxX - $minX) / $gridWidth);
  my $xPixelsPerUnit = ($gridWidth / ($maxX - $minX));
  my $deltaXPixels = $deltaXUnits * $xPixelsPerUnit;
  my $xNumberOfNumbers = int ($gridWidth / $deltaXPixels) + 1;
  for (my $i = 0; $i < $xNumberOfNumbers; $i++)
  {
    my $XValue = sprintf ("%1.2f", ($i * $deltaXPixels)) + 0;
    ### numbers
    $svg .= "<text x=\"" . $XValue . "\" y=\"10\" class=\"nx\">" . ($minX + $i * $deltaXUnits) . "</text>\n";
    ### gridline
    if ($i != 0)
    {
      $svg .= "<line x1=\"$XValue\" y1=\"0\" x2=\"$XValue\" y2=\"" . (-1 * $gridHeight) . "\" class=\"g\"/>\n";
    }
  }

  ### print measurepoints (dots) (data) (coordinates)
  ### Spline
  if ($graphType eq 'spline')
  {
    for (my $i = 0; $i < @xyArrayRefs; $i++)
    {
      my $dots;
      for (my $dotNumber = 0; $dotNumber < @{$xyArrayRefs[$i]->[0]}; $dotNumber++)
      {
        my $dotX = $horiUnitDistance * ($xyArrayRefs[$i]->[0]->[$dotNumber] - $minX);
        my $dotY = sprintf ("%1.2f", -1 * $yPixelsPerUnit * ($xyArrayRefs[$i]->[1]->[$dotNumber] - $minY)) + 0;
        $dots .= "<use xlink:href=\"#g$i\" transform=\"translate($dotX, $dotY)\"/>\n";
        if ($dotNumber == 0)
        {
          $svg .= "<path d=\"M$dotX $dotY";
        }
        else
        {
          $svg .= " L$dotX $dotY";
        }
      }
      $svg .= "\" style=\"fill: none; stroke: " . $xyArrayRefs[$i]->[3] . "; stroke-width:2\"/>\n$dots";
    }
  }
  ### Vertical Bars
  elsif ($graphType eq 'verticalbars')
  {
    for (my $dotNumber = 0; $dotNumber < @{$xyArrayRefs[0]->[0]}; $dotNumber++)
    {
      ### The longest bars must be drawn first, so that the shorter bars are drwan on top of the longer.
      ### So we sort $i (the number of the graph) to the length of the bar for each point.
      foreach my $i (sort {$xyArrayRefs[$b]->[1]->[$dotNumber] <=> $xyArrayRefs[$a]->[1]->[$dotNumber]} (0 .. $#xyArrayRefs))
      {
        my $lineX = $horiUnitDistance * ($xyArrayRefs[$i]->[0]->[$dotNumber] - $minX);
        my $lineY1 = 0;
        if (($minY < 0) && ($maxY > 0))
        {
          $lineY1 = $yPixelsPerUnit * $minY;
        }
        elsif ($maxY < 0)
        {
          $lineY1 = -1 * 1;
        }
        my $lineY2 = sprintf ("%1.2f", -1 * $yPixelsPerUnit * ($xyArrayRefs[$i]->[1]->[$dotNumber] - $minY)) + 0;
        $svg .= "<line x1=\"$lineX\" y1=\"$lineY1\" x2=\"$lineX\" y2=\"$lineY2\" style=\"stroke:" . $xyArrayRefs[$i]->[3] . ";stroke-width:$barWidth;\"/>\n";
      }
    }
  }

  ### print Title, Labels and Legend
  ### Title
  if ($$options{'title'})
  {
    my $titleStyle = 'font-size:24;';
    if ($$options{'titlestyle'})
    {
      $titleStyle = $self->XMLEscape($$options{'titlestyle'});
    }
    $svg .= "<text x=\"" . ($gridWidth / 2) . "\" y=\"" . (-1 * $gridHeight - 20) . "\" style=\"text-anchor:middle;$titleStyle\">" . $self->XMLEscape($$options{'title'}) . "</text>\n";
  }
  ### x-axis label
  if ($$options{'xlabel'})
  {
    my $xLabelStyle = 'font-size:16;';
    if ($$options{'xlabelstyle'})
    {
      $xLabelStyle = $self->XMLEscape($$options{'xlabelstyle'});
    }
    $svg .= "<text x=\"" . ($gridWidth / 2) . "\" y=\"40\" style=\"text-anchor:middle;$xLabelStyle\">" . $self->XMLEscape($$options{'xlabel'}) . "</text>\n";
  }
  ### y-axis label
  if ($$options{'ylabel'})
  {
    my $yLabelStyle = 'font-size:16;';
    if ($$options{'ylabelstyle'})
    {
      $yLabelStyle = $self->XMLEscape($$options{'ylabelstyle'});
    }
    $svg .= "<text x=\"" . ($gridHeight / 2) . "\" y=\"-20\" style=\"text-anchor:middle;$yLabelStyle\" transform=\"rotate(-90)\">" . $self->XMLEscape($$options{'ylabel'}) . "</text>\n";
  }
  ### Legend
  my $legendOffset = ($cornerDistance + $gridWidth + 10) . ", $cornerDistance";
  if ($$options{'legendoffset'})
  {
    $legendOffset = $self->XMLEscape($$options{'legendoffset'});
  }
  $svg .= "</g>\n<g id=\"legend\" transform=\"translate($legendOffset)\">\n";
  for (my $i = 0; $i < @xyArrayRefs; $i++)
  {
    if ($xyArrayRefs[$i]->[2])
    {
      my $y = 12 * $i;
      if ($graphType eq 'spline')
      {
        ### The line
        $svg .= "<line x1=\"0\" y1=\"$y\" x2=\"16\" y2=\"$y\" style=\"stroke-width:2;stroke:" . $xyArrayRefs[$i]->[3] . "\"/>\n";
        ### The dot
        $svg .= $self->CreateDot(8, $y, 3, $xyArrayRefs[$i]->[3], $i);
      }
      ### The text
      $svg .= "<text x=\"20\" y=\"" . ($y + 4) . "\" style=\"font-size:12;fill:" . $xyArrayRefs[$i]->[3] . "\">" . $xyArrayRefs[$i]->[2] . "</text>\n";
    }
  }
  $svg .= "</g>\n</svg>\n";
  return $svg;
}

### CreateDot is a subroutine that creates the svg code for different
### kinds of dots used in the spline graph type: circles, squares, triangles and more.
sub CreateDot($$$$$)
{
  my $self = shift;
  my $x = shift;
  my $y = shift;
  my $r = shift;
  my $color = shift;
  $color = $self->DarkenHexRGB($color);
  my $dotNumber = shift;
  my $d = 2 * $r;
  my $negr = -1 * $r;
  my $svg;
  ### Circle
  if ($dotNumber == 0)
  {
    $svg = "<circle id=\"g$dotNumber\" cx=\"$x\" cy=\"$y\" r=\"$r\" style=\"fill: $color; stroke: $color;\"/>\n";
  }
  ### Stars
  else
  {
    $svg .= "<path id=\"g$dotNumber\" d=\"";
    for (my $i = 1; $i <= (2*$dotNumber+2); $i++)
    {
      my $radius = ($i % 2) ? $r*1.5 : $r/2;
      my $pi = atan2(1,1) * 4;
      my $alpha = $i * ($pi / ($dotNumber + 1));
      my $xi = $x + $radius * cos($alpha);
      my $yi = $y + $radius * sin($alpha);
      $svg .= ($i == 1) ? "M" : "L";
      $svg .= sprintf (" %1.3f ", $xi) . (sprintf (" %1.3f ", $yi) + 0);
    }
    $svg .=  "z\" style=\"fill: $color; stroke: $color;\"/>\n";
  }
  return $svg;
}

### NaturalRound is a subroutine that rounds a number to 1, 2, 5 or 10 times its order
### So 110.34 becomes 100
### 3.1234 becomes 2
### 40 becomes 50

sub NaturalRound($)
{
  my $self = shift;
  my $numberToRound = shift;
  my $rounded;
  my $order = int (log ($numberToRound) / log (10));
  my $remainder = $numberToRound / 10**$order;
  if ($remainder < 1.4)
  {
    $rounded = 10**$order;
  }
  elsif ($remainder < 3.2)
  {
    $rounded = 2 * 10**$order;
  }
  elsif ($remainder < 7.1)
  {
    $rounded = 5 * 10**$order;
  }
  else
  {
    $rounded = 10 * 10**$order;
  }
}

### DarkenHexRGB is a subroutine that makes a rgb color value darker

sub DarkenHexRGB($)
{
  my $self = shift;
  my $hexString = shift;
  my $darkHexString;
  if ($hexString =~ m/^\#/)
  {
    $darkHexString = '#';
  }
  if ($hexString =~ m/^\#?[0-9a-f]{6}$/i)
  {
    while ($hexString =~ m/([0-9a-f][0-9a-f])/ig)
    {
      $darkHexString .= sprintf "%02lx", int(hex($1)/2);
    }
    return $darkHexString;
  }
  else
  {
    return $hexString;
  }
}

sub NegateHexadecimalRGB($)
{
  my $self = shift;
  my $hexString = shift;
  my $negHexString;
  if ($hexString =~ m/^\#/)
  {
    $negHexString = '#';
  }
  while ($hexString =~ m/([0-9a-f]{2})/ig)
  {
    $negHexString .= sprintf "%02lx", (255 - hex($1));
  }
  return $negHexString;
}

### XMLEscape is a subroutine that converts special XML characters to their xml encoding character.

sub XMLEscape($)
{
  my $self = shift;
  my $string = shift;
  unless (defined ($string))
  {
    $string = '';
  }
  $string =~ s/\&/&amp;/g;
  $string =~ s/>/&gt;/g;
  $string =~ s/</&lt;/g;
  $string =~ s/\"/&quot;/g;
  $string =~ s/\'/&apos;/g;
  #$string =~ s/([\x00-\x1f])/sprintf('&#x%02X;', ord($1))/ge;
  $string =~ s/([\x{80}-\x{ffff}])/sprintf('&#x%04X;', ord($1))/ge;
  return $string;
}

1;

__END__

=head1 NAME

  SVGGraph - Perl extension for creating SVG Graphs / Diagrams / Charts / Plots.

=head1 SYNOPSIS

  use SVGGraph;

  my @a = (1, 2, 3, 4);
  my @b = (3, 4, 3.5, 6.33);

  print "Content-type: image/svg-xml\n\n";
  my $SVGGraph = new SVGGraph;
  print SVGGraph->CreateGraph(
                        {'title' => 'Financial Results Q1 2002'},
                        [\@a, \@b, 'Staplers', 'red']
                      );

=head1 DESCRIPTION

  This module converts sets of arrays with coordinates into
  graphs, much like GNUplot would. It creates the graphs in the
  SVG (Scalable Vector Graphics) format. It has two styles,
  verticalbars and spline. It is designed to be light-weight.

  If your internet browser cannot display SVG, try downloading
  a plugin at adobe.com.

=head1 EXAMPLES

  For examples see: http://pearlshed.nl/svggraph/1.png
  and http://pearlshed.nl/svggraph/2.png

  Long code example:
  #!/usr/bin/perl -w -I.

  use strict;
  use SVGGraph;

  ### Array with x-values
  my @a = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20);
  ### Arrays with y-values
  my @b = (-5, 2, 1, 5, 8, 8, 9, 5, 4, 10, 2, 1, 5, 8, 8, 9, 5, 4, 10, 5);
  my @c = (6, -4, 2, 1, 5, 8, 8, 9, 5, 4, 10, 2, 1, 5, 8, 8, 9, 5, 4, 10);
  my @d = (1, 2, 3, 4, 9, 8, 7, 6, 5, 12, 30, 23, 12, 17, 13, 23, 12, 10, 20, 11);
  my @e = (3, 1, 2, -3, -4, -9, -8, -7, 6, 5, 12, 30, 23, 12, 17, 13, 23, 12, 10, 20);

  ### Initialise
  my $SVGGraph = new SVGGraph;
  ### Print the elusive content-type so the browser knows what mime type to expect
  print "Content-type: image/svg-xml\n\n";
  ### Print the graph
  print $SVGGraph->CreateGraph(	{
            'graphtype' => 'verticalbars', ### verticalbars or spline
            'imageheight' => 300, ### The total height of the whole svg image
            'barwidth' => 8, ### Width of the bar or dot in pixels
            'horiunitdistance' => 20, ### This is the distance in pixels between 1 x-unit
            'title' => 'Financial Results Q1 2002',
            'titlestyle' => 'font-size:24;fill:#FF0000;',
            'xlabel' => 'Week',
            'xlabelstyle' => 'font-size:16;fill:darkblue',
            'ylabel' => 'Revenue (x1000 USD)',
            'ylabelstyle' => 'font-size:16;fill:brown',
            'legendoffset' => '10, 10' ### In pixels from top left corner
          },
          [\@a, \@b, 'Bananas', '#FF0000'],
          [\@a, \@c, 'Apples', '#006699'],
          [\@a, \@d, 'Strawberries', '#FF9933'],
          [\@a, \@e, 'Melons', 'green']
        );

=head1 AUTHOR

  Teun van Eijsden, teun@chello.nl

=head1 SEE ALSO

  http://perldoc.com/
  For SVG styling: http://www.w3.org/TR/SVG/styling.html

=cut
