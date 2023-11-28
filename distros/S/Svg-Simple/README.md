<div>
    <p><a href="https://github.com/philiprbrenan/SvgSimple"><img src="https://github.com/philiprbrenan/SvgSimple/workflows/Test/badge.svg"></a>
</div>

# Name

Svg::Simple - Write [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) using Perl syntax.

# Synopsis

Write [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) using Perl syntax as in:

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

<div>
    <img src="https://raw.githubusercontent.com/philiprbrenan/SvgSimple/main/lib/Svg/svg/test.svg">
</div>

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

    say STDERR $s->print(width=>2000, height=>1000);

If you wish to inline the generated [html](https://en.wikipedia.org/wiki/HTML)
you should remove the first two lines of the generated code using a regular
expression to remove the superfluous [xml](https://en.wikipedia.org/wiki/XML)
headers.

# Description

Write [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) using Perl syntax.

Version 20231118.

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

# Private Methods

## AUTOLOAD($svg, %options)

[Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) methods.

       Parameter  Description
    1  $svg       Svg object
    2  %options   Options

# Index

1 [AUTOLOAD](#autoload) - [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) methods.

2 [gridLines](#gridlines) - Draw a grid.

3 [new](#new) - Create a new [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) object.

4 [print](#print) - Print resulting [Scalar Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) string.

# Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via **cpan**:

    sudo cpan install Svg::Simple

# Author

[philiprbrenan@gmail.com](mailto:philiprbrenan@gmail.com)

[http://www.appaapps.com](http://www.appaapps.com)

# Copyright

Copyright (c) 2016-2023 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.


For documentation see: [CPAN](https://metacpan.org/pod/Svg::Simple)