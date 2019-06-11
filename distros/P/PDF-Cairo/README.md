# PDF-Cairo

Perl API for PDF generation using Cairo, FreeType, and Pango.

## Overview

[PDF::Cairo](https://metacpan.org/release/PDF-Cairo) is loosely based on the API of PDF::API2::Lite, but uses
Cairo, Font::FreeType, and (optionally) Pango to provide better
support for modern TrueType and OpenType fonts. Compatibility methods
are provided to more easily convert existing scripts.

[Cairo](https://www.cairographics.org) is a cross-platform vector
graphics library that is capable of generating high-quality PDF output
(as well as PNG, PS, and SVG). Unfortunately, the Cairo Perl module
is not well documented or easy to use, especially in combination with
Font::FreeType and/or Pango. PDF::Cairo adapts the simple and
straightforward interface of PDF::API2::Lite, hiding the quirks of
the underlying C libraries. Methods that do not return an explicit
value return $self so they can be chained.

Many scripts can be ported from PDF::API2::Lite just by updating
the module name.

## Modules

* `PDF::Cairo` -- create PDF files containing text, line art, and images.

* `PDF::Cairo::Layout` -- create advanced text layouts using Pango.

* `PDF::Cairo::Font` -- use any installed font supported by FreeType.

* `PDF::Cairo::Box` -- manipulate rectangles for easy page layout.

* `PDF::Cairo::Util` -- small library of useful functions

## Usage

```
use PDF::Cairo qw(cm);
$pdf = PDF::Cairo->new(
    file => "output.pdf",
    paper => "a4",
    landscape => 1,
);
$font = $pdf->loadfont('Times-Bold');
$pdf->move(cm(2), cm(4));
$pdf->fillcolor('red');
$pdf->setfont($font, 32);
$pdf->print("Hamburgefontsiv");
$image = $pdf->loadimage("logo.png");
$pdf->showimage($image, cm(5), cm(5),
    scale => 0.5, rotate => 45);
$pdf->write;
```
