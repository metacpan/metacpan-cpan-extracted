# PDF::Cairo Examples

Scripts that test or demonstrate various features of the modules that
make up PDF::Cairo. Many of them were converted from PDF::API2::Lite.

* box-slice.pl

The slice() and grid() methods in PDF::Cairo::Box have a variety
of options to distribute the leftover space between columns/rows.

* calendar.pl

Generate a [progressive/gapless
calendar](http://wondermark.com/free-calendar-2019/), using the
`DateTime` module to handle all of the calculations and localization.

* frontpage.pl

Create a terrible cheesy mockup of a 'newspaper' front page, to test a
realistic combination of the module's features. This has been useful
for exposing bugs and identifying missing API features.

* hexgrid.pl

Create a
[Traveller](https://en.wikipedia.org/wiki/Traveller_(role-playing_game))-style
hex grid. Uses PDF::Cairo::Box to simplify the code for adding data
to each grid cell.

* images.pl

Quick test of the loadimage()/showimage() methods.

* inkle-draft.pl

Drafting grid for inkle weaving.

* isopad.pl

Isometric drawing paper.

* kanjigrid.pl

Kanji/kana practice sheets. TODO: add grayed-out sample characters in
an appropriate font to trace over.

* layout.pl

Quick test of [Pango](https://www.pango.org) layout support in
PDF::Cairo::Layout.

* polygon.pl

Test of the polygon() method.

* svg.pl

Test of using Image::CairoSVG to render SVG files.

* tategaki.pl

Japanese vertical-text report-writing paper.

* textpath.pl

Test of extracting font outlines with textpath().

* yoko-ruled.pl

Clone of a popular notebook paper style.
