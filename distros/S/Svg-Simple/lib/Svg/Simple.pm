#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I/home/phil/perl/cpan/Math-Intersection-Circle-Line/lib/
#-----------------------------------------------------------------------------------------------------------------------
# Write SVG using Perl syntax.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2017-2020
#-----------------------------------------------------------------------------------------------------------------------
# podDocumentation
package Svg::Simple;
require v5.34;
our $VERSION = 20260909;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Math::Intersection::Circle::Line;
use utf8;

makeDieConfess;

#D1 Constructors                                                                                                        # Construct and print a new L<svg> object.

sub new(%)                                                                                                              # Create a new L<svg> object.
 {my (%options) = @_;                                                                                                   # Svg options
  genHash(__PACKAGE__,
    code     => [],                                                                                                     # Svg code generated
    mX       => 0,                                                                                                      # Maximum X coordinate encountered
    mY       => 0,                                                                                                      # Maximum Y coordinate encountered
    defaults => $options{defaults},                                                                                     # Default attributes to be applied to each statement
    grid     => $options{grid},                                                                                         # Grid of specified size requested if non zero
    z        => {0=>1},                                                                                                 # Values of z encountered: the elements will be drawn in passes in Z order.
  );
 }

sub gridLines($$$$)                                                                                                     # Draw a grid.
 {my ($svg, $x, $y, $g) = @_;                                                                                           # Svg, maximum X, maximum Y, grid square size
  @_ == 4 or confess "Four parameters";
  my @s;
  my $X = int($x / $g); my $Y = int($y / $g);                                                                           # Steps in X and Y
  my $f =     $g /  4;                                                                                                  # Font size
  my $w =     $f / 16;                                                                                                  # Line width
  my @w = (opacity=>0.2, font_size=>$f, stroke_width=>$w, stroke=>"black",                                              # Font for grid
           text_anchor => "start", dominant_baseline => "hanging");
  my @f = (@w, opacity=>1, fill=>'black');

  for my $i(0..$X)                                                                                                      # X lines
   {my $c = $i*$g;
    $svg->line(x1=>$c, x2=>$c, y1=>0, y2=>$y, @w);
    $svg->text(@f, x => $c, y => 0, cdata => $i) unless $i == $X;
   }

  for my $i(0..$Y)                                                                                                      # Y lines
   {my $c = $i*$g;
    $svg->line(y1=>$c, y2=>$c, x1=>0, x2=>$x, @w);
    $svg->text(@f, x => 0, y => $c, cdata => $i) unless $i == $Y;
   }

  for my $i(1..$X)                                                                                                      # X lines
   {my $x = $i*$g;
    for my $j(1..$Y)                                                                                                    # Y lines
     {my $y = $j*$g;
      if ($i % 10 == 0 or $j % 10 == 0)
       {$svg->text(@f, x => $x, y => $y, cdata => "$i.$j");
       }
     }
   }
 }

sub print($%)                                                                                                           # Print resulting L<svg> string.
 {my ($svg, %options) = @_;                                                                                             # Svg, svg options
  my $X = $options{x}      // 0;                                                                                        # Maximum width
  my $Y = $options{y}      // 0;                                                                                        # Maximum height
  my $W = $options{width}  // $svg->mX;                                                                                 # Maximum width
  my $H = $options{height} // $svg->mY;                                                                                 # Maximum height
  my $I = $options{inline};                                                                                             # Do not headers
  my $F = $options{svg};                                                                                                # Optional file to write to
  my $g = $svg->grid ? $svg->gridLines($W, $H, $svg->grid) : '';                                                        # Draw a grid if requested
  my $e = q(</svg>);

  my @C = $svg->code->@*;                                                                                               # Elements
  my @c;                                                                                                                # Elements reordered by z index
  for my $Z(sort {$a <=> $b} keys $svg->z->%*)                                                                          # Reorder elements by z from low to high
   {for my $C(@C)                                                                                                       # Scan svg elements
     {my ($c, $z) = @$C;                                                                                                # Element, z order
      if ($z == $Z)                                                                                                     # Matching z order
       {push @c, $c;
       }
     }
   }

  my $s = join "\n", @c;

  my $S = <<"END";
<svg height="100%" viewBox="$X $Y $W $H" width="100%" background-color="none" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
$g
$s
$e
END

  my $x = <<"END";                                                                                                      # XML header
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
END

  my $t = $I ? $S : $x.$S;                                                                                              # Write without headers for inline usage
  writeFile($F, $t) if $F;                                                                                              # Write to file
  $t
 }

our $AUTOLOAD;                                                                                                          # The method to be autoloaded appears here

sub AUTOLOAD($%)                                                                                                        #P L<svg> methods.
 {my ($svg, %options) = @_;                                                                                             # Svg object, options
  my @s;

  my %o;
     %o = ($svg->defaults->%*) if $svg->defaults;                                                                       # Add any default values
     %o = (%o, %options);                                                                                               # Add supplied options

  for my $k(sort keys %o)                                                                                               # Process each option
   {my $v = $o{$k};
    my $K = $k =~ s(_) (-)r;                                                                                            # Underscore _ in option names becomes hyphen -
    next if $k =~ m(\Acdata\Z)i;                                                                                        # Skip text keyword  as the text will be placed inline
    next if $k =~ m(\Asub\Z)i;                                                                                          # Skip sub keyword as the subroutine will be called and its content placed inside this tag
    push @s, qq($K="$v");
   }

  my $n = $AUTOLOAD =~ s(\A.*::) ()r;                                                                                   # Name of element

  eval                                                                                                                  # Maximum extent of the Svg
   {my $X = $svg->mX;
    my $Y = $svg->mY;
    my $w = $options{stroke} ? $options{stroke_width} // $options{"stroke-width"} // 1 : 0;

    my sub option($) {$options{$_[0]} // 0}                                                                             # Get an option or default to zero if not present.  This avoids the problem of validating the SVG parameters which the browser will do more effectively.

    if ($n =~ m(\Acircle\Z)i)
     {$X = max $X, $w + option("cx")+option("r");
      $Y = max $Y, $w + option("cy")+option("r");
     }
    if ($n =~ m(\Aline\Z)i)                                                                                             # Lines
     {$X = max $X, $w + option("$_") for qw(x1 x2);
      $Y = max $Y, $w + option("$_") for qw(y1 y2);
     }
    if ($n =~ m(\Arect\Z)i)                                                                                             # Rectangles
     {$X = max $X, $w + option("x")+option("width");
      $Y = max $Y, $w + option("y")+option("height");
     }
    if ($n =~ m(\Atext\Z)i)
     {$X = max $X, option("x") + $w * length(option("cdata"));
      $Y = max $Y, option("y");
     }
    $svg->mX = max $svg->mX, $X;
    $svg->mY = max $svg->mY, $Y;
   };
  if ($@)                                                                                                               # Failed to evaluate the preceding code
   {say STDERR $@;
    exit;
   }

  my $z = 0;                                                                                                            # Default z order
  if (defined(my $Z = $options{z}))                                                                                     # Override Z order
   {$svg->z->{$z = $Z}++;
   }

  my $p = join " ", @s;                                                                                                 # Options
  if (defined(my $t = $options{cdata}))
   {push $svg->code->@*, ["<$n $p>$t</$n>", $z]                                                                         # Internal text
   }
  elsif (defined(my $s = $options{sub}))                                                                                # Group or other command that brackets statements
   {push $svg->code->@*, ["<$n $p>", $z];                                                                               # Opening xml
    &$s($svg);                                                                                                          # Internal xml
    push $svg->code->@*, ["</$n>",   $z]                                                                                # Closing xml
   }
  else
   {push $svg->code->@*, ["<$n $p/>",       $z]                                                                         # No internal text
   }
  $svg
 }

#D1 Utility functions                                                                                                   # Extra features to make using Svg easier

sub arcPath($$$$$$$$)                                                                                                   # Arc through three points along the circumference of a circle from the first point through the middle point to the last point
 {my ($svg, $N, $x1, $y1, $x2, $y2, $x3, $y3) = @_;                                                                     # Svg, number of points on path, start x, start y, middle x, middle y, end x, end y
  @_ == 8 or confess "Eight parameters";

  Math::Intersection::Circle::Line::circumCircle                                                                        # Draw a circle clockwise through the three points
   {my ($cx, $cy) = @_;
    my $r = Math::Intersection::Circle::Line::vectorLength($x1, $y1, $cx, $cy);                                         # Radius of circle

    my sub inter($$)                                                                                                    # Point on the circumference of a circle where the line drawn through the specified point and the center of the circle intersect the circle closest to the specified point
     {my ($x, $y) = @_;                                                                                                 # Options

      Math::Intersection::Circle::Line::intersectionCircleLine
       {my ($x1, $y1, $x2, $y2) = @_;                                                                                   # Intersection points
        my $l1 = Math::Intersection::Circle::Line::vectorLength($x,$y, $x1,$y1);                                        # One point on the circumference
        my $l2 = Math::Intersection::Circle::Line::vectorLength($x,$y, $x2,$y2);                                        # The opposite point
        ($x1, $y1) = ($x2, $y2) if $l2 < $l1;                                                                           # The point on the circumference closest to the point being mapped
        ($x1, $y1)                                                                                                      # Return closest intersection point
       } $cx, $cy, $r, $cx, $cy, $x, $y;
     }

    my @p;                                                                                                              # Path
    for my $i(0..$N)                                                                                                    # Step along first line segment mapping it on to the nearest part of the circle
     {my $dx = ($x2 - $x1) * $i / $N;
      my $dy = ($y2 - $y1) * $i / $N;
      push @p, join " ", "L", inter $x1+$dx, $y1+$dy;
     }
    for my $i(0..$N)                                                                                                    # Step along second line segment mapping it on to the nearest part of the circle
     {my $dx = ($x3 - $x2) * $i / $N;
      my $dy = ($y3 - $y2) * $i / $N;
      push @p, join " ", "L", inter $x2+$dx, $y2+$dy;
     }

    my $p = join " ", @p;                                                                                               # Construct the SVG path string running along the circle circumference from the first point, through the middle point to the last point
    $p =~ s(\AL) (M)r                                                                                                   # Move to the start of the curve
   } $x1, $y1, $x2, $y2, $x3, $y3;
 }

#D0
#-----------------------------------------------------------------------------------------------------------------------
# Export - eeee
#-----------------------------------------------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

# containingFolder

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw();
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation

=pod

=encoding utf-8

=for html <p><a href="https://github.com/philiprbrenan/SvgSimple"><img src="https://github.com/philiprbrenan/SvgSimple/workflows/Test/badge.svg"></a>

=head1 Name

Svg::Simple - Write L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> using Perl syntax.

=head1 Synopsis

Write L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> using Perl syntax as in:

  my $s = Svg::Simple::new();

  $s->g(id=>"g1", sub=>sub
   {$s->text(x=>10, y=>10,
      cdata             =>"Hello World",
      text_anchor       =>"middle",
      alignment_baseline=>"middle",
      font_size         => 3.6,
      font_family       =>"Arial",
      fill              =>"black");

    $s->circle(cx=>10, cy=>10, r=>8, stroke=>"blue", fill=>"transparent", opacity=>0.5);
   });
  say STDERR $s->print;

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SvgSimple/main/lib/Svg/svg/test.svg">

A B<-> in an L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics>
keyword can be replaced with B<_> to reduce line noise.

A B<cdata=>"text"> keyword value pair will placed the text inside an open and closing pair of tags.

A B<sub=\>sub{}> keyword value pair will create an open tag, call the supplied sub and then create a close tag to
bracket svg statements together,

A B<-> in an L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics>
keyword can be replaced with B<_> to reduce line noise.

The L<print> method automatically creates an
L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> to wrap around
all the L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics>
statements specified.  The image so created will fill all of the available
space in the browser if the image is shown by itself, else it will fill all of
the available space in the parent tag containing the
L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> statements if the
L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> is inlined in
L<html> .

This package automatically tracks the dimensions of the objects specified in
the L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> statements
and creates a viewport wide enough and high enough to display them fully in
whatever space the browser allocates to the
L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> image.

If you wish to set these dimensions yourself, call the L<print> method with
overriding values as in:

  say STDERR $s->print(x=>-100, y=>-100, width=>2000, height=>1000);

=head1 Description

Write L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> using Perl syntax.

Version 20240308.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.

=head1 Constructors

Construct and print a new L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> object.

=head2 new (%options)

Create a new L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> object.

     Parameter  Description
  1  %options   Svg options

B<Example:>


  if (1)

   {my $s = Svg::Simple::new();  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $s->text(x=>10, y=>10,
      cdata             =>"Hello World",
      text_anchor       =>"middle",
      alignment_baseline=>"middle",
      font_size         => 3.6,
      font_family       =>"Arial",
      fill              =>"black");

    $s->circle(cx=>10, cy=>10, r=>8, stroke=>"blue", fill=>"transparent", opacity=>0.5);

    my $t = $s->print(svg=>q(svg/new));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok($t =~ m(circle));
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SvgSimple/main/lib/Svg/svg/new.svg">


=head2 gridLines   ($svg, $x, $y, $g)

Draw a grid.

     Parameter  Description
  1  $svg       Svg
  2  $x         Maximum X
  3  $y         Maximum Y
  4  $g         Grid square size

B<Example:>


  if (1)
   {my $s = Svg::Simple::new(grid=>10);
    $s->rect(x=>10, y=>10, width=>40, height=>30, stroke=>"blue", fill=>'transparent');
    my $t = $s->print(svg=>q(svg/grid));
    is_deeply(scalar(split /line/, $t), 32);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SvgSimple/main/lib/Svg/svg/grid.svg">


=head2 print   ($svg, %options)

Print resulting L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> string.

     Parameter  Description
  1  $svg       Svg
  2  %options   Svg options

B<Example:>


  if (1)
   {my $s = Svg::Simple::new();

    my @d = (width=>8, height=>8, stroke=>"blue", fill=>"transparent");           # Default values
    $s->rect(x=>1, y=>1, z=>1, @d, stroke=>"blue");                               # Defined earlier  but drawn above because of z order
    $s->rect(x=>4, y=>4, z=>0, @d, stroke=>"red");

    my $t = $s->print(svg=>q(svg/rect));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply(scalar(split /rect/, $t), 3);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SvgSimple/main/lib/Svg/svg/rect.svg">


=head1 Utility functions

Extra features to make using Svg easier

=head2 arcPath ($svg, $N, $x1, $y1, $x2, $y2, $x3, $y3)

Arc through three points along the circumference of a circle from the first point through the middle point to the last point

     Parameter  Description
  1  $svg       Svg
  2  $N         Number of points on path
  3  $x1        Start x
  4  $y1        Start y
  5  $x2        Middle x
  6  $y2        Middle y
  7  $x3        End x
  8  $y3        End y

B<Example:>


  if (1)
   {my $d = {width=>8, height=>8, stroke_width=>0.1, stroke=>"blue", fill=>"transparent"};           # Default values
    my $s = Svg::Simple::new(defaults=>$d);

    my $p = $s->arcPath(64, 1,1, 3,2, 1, 3);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    $s->path(d=>"M 1 1  $p  Z");
    $s->print(svg=>q(svg/arc1), width=>10, height=>10);
   }


=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SvgSimple/main/lib/Svg/svg/arc1.svg">



=head1 Private Methods

=head2 AUTOLOAD($svg, %options)

L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> methods.

     Parameter  Description
  1  $svg       Svg object
  2  %options   Options


=head1 Index


1 L<arcPath|/arcPath> - Arc through three points along the circumference of a circle from the first point through the middle point to the last point

2 L<AUTOLOAD|/AUTOLOAD> - L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> methods.

3 L<gridLines|/gridLines> - Draw a grid.

4 L<new|/new> - Create a new L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> object.

5 L<print|/print> - Print resulting L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> string.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Svg::Simple

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://prb.appaapps.com|http://prb.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2023 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



#D0 Tests                                                                                                               # Tests and examples
goto finish if caller;                                                                                                  # Skip testing if we are being called as a module
clearFolder(q(svg), 99);                                                                                                # Clear the output svg folder
eval "use Test::More qw(no_plan)";
eval "Test::More->builder->output('/dev/null')" if -e q(/home/phil/);
eval {goto latest};

#Svg https://raw.githubusercontent.com/philiprbrenan/SvgSimple/main/lib/Svg/

if (1)                                                                                                                  #Tnew
 {my $s = Svg::Simple::new();

  $s->text(x=>10, y=>10,
    cdata             =>"Hello World",
    text_anchor       =>"middle",
    alignment_baseline=>"middle",
    font_size         => 3.6,
    font_family       =>"Arial",
    fill              =>"black");

  $s->circle(cx=>10, cy=>10, r=>8, stroke=>"blue", fill=>"transparent", opacity=>0.5);
  my $t = $s->print(svg=>q(svg/new));
  ok($t =~ m(circle));
 }

if (1)                                                                                                                  #TgridLines
 {my $s = Svg::Simple::new(grid=>10);
  $s->rect(x=>10, y=>10, width=>40, height=>30, stroke=>"blue", fill=>'transparent');
  my $t = $s->print(svg=>q(svg/grid));
  is_deeply(scalar(split /line/, $t), 32);
 }

if (1)                                                                                                                  #Tprint
 {my $s = Svg::Simple::new();

  my @d = (width=>8, height=>8, stroke=>"blue", fill=>"transparent");                                                   # Default values
  $s->rect(x=>1, y=>1, z=>1, @d, stroke=>"blue");                                                                       # Defined earlier  but drawn above because of z order
  $s->rect(x=>4, y=>4, z=>0, @d, stroke=>"red");
  my $t = $s->print(svg=>q(svg/rect));
  is_deeply(scalar(split /rect/, $t), 3);
 }

if (1)                                                                                                                  #TarcPath
 {my $d = {width=>8, height=>8, stroke_width=>0.1, stroke=>"blue", fill=>"transparent"};                                # Default values
  my $s = Svg::Simple::new(defaults=>$d);
  my $p = $s->arcPath(64, 1,1, 3,2, 1, 3);
  $s->path(d=>"M 1 1  $p  Z");
  $s->print(svg=>q(svg/arc1), width=>10, height=>10);
 }

if (1)
 {my $s = Svg::Simple::new();

  $s->g(id=>"group1", sub=>sub
   {$s->text(x=>10, y=>10,
      cdata             =>"Hello World",
      text_anchor       =>"middle",
      alignment_baseline=>"middle",
      font_size         => 3.6,
      font_family       =>"Arial",
      fill              =>"black");

    $s->circle(cx=>10, cy=>10, r=>8, stroke=>"blue", fill=>"transparent", opacity=>0.5);
 });

  &is_deeply($s->print, <<'END');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
<svg height="100%" viewBox="0 0 19 19" width="100%" background-color="none" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">

<g id="group1">
<text alignment-baseline="middle" fill="black" font-family="Arial" font-size="3.6" text-anchor="middle" x="10" y="10">Hello World</text>
<circle cx="10" cy="10" fill="transparent" opacity="0.5" r="8" stroke="blue"/>
</g>
</svg>
END
 }

done_testing();
finish: 1;
