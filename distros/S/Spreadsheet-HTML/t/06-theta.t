#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 62;

use Spreadsheet::HTML;

my $data = [
    [qw(header1 header2 header3 header4 )],
    [qw(foo1 bar1 baz1 qux1)],
    [qw(foo2 bar2 baz2 qux2)],
    [qw(foo3 bar3 baz3 qux3)],
    [qw(foo4 bar4 baz4 qux4)],
];
my $table = Spreadsheet::HTML->new( data => $data );


# THETA 0
my $expected = '<table><tr><th>header1</th><th>header2</th><th>header3</th><th>header4</th></tr><tr><td>foo1</td><td>bar1</td><td>baz1</td><td>qux1</td></tr><tr><td>foo2</td><td>bar2</td><td>baz2</td><td>qux2</td></tr><tr><td>foo3</td><td>bar3</td><td>baz3</td><td>qux3</td></tr><tr><td>foo4</td><td>bar4</td><td>baz4</td><td>qux4</td></tr></table>';
is $table->generate( theta => 0 ), $expected,                       "theta => 0: correct HTML from method call";
is Spreadsheet::HTML::generate( $data, theta => 0 ), $expected,     "theta => 0: correct HTML from procedural call (array ref arg)";
is Spreadsheet::HTML::generate( @$data, theta => 0 ), $expected,    "theta => 0: correct HTML from procedural call (list arg)";

is Spreadsheet::HTML::generate( data => $data, theta => 0, pinhead => 1 ),
    $expected,
   "theta => 0: pinhead does not impact";

is Spreadsheet::HTML::generate( data => $data, theta => 0, matrix => 1 ),
    '<table><tr><td>header1</td><td>header2</td><td>header3</td><td>header4</td></tr><tr><td>foo1</td><td>bar1</td><td>baz1</td><td>qux1</td></tr><tr><td>foo2</td><td>bar2</td><td>baz2</td><td>qux2</td></tr><tr><td>foo3</td><td>bar3</td><td>baz3</td><td>qux3</td></tr><tr><td>foo4</td><td>bar4</td><td>baz4</td><td>qux4</td></tr></table>',
   "theta => 0: correct HTML when matrix is specified";

is Spreadsheet::HTML::generate( data => $data, theta => 0, headless => 1 ),
    '<table><tr><td>foo1</td><td>bar1</td><td>baz1</td><td>qux1</td></tr><tr><td>foo2</td><td>bar2</td><td>baz2</td><td>qux2</td></tr><tr><td>foo3</td><td>bar3</td><td>baz3</td><td>qux3</td></tr><tr><td>foo4</td><td>bar4</td><td>baz4</td><td>qux4</td></tr></table>',
   "theta => 0: correct HTML from when headless is specified";

is Spreadsheet::HTML::generate( data => $data, theta => 0, flip => 1 ),
    '<table><tr><th>header4</th><th>header3</th><th>header2</th><th>header1</th></tr><tr><td>qux1</td><td>baz1</td><td>bar1</td><td>foo1</td></tr><tr><td>qux2</td><td>baz2</td><td>bar2</td><td>foo2</td></tr><tr><td>qux3</td><td>baz3</td><td>bar3</td><td>foo3</td></tr><tr><td>qux4</td><td>baz4</td><td>bar4</td><td>foo4</td></tr></table>',
   "theta => 0: correct HTML when flip is specified";

is Spreadsheet::HTML::generate( data => $data, theta => 0, headless => 1, flip => 1 ),
    '<table><tr><td>qux1</td><td>baz1</td><td>bar1</td><td>foo1</td></tr><tr><td>qux2</td><td>baz2</td><td>bar2</td><td>foo2</td></tr><tr><td>qux3</td><td>baz3</td><td>bar3</td><td>foo3</td></tr><tr><td>qux4</td><td>baz4</td><td>bar4</td><td>foo4</td></tr></table>',
   "theta => 0: correct HTML when headless and flip are both specified";


# THETA 90
$expected = '<table><tr><td>foo4</td><td>foo3</td><td>foo2</td><td>foo1</td><th>header1</th></tr><tr><td>bar4</td><td>bar3</td><td>bar2</td><td>bar1</td><th>header2</th></tr><tr><td>baz4</td><td>baz3</td><td>baz2</td><td>baz1</td><th>header3</th></tr><tr><td>qux4</td><td>qux3</td><td>qux2</td><td>qux1</td><th>header4</th></tr></table>';
is $table->generate( theta => 90 ), $expected,                       "theta => 90: correct HTML from method call";
is Spreadsheet::HTML::generate( $data, theta => 90 ), $expected,     "theta => 90: correct HTML from procedural call (array ref arg)";
is Spreadsheet::HTML::generate( @$data, theta => 90 ), $expected,    "theta => 90: correct HTML from procedural call (list arg)";

is Spreadsheet::HTML::generate( data => $data, theta => 90, pinhead => 1 ),
    '<table><tr><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td><th>header1</th></tr><tr><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td><th>header2</th></tr><tr><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td><th>header3</th></tr><tr><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td><th>header4</th></tr></table>',
   "theta => 90: pinhead impacts rotation";

is Spreadsheet::HTML::generate( data => $data, theta => 90, matrix => 1 ),
    '<table><tr><td>foo4</td><td>foo3</td><td>foo2</td><td>foo1</td><td>header1</td></tr><tr><td>bar4</td><td>bar3</td><td>bar2</td><td>bar1</td><td>header2</td></tr><tr><td>baz4</td><td>baz3</td><td>baz2</td><td>baz1</td><td>header3</td></tr><tr><td>qux4</td><td>qux3</td><td>qux2</td><td>qux1</td><td>header4</td></tr></table>',
   "theta => 90: correct HTML when matrix is specified";

is Spreadsheet::HTML::generate( data => $data, theta => 90, headless => 1 ),
    '<table><tr><td>foo4</td><td>foo3</td><td>foo2</td><td>foo1</td></tr><tr><td>bar4</td><td>bar3</td><td>bar2</td><td>bar1</td></tr><tr><td>baz4</td><td>baz3</td><td>baz2</td><td>baz1</td></tr><tr><td>qux4</td><td>qux3</td><td>qux2</td><td>qux1</td></tr></table>',
   "theta => 90: correct HTML from when headless is specified";

is Spreadsheet::HTML::generate( data => $data, theta => 90, flip => 1 ),
    '<table><tr><td>qux4</td><td>qux3</td><td>qux2</td><td>qux1</td><th>header4</th></tr><tr><td>baz4</td><td>baz3</td><td>baz2</td><td>baz1</td><th>header3</th></tr><tr><td>bar4</td><td>bar3</td><td>bar2</td><td>bar1</td><th>header2</th></tr><tr><td>foo4</td><td>foo3</td><td>foo2</td><td>foo1</td><th>header1</th></tr></table>',
   "theta => 90: correct HTML when flip is specified";

is Spreadsheet::HTML::generate( data => $data, theta => 90, headless => 1, flip => 1 ),
    '<table><tr><td>qux4</td><td>qux3</td><td>qux2</td><td>qux1</td></tr><tr><td>baz4</td><td>baz3</td><td>baz2</td><td>baz1</td></tr><tr><td>bar4</td><td>bar3</td><td>bar2</td><td>bar1</td></tr><tr><td>foo4</td><td>foo3</td><td>foo2</td><td>foo1</td></tr></table>',
   "theta => 90: correct HTML when headless and flip are both specified";


# THETA -90
$expected = '<table><tr><td>qux4</td><td>qux3</td><td>qux2</td><td>qux1</td><th>header4</th></tr><tr><td>baz4</td><td>baz3</td><td>baz2</td><td>baz1</td><th>header3</th></tr><tr><td>bar4</td><td>bar3</td><td>bar2</td><td>bar1</td><th>header2</th></tr><tr><td>foo4</td><td>foo3</td><td>foo2</td><td>foo1</td><th>header1</th></tr></table>';
is $table->generate( theta => -90 ), $expected,                       "theta => -90: correct HTML from method call";
is Spreadsheet::HTML::generate( $data, theta => -90 ), $expected,     "theta => -90: correct HTML from procedural call (array ref arg)";
is Spreadsheet::HTML::generate( @$data, theta => -90 ), $expected,    "theta => -90: correct HTML from procedural call (list arg)";

is Spreadsheet::HTML::generate( data => $data, theta => -90, pinhead => 1 ),
    '<table><tr><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td><th>header4</th></tr><tr><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td><th>header3</th></tr><tr><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td><th>header2</th></tr><tr><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td><th>header1</th></tr></table>',
   "theta => -90: pinhead impacts rotation";

is Spreadsheet::HTML::generate( data => $data, theta => -90, matrix => 1 ),
    '<table><tr><td>qux4</td><td>qux3</td><td>qux2</td><td>qux1</td><td>header4</td></tr><tr><td>baz4</td><td>baz3</td><td>baz2</td><td>baz1</td><td>header3</td></tr><tr><td>bar4</td><td>bar3</td><td>bar2</td><td>bar1</td><td>header2</td></tr><tr><td>foo4</td><td>foo3</td><td>foo2</td><td>foo1</td><td>header1</td></tr></table>',
   "theta => -90: correct HTML when matrix is specified";

is Spreadsheet::HTML::generate( data => $data, theta => -90, headless => 1 ),
    '<table><tr><td>qux4</td><td>qux3</td><td>qux2</td><td>qux1</td></tr><tr><td>baz4</td><td>baz3</td><td>baz2</td><td>baz1</td></tr><tr><td>bar4</td><td>bar3</td><td>bar2</td><td>bar1</td></tr><tr><td>foo4</td><td>foo3</td><td>foo2</td><td>foo1</td></tr></table>',
   "theta => -90: correct HTML from when headless is specified";

is Spreadsheet::HTML::generate( data => $data, theta => -90, flip => 1 ),
    '<table><tr><td>foo4</td><td>foo3</td><td>foo2</td><td>foo1</td><th>header1</th></tr><tr><td>bar4</td><td>bar3</td><td>bar2</td><td>bar1</td><th>header2</th></tr><tr><td>baz4</td><td>baz3</td><td>baz2</td><td>baz1</td><th>header3</th></tr><tr><td>qux4</td><td>qux3</td><td>qux2</td><td>qux1</td><th>header4</th></tr></table>',
   "theta => -90: correct HTML when flip is specified";

is Spreadsheet::HTML::generate( data => $data, theta => -90, headless => 1, flip => 1 ),
    '<table><tr><td>foo4</td><td>foo3</td><td>foo2</td><td>foo1</td></tr><tr><td>bar4</td><td>bar3</td><td>bar2</td><td>bar1</td></tr><tr><td>baz4</td><td>baz3</td><td>baz2</td><td>baz1</td></tr><tr><td>qux4</td><td>qux3</td><td>qux2</td><td>qux1</td></tr></table>',
   "theta => -90: correct HTML when headless and flip are both specified";


# THETA 180
$expected = '<table><tr><td>qux4</td><td>baz4</td><td>bar4</td><td>foo4</td></tr><tr><td>qux3</td><td>baz3</td><td>bar3</td><td>foo3</td></tr><tr><td>qux2</td><td>baz2</td><td>bar2</td><td>foo2</td></tr><tr><td>qux1</td><td>baz1</td><td>bar1</td><td>foo1</td></tr><tr><th>header4</th><th>header3</th><th>header2</th><th>header1</th></tr></table>';
is $table->generate( theta => 180 ), $expected,                       "theta => 180: correct HTML from method call";
is Spreadsheet::HTML::generate( $data, theta => 180 ), $expected,     "theta => 180: correct HTML from procedural call (array ref arg)";
is Spreadsheet::HTML::generate( @$data, theta => 180 ), $expected,    "theta => 180: correct HTML from procedural call (list arg)";

is Spreadsheet::HTML::generate( data => $data, theta => 180, pinhead => 1 ),
    '<table><tr><td>qux1</td><td>baz1</td><td>bar1</td><td>foo1</td></tr><tr><td>qux2</td><td>baz2</td><td>bar2</td><td>foo2</td></tr><tr><td>qux3</td><td>baz3</td><td>bar3</td><td>foo3</td></tr><tr><td>qux4</td><td>baz4</td><td>bar4</td><td>foo4</td></tr><tr><th>header4</th><th>header3</th><th>header2</th><th>header1</th></tr></table>',
   "theta => 180: pinhead impacts rotation";

is Spreadsheet::HTML::generate( data => $data, theta => 180, matrix => 1 ),
    '<table><tr><td>qux4</td><td>baz4</td><td>bar4</td><td>foo4</td></tr><tr><td>qux3</td><td>baz3</td><td>bar3</td><td>foo3</td></tr><tr><td>qux2</td><td>baz2</td><td>bar2</td><td>foo2</td></tr><tr><td>qux1</td><td>baz1</td><td>bar1</td><td>foo1</td></tr><tr><td>header4</td><td>header3</td><td>header2</td><td>header1</td></tr></table>',
   "theta => 180: correct HTML when matrix is specified";

is Spreadsheet::HTML::generate( data => $data, theta => 180, headless => 1 ),
    '<table><tr><td>qux4</td><td>baz4</td><td>bar4</td><td>foo4</td></tr><tr><td>qux3</td><td>baz3</td><td>bar3</td><td>foo3</td></tr><tr><td>qux2</td><td>baz2</td><td>bar2</td><td>foo2</td></tr><tr><td>qux1</td><td>baz1</td><td>bar1</td><td>foo1</td></tr></table>',
   "theta => 180: correct HTML from when headless is specified";

is Spreadsheet::HTML::generate( data => $data, theta => 180, flip => 1 ),
    '<table><tr><td>foo4</td><td>bar4</td><td>baz4</td><td>qux4</td></tr><tr><td>foo3</td><td>bar3</td><td>baz3</td><td>qux3</td></tr><tr><td>foo2</td><td>bar2</td><td>baz2</td><td>qux2</td></tr><tr><td>foo1</td><td>bar1</td><td>baz1</td><td>qux1</td></tr><tr><th>header1</th><th>header2</th><th>header3</th><th>header4</th></tr></table>',
   "theta => 180: correct HTML when flip is specified";

is Spreadsheet::HTML::generate( data => $data, theta => 180, headless => 1, flip => 1 ),
    '<table><tr><td>foo4</td><td>bar4</td><td>baz4</td><td>qux4</td></tr><tr><td>foo3</td><td>bar3</td><td>baz3</td><td>qux3</td></tr><tr><td>foo2</td><td>bar2</td><td>baz2</td><td>qux2</td></tr><tr><td>foo1</td><td>bar1</td><td>baz1</td><td>qux1</td></tr></table>',
   "theta => 180: correct HTML when headless and flip are both specified";


# THETA -180
$expected = '<table><tr><td>foo4</td><td>bar4</td><td>baz4</td><td>qux4</td></tr><tr><td>foo3</td><td>bar3</td><td>baz3</td><td>qux3</td></tr><tr><td>foo2</td><td>bar2</td><td>baz2</td><td>qux2</td></tr><tr><td>foo1</td><td>bar1</td><td>baz1</td><td>qux1</td></tr><tr><th>header1</th><th>header2</th><th>header3</th><th>header4</th></tr></table>';
is $table->generate( theta => -180 ), $expected,                       "theta => -180: correct HTML from method call";
is Spreadsheet::HTML::generate( $data, theta => -180 ), $expected,     "theta => -180: correct HTML from procedural call (array ref arg)";
is Spreadsheet::HTML::generate( @$data, theta => -180 ), $expected,    "theta => -180: correct HTML from procedural call (list arg)";

is Spreadsheet::HTML::generate( data => $data, theta => -180, pinhead => 1 ),
    '<table><tr><td>foo1</td><td>bar1</td><td>baz1</td><td>qux1</td></tr><tr><td>foo2</td><td>bar2</td><td>baz2</td><td>qux2</td></tr><tr><td>foo3</td><td>bar3</td><td>baz3</td><td>qux3</td></tr><tr><td>foo4</td><td>bar4</td><td>baz4</td><td>qux4</td></tr><tr><th>header1</th><th>header2</th><th>header3</th><th>header4</th></tr></table>',
   "theta => -180: pinhead impacts rotation";

is Spreadsheet::HTML::generate( data => $data, theta => -180, matrix => 1 ),
    '<table><tr><td>foo4</td><td>bar4</td><td>baz4</td><td>qux4</td></tr><tr><td>foo3</td><td>bar3</td><td>baz3</td><td>qux3</td></tr><tr><td>foo2</td><td>bar2</td><td>baz2</td><td>qux2</td></tr><tr><td>foo1</td><td>bar1</td><td>baz1</td><td>qux1</td></tr><tr><td>header1</td><td>header2</td><td>header3</td><td>header4</td></tr></table>',
   "theta => -180: correct HTML when matrix is specified";

is Spreadsheet::HTML::generate( data => $data, theta => -180, headless => 1 ),
    '<table><tr><td>foo4</td><td>bar4</td><td>baz4</td><td>qux4</td></tr><tr><td>foo3</td><td>bar3</td><td>baz3</td><td>qux3</td></tr><tr><td>foo2</td><td>bar2</td><td>baz2</td><td>qux2</td></tr><tr><td>foo1</td><td>bar1</td><td>baz1</td><td>qux1</td></tr></table>',
   "theta => -180: correct HTML from when headless is specified";

is Spreadsheet::HTML::generate( data => $data, theta => -180, flip => 1 ),
    '<table><tr><td>qux4</td><td>baz4</td><td>bar4</td><td>foo4</td></tr><tr><td>qux3</td><td>baz3</td><td>bar3</td><td>foo3</td></tr><tr><td>qux2</td><td>baz2</td><td>bar2</td><td>foo2</td></tr><tr><td>qux1</td><td>baz1</td><td>bar1</td><td>foo1</td></tr><tr><th>header4</th><th>header3</th><th>header2</th><th>header1</th></tr></table>',
   "theta => -180: correct HTML when flip is specified";

is Spreadsheet::HTML::generate( data => $data, theta => -180, headless => 1, flip => 1 ),
    '<table><tr><td>qux4</td><td>baz4</td><td>bar4</td><td>foo4</td></tr><tr><td>qux3</td><td>baz3</td><td>bar3</td><td>foo3</td></tr><tr><td>qux2</td><td>baz2</td><td>bar2</td><td>foo2</td></tr><tr><td>qux1</td><td>baz1</td><td>bar1</td><td>foo1</td></tr></table>',
   "theta => -180: correct HTML when headless and flip are both specified";


# THETA 270
$expected = '<table><tr><th>header4</th><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td></tr><tr><th>header3</th><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td></tr><tr><th>header2</th><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td></tr><tr><th>header1</th><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td></tr></table>';
is $table->generate( theta => 270 ), $expected,                       "theta => 270: correct HTML from method call";
is Spreadsheet::HTML::generate( $data, theta => 270 ), $expected,     "theta => 270: correct HTML from procedural call (array ref arg)";
is Spreadsheet::HTML::generate( @$data, theta => 270 ), $expected,    "theta => 270: correct HTML from procedural call (list arg)";

is Spreadsheet::HTML::generate( data => $data, theta => 270, pinhead => 1 ),
    $expected,
   "theta => 270: pinhead does not impact";

is Spreadsheet::HTML::generate( data => $data, theta => 270, matrix => 1 ),
    '<table><tr><td>header4</td><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td></tr><tr><td>header3</td><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td></tr><tr><td>header2</td><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td></tr><tr><td>header1</td><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td></tr></table>',
   "theta => 270: correct HTML when matrix is specified";

is Spreadsheet::HTML::generate( data => $data, theta => 270, headless => 1 ),
    '<table><tr><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td></tr><tr><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td></tr><tr><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td></tr><tr><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td></tr></table>',
   "theta => 270: correct HTML from when headless is specified";

is Spreadsheet::HTML::generate( data => $data, theta => 270, flip => 1 ),
    '<table><tr><th>header1</th><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td></tr><tr><th>header2</th><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td></tr><tr><th>header3</th><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td></tr><tr><th>header4</th><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td></tr></table>',
   "theta => 270: correct HTML when flip is specified";

is Spreadsheet::HTML::generate( data => $data, theta => 270, headless => 1, flip => 1 ),
    '<table><tr><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td></tr><tr><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td></tr><tr><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td></tr><tr><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td></tr></table>',
   "theta => 270: correct HTML when headless and flip are both specified";


# THETA -270 
$expected = '<table><tr><th>header1</th><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td></tr><tr><th>header2</th><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td></tr><tr><th>header3</th><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td></tr><tr><th>header4</th><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td></tr></table>';
is $table->generate( theta => -270 ), $expected,                       "theta => -270: correct HTML from method call";
is Spreadsheet::HTML::generate( $data, theta => -270 ), $expected,     "theta => -270: correct HTML from procedural call (array ref arg)";
is Spreadsheet::HTML::generate( @$data, theta => -270 ), $expected,    "theta => -270: correct HTML from procedural call (list arg)";

is Spreadsheet::HTML::generate( data => $data, theta => -270, pinhead => 1 ),
    $expected,
   "theta => -270: pinhead does not impact";

is Spreadsheet::HTML::generate( data => $data, theta => -270, matrix => 1 ),
    '<table><tr><td>header1</td><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td></tr><tr><td>header2</td><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td></tr><tr><td>header3</td><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td></tr><tr><td>header4</td><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td></tr></table>',
   "theta => -270: correct HTML when matrix is specified";

is Spreadsheet::HTML::generate( data => $data, theta => -270, headless => 1 ),
    '<table><tr><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td></tr><tr><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td></tr><tr><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td></tr><tr><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td></tr></table>',
   "theta => -270: correct HTML from when headless is specified";

is Spreadsheet::HTML::generate( data => $data, theta => -270, flip => 1 ),
    '<table><tr><th>header4</th><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td></tr><tr><th>header3</th><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td></tr><tr><th>header2</th><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td></tr><tr><th>header1</th><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td></tr></table>',
   "theta => -270: correct HTML when flip is specified";

is Spreadsheet::HTML::generate( data => $data, theta => -270, headless => 1, flip => 1 ),
    '<table><tr><td>qux1</td><td>qux2</td><td>qux3</td><td>qux4</td></tr><tr><td>baz1</td><td>baz2</td><td>baz3</td><td>baz4</td></tr><tr><td>bar1</td><td>bar2</td><td>bar3</td><td>bar4</td></tr><tr><td>foo1</td><td>foo2</td><td>foo3</td><td>foo4</td></tr></table>',
   "theta => -270: correct HTML when headless and flip are both specified";


# COMPLIMENTS
is  Spreadsheet::HTML::generate( data => $data, theta => 90 ),
    Spreadsheet::HTML::generate( data => $data, theta => -90, flip => 1 ),
    "(theta => 90 ) is same as ( theta => -90, flip => 1 )";

is  Spreadsheet::HTML::generate( data => $data, theta => -90 ),
    Spreadsheet::HTML::generate( data => $data, theta => 90, flip => 1 ),
    "(theta => -90 ) is same as ( theta => 90, flip => 1 )";

is  Spreadsheet::HTML::generate( data => $data, theta => 180 ),
    Spreadsheet::HTML::generate( data => $data, theta => -180, flip => 1 ),
    "(theta => 180 ) is same as ( theta => -180, flip => 1 )";

is  Spreadsheet::HTML::generate( data => $data, theta => -180 ),
    Spreadsheet::HTML::generate( data => $data, theta => 180, flip => 1 ),
    "(theta => -180 ) is same as ( theta => 180, flip => 1 )";

is  Spreadsheet::HTML::generate( data => $data, theta => 270 ),
    Spreadsheet::HTML::generate( data => $data, theta => -270, flip => 1 ),
    "(theta => 270 ) is same as ( theta => -270, flip => 1 )";

is  Spreadsheet::HTML::generate( data => $data, theta => -270 ),
    Spreadsheet::HTML::generate( data => $data, theta => 270, flip => 1 ),
    "(theta => -270 ) is same as ( theta => 270, flip => 1 )";

