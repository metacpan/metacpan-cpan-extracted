#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Write SVG using Perl syntax.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2017-2020
#-------------------------------------------------------------------------------
# podDocumentation
package Svg::Simple;
require v5.34;
our $VERSION = 20231118;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);

makeDieConfess;

#D1 Constructors                                                                # Construct and print a new L<svg> object.

sub new(%)                                                                      # Create a new L<svg> object.
 {my (%options) = @_;                                                           # Svg options
  genHash(__PACKAGE__,
    code     => [],                                                             # Svg code generated
    mX       => 0,                                                              # Maximum X coordinate encountered
    mY       => 0,                                                              # Maximum Y coordinate encountered
    defaults => $options{defaults},                                             # Default attributes to be applied to each statement
    grid     => $options{grid},                                                 # Grid of specified size requested if non zero
    z        => {0=>1},                                                         # Values of z encountered: the elements will be drawn in passes in Z order.
  );
 }

sub gridLines($$$$)                                                             # Draw a grid.
 {my ($svg, $x, $y, $g) = @_;                                                   # Svg, maximum X, maximum Y, grid square size
  my @s;
  my $X = int($x / $g); my $Y = int($y / $g);                                   # Steps in X and Y
  my $f =     $g /  4;                                                          # Font size
  my $w =     $f / 16;                                                          # Line width
  my @w = (opacity=>0.2, font_size=>$f, stroke_width=>$w, stroke=>"black",      # Font for grid
           text_anchor => "start", dominant_baseline => "hanging");
  my @f = (@w, opacity=>1, fill=>'black');

  for my $i(0..$X)                                                              # X lines
   {my $c = $i*$g;
    $svg->line(x1=>$c, x2=>$c, y1=>0, y2=>$y, @w);
    $svg->text(@f, x => $c, y => 0, cdata => $i) unless $i == $X;
   }

  for my $i(0..$Y)                                                              # Y lines
   {my $c = $i*$g;
    $svg->line(y1=>$c, y2=>$c, x1=>0, x2=>$x, @w);
    $svg->text(@f, x => 0, y => $c, cdata => $i) unless $i == $Y;
   }
 }

sub print($%)                                                                   # Print resulting L<svg> string.
 {my ($svg, %options) = @_;                                                     # Svg, svg options
  my $X = $options{width}  // $svg->mX;                                         # Maximum width
  my $Y = $options{height} // $svg->mY;                                         # Maximum height
  my $g = $svg->grid ? $svg->gridLines($X, $Y, $svg->grid) : '';                # Draw a grid if requested
  my $e = q(</svg>);

  my @C = $svg->code->@*;                                                       # Elements
  my @c;                                                                        # Elements reordered by z index
  for my $Z(sort {$a <=> $b} keys $svg->z->%*)                                  # Reorder elements by z from low to high
   {for my $C(@C)                                                               # Scan svg elements
     {my ($c, $z) = @$C;                                                        # Element, z order
      if ($z == $Z)                                                             # Matching z order
       {push @c, $c;
       }
     }
   }

  my $s = join "\n", @c;

  my $S = <<"END";
<svg height="100%" viewBox="0 0 $X $Y" width="100%" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
$g
$s
$e
END

  my $H = <<"END";
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
END

  my $t = $options{inline} ? $S : $H.$S;                                        # Write without headers for inline usage

  if (my $f = $options{svg})                                                    # Write to file
   {owf(fpe($f, q(svg)), $t)
   }
  $t
 }

our $AUTOLOAD;                                                                  # The method to be autoloaded appears here

sub AUTOLOAD($%)                                                                #P L<svg> methods.
 {my ($svg, %options) = @_;                                                     # Svg object, options
  my @s;

  my %o;
     %o = ($svg->defaults->%*) if $svg->defaults;                               # Add any default values
     %o = (%o, %options);                                                       # Add supplied options

  for my $k(sort keys %o)                                                       # Process each option
   {my $v = $o{$k};
    my $K = $k =~ s(_) (-)r;                                                    # Underscore _ in option names becomes hyphen -
    next if $k =~ m(\Acdata\Z)i;
    push @s, qq($K="$v");
   }

  my $n = $AUTOLOAD =~ s(\A.*::) ()r;                                           # Name of element

  eval                                                                          # Maximum extent of the Svg
   {my $X = $svg->mY;
    my $Y = $svg->mY;
    my $w = $options{stroke} ? $options{stroke_width} // $options{"stroke-width"} // 1 : 0;
    if ($n =~ m(\Acircle\Z)i)
     {$X = max $X, $w + $options{cx}+$options{r};
      $Y = max $Y, $w + $options{cy}+$options{r};
     }
    if ($n =~ m(\Aline\Z)i)
     {$X = max $X, $w + $options{$_} for qw(x1 x2);
      $Y = max $Y, $w + $options{$_} for qw(y1 y2);
     }
    if ($n =~ m(\Arect\Z)i)
     {$X = max $X, $w + $options{x}+$options{width};
      $Y = max $Y, $w + $options{y}+$options{height};
     }
    if ($n =~ m(\Atext\Z)i)
     {$X = max $X, $options{x} + $w * length($options{cdata});
      $Y = max $Y, $options{y};
     }
    $svg->mX = max $svg->mX, $X;
    $svg->mY = max $svg->mY, $Y;
   };

  my $z = 0;                                                                    # Default z order
  if (defined(my $Z = $options{z}))                                             # Override Z order
   {$svg->z->{$z = $Z}++;
   }

  my $p = join " ", @s;                                                         # Options
  if (defined(my $t = $options{cdata}))
   {push $svg->code->@*, ["<$n $p>$t</$n>", $z]                                 # Internal text
   }
  else
   {push $svg->code->@*, ["<$n $p/>",       $z]                                 # No internal text
   }
  $svg
 }

#D0
#-------------------------------------------------------------------------------
# Export - eeee
#-------------------------------------------------------------------------------

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

  $s->text(x=>10, y=>10,
    cdata             =>"Hello World",
    text_anchor       =>"middle",
    alignment_baseline=>"middle",
    font_size         => 3.6,
    font_family       =>"Arial",
    fill              =>"black");

  $s->circle(cx=>10, cy=>10, r=>8, stroke=>"blue", fill=>"transparent", opacity=>0.5);

  say STDERR $s->print;

=for html <img src="https://raw.githubusercontent.com/philiprbrenan/SvgSimple/main/lib/Svg/svg/test.svg">

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

  say STDERR $s->print(width=>2000, height=>1000);

If you wish to inline the generated L<html|https://en.wikipedia.org/wiki/HTML>
you should remove the first two lines of the generated code using a regular
expression to remove the superfluous L<xml|https://en.wikipedia.org/wiki/XML>
headers.

=head1 Description

Write L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> using Perl syntax.


Version 20231118.


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



=head1 Private Methods

=head2 AUTOLOAD($svg, %options)

L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> methods.

     Parameter  Description
  1  $svg       Svg object
  2  %options   Options


=head1 Index


1 L<AUTOLOAD|/AUTOLOAD> - L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> methods.

2 L<gridLines|/gridLines> - Draw a grid.

3 L<new|/new> - Create a new L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> object.

4 L<print|/print> - Print resulting L<Scalar Vector Graphics|https://en.wikipedia.org/wiki/Scalable_Vector_Graphics> string.

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Svg::Simple

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2023 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



#D0 Tests                                                                       # Tests and examples
goto finish if caller;                                                          # Skip testing if we are being called as a module
eval "use Test::More qw(no_plan)";
eval "Test::More->builder->output('/dev/null')" if -e q(/home/phil/);
eval {goto latest};

#Svg https://raw.githubusercontent.com/philiprbrenan/SvgSimple/main/lib/Svg/

if (1)                                                                          #Tnew
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

if (1)                                                                          #TgridLines
 {my $s = Svg::Simple::new(grid=>10);
  $s->rect(x=>10, y=>10, width=>40, height=>30, stroke=>"blue", fill=>'transparent');
  my $t = $s->print(svg=>q(svg/grid));
  is_deeply(scalar(split /line/, $t), 32);
 }

if (1)                                                                          #Tprint
 {my $s = Svg::Simple::new();

  my @d = (width=>8, height=>8, stroke=>"blue", fill=>"transparent");           # Default values
  $s->rect(x=>1, y=>1, z=>1, @d, stroke=>"blue");                               # Defined earlier  but drawn above because of z order
  $s->rect(x=>4, y=>4, z=>0, @d, stroke=>"red");
  my $t = $s->print(svg=>q(svg/rect));
  is_deeply(scalar(split /rect/, $t), 3);
 }

done_testing();
finish: 1;
