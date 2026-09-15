<div>
    <p><a href="https://github.com/philiprbrenan/SvgSimple"><img src="https://github.com/philiprbrenan/SvgSimple/workflows/Test/badge.svg"></a>
</div>

# Name

Svg::Simple - Write [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) using Perl syntax.

# Synopsis

Write [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) using Perl syntax as in:

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

<div>
    <img src="https://raw.githubusercontent.com/philiprbrenan/SvgSimple/main/lib/Svg/svg/test.svg">
</div>

A **-** in an [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics)
keyword can be replaced with **\_** to reduce line noise.

A **cdata=**"text"> keyword value pair will placed the text inside an open and closing pair of tags.

A **sub=\\**sub{}> keyword value pair will create an open tag, call the supplied sub and then create a close tag to
bracket svg statements together,

A **-** in an [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics)
keyword can be replaced with **\_** to reduce line noise.

The [print](https://metacpan.org/pod/print) method automatically creates an
[Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) to wrap around
all the [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics)
statements specified.  The image so created will fill all of the available
space in the browser if the image is shown by itself, else it will fill all of
the available space in the parent tag containing the
[Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) statements if the
[Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) is inlined in
[HTML](https://en.wikipedia.org/wiki/HTML) .

This package automatically tracks the dimensions of the objects specified in
the [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) statements
and creates a viewport wide enough and high enough to display them fully in
whatever space the browser allocates to the
[Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) image.

If you wish to set these dimensions yourself, call the [print](https://metacpan.org/pod/print) method with
overriding values as in:

    say STDERR $s->print(x=>-100, y=>-100, width=>2000, height=>1000);

# Description

Write [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) using Perl syntax.

Version 20240308.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see [Index](#index).

# Constructors

Construct and print a new [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) object.

## new (%options)

Create a new [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) object.

       Parameter  Description
    1  %options   Svg options

**Example:**

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

<div>
    <img src="https://raw.githubusercontent.com/philiprbrenan/SvgSimple/main/lib/Svg/svg/new.svg">
</div>

## gridLines   ($svg, $x, $y, $g)

Draw a grid.

       Parameter  Description
    1  $svg       Svg
    2  $x         Maximum X
    3  $y         Maximum Y
    4  $g         Grid square size

**Example:**

    if (1)
     {my $s = Svg::Simple::new(grid=>10);
      $s->rect(x=>10, y=>10, width=>40, height=>30, stroke=>"blue", fill=>'transparent');
      my $t = $s->print(svg=>q(svg/grid));
      is_deeply(scalar(split /line/, $t), 32);
     }

<div>
    <img src="https://raw.githubusercontent.com/philiprbrenan/SvgSimple/main/lib/Svg/svg/grid.svg">
</div>

## print   ($svg, %options)

Print resulting [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) string.

       Parameter  Description
    1  $svg       Svg
    2  %options   Svg options

**Example:**

    if (1)
     {my $s = Svg::Simple::new();

      my @d = (width=>8, height=>8, stroke=>"blue", fill=>"transparent");           # Default values
      $s->rect(x=>1, y=>1, z=>1, @d, stroke=>"blue");                               # Defined earlier  but drawn above because of z order
      $s->rect(x=>4, y=>4, z=>0, @d, stroke=>"red");

      my $t = $s->print(svg=>q(svg/rect));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      is_deeply(scalar(split /rect/, $t), 3);
     }

<div>
    <img src="https://raw.githubusercontent.com/philiprbrenan/SvgSimple/main/lib/Svg/svg/rect.svg">
</div>

# Utility functions

Extra features to make using Svg easier

## arcPath ($svg, $N, $x1, $y1, $x2, $y2, $x3, $y3)

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

**Example:**

    if (1)
     {my $d = {width=>8, height=>8, stroke_width=>0.1, stroke=>"blue", fill=>"transparent"};           # Default values
      my $s = Svg::Simple::new(defaults=>$d);

      my $p = $s->arcPath(64, 1,1, 3,2, 1, 3);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

      $s->path(d=>"M 1 1  $p  Z");
      $s->print(svg=>q(svg/arc1), width=>10, height=>10);
     }

<div>
    <img src="https://raw.githubusercontent.com/philiprbrenan/SvgSimple/main/lib/Svg/svg/arc1.svg">
</div>

# Private Methods

## AUTOLOAD($svg, %options)

[Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) methods.

       Parameter  Description
    1  $svg       Svg object
    2  %options   Options

# Index

1 [arcPath](#arcpath) - Arc through three points along the circumference of a circle from the first point through the middle point to the last point

2 [AUTOLOAD](#autoload) - [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) methods.

3 [gridLines](#gridlines) - Draw a grid.

4 [new](#new) - Create a new [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) object.

5 [print](#print) - Print resulting [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) string.

# Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via **cpan**:

    sudo cpan install Svg::Simple

# Author

[philiprbrenan@gmail.com](mailto:philiprbrenan@gmail.com)

[http://prb.appaapps.com](http://prb.appaapps.com)

# Copyright

Copyright (c) 2016-2023 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.


For documentation see: [CPAN](https://metacpan.org/pod/Svg::Simple)