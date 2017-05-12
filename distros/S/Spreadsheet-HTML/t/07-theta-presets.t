#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 40;

use Spreadsheet::HTML;

my $data = [
    [qw(header1 header2 header3 header4 )],
    [qw(foo1 bar1 baz1 qux1)],
    [qw(foo2 bar2 baz2 qux2)],
    [qw(foo3 bar3 baz3 qux3)],
    [qw(foo4 bar4 baz4 qux4)],
];
my $table = Spreadsheet::HTML->new( data => $data );

my $expected = '<table><tr><th>header1</th><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td></tr><tr><th>header2</th><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td></tr><tr><th>header3</th><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td></tr><tr><th>header4</th><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td></tr></table>';
is $table->west, $expected,                         "west: correct HTML from method call";
is Spreadsheet::HTML::west( $data ), $expected,     "west: correct HTML from procedural call (array ref arg)";
is Spreadsheet::HTML::west( @$data ), $expected,    "west: correct HTML from procedural call (list arg)";

is Spreadsheet::HTML::west( data => $data, matrix => 1 ),
    '<table><tr><td>header1</td><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td></tr><tr><td>header2</td><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td></tr><tr><td>header3</td><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td></tr><tr><td>header4</td><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td></tr></table>',
   "west: correct HTML when matrix is specified";

is Spreadsheet::HTML::west( data => $data, headless => 1 ),
    '<table><tr><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td></tr><tr><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td></tr><tr><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td></tr><tr><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td></tr></table>',
   "west: correct HTML from when headless is specified";

$expected = '<table><tr><th>header4</th><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td></tr><tr><th>header3</th><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td></tr><tr><th>header2</th><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td></tr><tr><th>header1</th><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td></tr></table>';
is $table->west( flip => 1 ), $expected,                        "flip west: correct HTML from method call";
is Spreadsheet::HTML::west( $data, flip => 1 ), $expected,      "flip west: correct HTML from procedural call (array ref arg)";
is Spreadsheet::HTML::west( @$data, flip => 1 ), $expected,     "flip west: correct HTML from procedural call (list arg)";

is Spreadsheet::HTML::west( data => $data, flip => 1, matrix => 1 ),
    '<table><tr><td>header4</td><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td></tr><tr><td>header3</td><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td></tr><tr><td>header2</td><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td></tr><tr><td>header1</td><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td></tr></table>',
   "flip west: correct HTML when matrix is specified";

is Spreadsheet::HTML::west( data => $data, flip => 1, headless => 1 ),
    '<table><tr><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td></tr><tr><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td></tr><tr><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td></tr><tr><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td></tr></table>',
   "flip west: correct HTML from when headless is specified";



$expected = '<table><tr><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td><th>header1</th></tr><tr><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td><th>header2</th></tr><tr><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td><th>header3</th></tr><tr><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td><th>header4</th></tr></table>';
is $table->east, $expected,                         "east: correct HTML from method call";
is Spreadsheet::HTML::east( $data ), $expected,     "east: correct HTML from procedural call (array ref arg)";
is Spreadsheet::HTML::east( @$data ), $expected,    "east: correct HTML from procedural call (list arg)";

is Spreadsheet::HTML::east( data => $data, matrix => 1 ),
    '<table><tr><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td><td>header1</td></tr><tr><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td><td>header2</td></tr><tr><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td><td>header3</td></tr><tr><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td><td>header4</td></tr></table>',
   "east: correct HTML when matrix is specified";

is Spreadsheet::HTML::east( data => $data, headless => 1 ),
    '<table><tr><td>foo4</td><td>foo3</td><td>foo2</td><td>foo1</td></tr><tr><td>bar4</td><td>bar3</td><td>bar2</td><td>bar1</td></tr><tr><td>baz4</td><td>baz3</td><td>baz2</td><td>baz1</td></tr><tr><td>qux4</td><td>qux3</td><td>qux2</td><td>qux1</td></tr></table>',
   "east: correct HTML when headless is specified";


$expected = '<table><tr><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td><th>header4</th></tr><tr><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td><th>header3</th></tr><tr><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td><th>header2</th></tr><tr><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td><th>header1</th></tr></table>';
is $table->east( flip => 1 ), $expected,                        "flip east: correct HTML from method call";
is Spreadsheet::HTML::east( $data, flip => 1 ), $expected,      "flip east: correct HTML from procedural call (array ref arg)";
is Spreadsheet::HTML::east( @$data, flip => 1 ), $expected,     "flip east: correct HTML from procedural call (list arg)";

is Spreadsheet::HTML::east( data => $data, flip => 1, matrix => 1 ),
    '<table><tr><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td><td>header4</td></tr><tr><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td><td>header3</td></tr><tr><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td><td>header2</td></tr><tr><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td><td>header1</td></tr></table>',
   "flip east: correct HTML when matrix is specified";

is Spreadsheet::HTML::east( data => $data, flip => 1, headless => 1 ),
    '<table><tr><td>qux4</td><td>qux3</td><td>qux2</td><td>qux1</td></tr><tr><td>baz4</td><td>baz3</td><td>baz2</td><td>baz1</td></tr><tr><td>bar4</td><td>bar3</td><td>bar2</td><td>bar1</td></tr><tr><td>foo4</td><td>foo3</td><td>foo2</td><td>foo1</td></tr></table>',
   "flip east: correct HTML when headless is specified";


$expected = '<table><tr><td>foo1</td><td>bar1</td><td>baz1</td><td>qux1</td></tr><tr><td>foo2</td><td>bar2</td><td>baz2</td><td>qux2</td></tr><tr><td>foo3</td><td>bar3</td><td>baz3</td><td>qux3</td></tr><tr><td>foo4</td><td>bar4</td><td>baz4</td><td>qux4</td></tr><tr><th>header1</th><th>header2</th><th>header3</th><th>header4</th></tr></table>';
is $table->south, $expected,                            "south: correct HTML from method call";
is Spreadsheet::HTML::south( $data ), $expected,        "south: correct HTML from procedural call (array ref arg)";
is Spreadsheet::HTML::south( @$data ), $expected,       "south: correct HTML from procedural call (list arg)";

is Spreadsheet::HTML::south( data => $data, matrix => 1 ),
    '<table><tr><td>foo1</td><td>bar1</td><td>baz1</td><td>qux1</td></tr><tr><td>foo2</td><td>bar2</td><td>baz2</td><td>qux2</td></tr><tr><td>foo3</td><td>bar3</td><td>baz3</td><td>qux3</td></tr><tr><td>foo4</td><td>bar4</td><td>baz4</td><td>qux4</td></tr><tr><td>header1</td><td>header2</td><td>header3</td><td>header4</td></tr></table>',
   "south: correct HTML when matrix is specified"
;

is Spreadsheet::HTML::south( data => $data, headless => 1 ),
    '<table><tr><td>foo4</td><td>bar4</td><td>baz4</td><td>qux4</td></tr><tr><td>foo3</td><td>bar3</td><td>baz3</td><td>qux3</td></tr><tr><td>foo2</td><td>bar2</td><td>baz2</td><td>qux2</td></tr><tr><td>foo1</td><td>bar1</td><td>baz1</td><td>qux1</td></tr></table>',
   "south: loses pin when headless is specified"
;


$expected = '<table><tr><td>qux1</td><td>baz1</td><td>bar1</td><td>foo1</td></tr><tr><td>qux2</td><td>baz2</td><td>bar2</td><td>foo2</td></tr><tr><td>qux3</td><td>baz3</td><td>bar3</td><td>foo3</td></tr><tr><td>qux4</td><td>baz4</td><td>bar4</td><td>foo4</td></tr><tr><th>header4</th><th>header3</th><th>header2</th><th>header1</th></tr></table>';
is $table->south( flip => 1 ), $expected,                           "flip south: correct HTML from method call";
is Spreadsheet::HTML::south( $data, flip => 1 ), $expected,         "flip south: correct HTML from procedural call (array ref arg)";
is Spreadsheet::HTML::south( @$data, flip => 1 ), $expected,        "flip south: correct HTML from procedural call (list arg)";

is Spreadsheet::HTML::south( data => $data, flip => 1, matrix => 1 ),
    '<table><tr><td>qux1</td><td>baz1</td><td>bar1</td><td>foo1</td></tr><tr><td>qux2</td><td>baz2</td><td>bar2</td><td>foo2</td></tr><tr><td>qux3</td><td>baz3</td><td>bar3</td><td>foo3</td></tr><tr><td>qux4</td><td>baz4</td><td>bar4</td><td>foo4</td></tr><tr><td>header4</td><td>header3</td><td>header2</td><td>header1</td></tr></table>',
   "flip south: correct HTML when matrix is specified"
;

is Spreadsheet::HTML::south( data => $data, flip => 1, headless => 1 ),
    '<table><tr><td>qux4</td><td>baz4</td><td>bar4</td><td>foo4</td></tr><tr><td>qux3</td><td>baz3</td><td>bar3</td><td>foo3</td></tr><tr><td>qux2</td><td>baz2</td><td>bar2</td><td>foo2</td></tr><tr><td>qux1</td><td>baz1</td><td>bar1</td><td>foo1</td></tr></table>',
   "flip south: correct HTML when headless is specified"
;


$expected = '<table><tr><th>header1</th><th>header2</th><th>header3</th><th>header4</th></tr><tr><td>foo1</td><td>bar1</td><td>baz1</td><td>qux1</td></tr><tr><td>foo2</td><td>bar2</td><td>baz2</td><td>qux2</td></tr><tr><td>foo3</td><td>bar3</td><td>baz3</td><td>qux3</td></tr><tr><td>foo4</td><td>bar4</td><td>baz4</td><td>qux4</td></tr></table>';
is $table->north, $expected,                            "north: correct HTML from method call";
is Spreadsheet::HTML::north( $data ), $expected,        "north: correct HTML from procedural call (array ref arg)";
is Spreadsheet::HTML::north( @$data ), $expected,       "north: correct HTML from procedural call (list arg)";

is Spreadsheet::HTML::north( data => $data, matrix => 1 ),
    '<table><tr><td>header1</td><td>header2</td><td>header3</td><td>header4</td></tr><tr><td>foo1</td><td>bar1</td><td>baz1</td><td>qux1</td></tr><tr><td>foo2</td><td>bar2</td><td>baz2</td><td>qux2</td></tr><tr><td>foo3</td><td>bar3</td><td>baz3</td><td>qux3</td></tr><tr><td>foo4</td><td>bar4</td><td>baz4</td><td>qux4</td></tr></table>',
   "north: correct HTML when matrix is specified"
;

is Spreadsheet::HTML::north( data => $data, headless => 1 ),
    '<table><tr><td>foo1</td><td>bar1</td><td>baz1</td><td>qux1</td></tr><tr><td>foo2</td><td>bar2</td><td>baz2</td><td>qux2</td></tr><tr><td>foo3</td><td>bar3</td><td>baz3</td><td>qux3</td></tr><tr><td>foo4</td><td>bar4</td><td>baz4</td><td>qux4</td></tr></table>',
   "north: correct HTML when headless is specified"
;


$expected = '<table><tr><th>header4</th><th>header3</th><th>header2</th><th>header1</th></tr><tr><td>qux1</td><td>baz1</td><td>bar1</td><td>foo1</td></tr><tr><td>qux2</td><td>baz2</td><td>bar2</td><td>foo2</td></tr><tr><td>qux3</td><td>baz3</td><td>bar3</td><td>foo3</td></tr><tr><td>qux4</td><td>baz4</td><td>bar4</td><td>foo4</td></tr></table>';
is $table->north( flip => 1 ), $expected,                           "flip north: correct HTML from method call";
is Spreadsheet::HTML::north( $data, flip => 1 ), $expected,         "flip north: correct HTML from procedural call (array ref arg)";
is Spreadsheet::HTML::north( @$data, flip => 1 ), $expected,        "flip north: correct HTML from procedural call (list arg)";

is Spreadsheet::HTML::north( data => $data, flip => 1, matrix => 1 ),
    '<table><tr><td>header4</td><td>header3</td><td>header2</td><td>header1</td></tr><tr><td>qux1</td><td>baz1</td><td>bar1</td><td>foo1</td></tr><tr><td>qux2</td><td>baz2</td><td>bar2</td><td>foo2</td></tr><tr><td>qux3</td><td>baz3</td><td>bar3</td><td>foo3</td></tr><tr><td>qux4</td><td>baz4</td><td>bar4</td><td>foo4</td></tr></table>',
   "flip north: correct HTML when matrix is specified"
;

is Spreadsheet::HTML::north( data => $data, flip => 1, headless => 1 ),
    '<table><tr><td>qux1</td><td>baz1</td><td>bar1</td><td>foo1</td></tr><tr><td>qux2</td><td>baz2</td><td>bar2</td><td>foo2</td></tr><tr><td>qux3</td><td>baz3</td><td>bar3</td><td>foo3</td></tr><tr><td>qux4</td><td>baz4</td><td>bar4</td><td>foo4</td></tr></table>',
   "flip north: correct HTML when headless is specified"
;

