#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

eval "use JSON";
plan skip_all => "JSON required" if $@;
plan tests => 8;

use_ok 'Spreadsheet::HTML';

my %file = ( file => 't/data/simple.json' );

my $table = new_ok 'Spreadsheet::HTML', [ %file ];

is $table->generate,
    '<table><tr><th>header1</th><th>header2</th><th>header3</th></tr><tr><td>foo</td><td>bar</td><td>baz</td></tr><tr><td>one</td><td>two</td><td>three</td></tr><tr><td>1</td><td>2</td><td>3</td></tr></table>',
    "loaded simple JSON data via method"
;

is Spreadsheet::HTML::generate( %file ),
    '<table><tr><th>header1</th><th>header2</th><th>header3</th></tr><tr><td>foo</td><td>bar</td><td>baz</td></tr><tr><td>one</td><td>two</td><td>three</td></tr><tr><td>1</td><td>2</td><td>3</td></tr></table>',
    "loaded simple JSON data via procedure"
;

is $table->generate( data => 1 ),
    '<table><tr><th>header1</th><th>header2</th><th>header3</th></tr><tr><td>foo</td><td>bar</td><td>baz</td></tr><tr><td>one</td><td>two</td><td>three</td></tr><tr><td>1</td><td>2</td><td>3</td></tr></table>',
    "data param does not clobber loaded simple JSON data via method"
;

is Spreadsheet::HTML::generate( %file, data => 1 ),
    '<table><tr><th>header1</th><th>header2</th><th>header3</th></tr><tr><td>foo</td><td>bar</td><td>baz</td></tr><tr><td>one</td><td>two</td><td>three</td></tr><tr><td>1</td><td>2</td><td>3</td></tr></table>',
    "data param does not clobber loaded simple JSON data via procedure"
;

$table = Spreadsheet::HTML->new( %file );
is $table->landscape,
    '<table><tr><th>header1</th><td>foo</td><td>one</td><td>1</td></tr><tr><th>header2</th><td>bar</td><td>two</td><td>2</td></tr><tr><th>header3</th><td>baz</td><td>three</td><td>3</td></tr></table>',
    "transposed simple JSON data via method from new object"
;

is Spreadsheet::HTML::landscape( %file ),
    '<table><tr><th>header1</th><td>foo</td><td>one</td><td>1</td></tr><tr><th>header2</th><td>bar</td><td>two</td><td>2</td></tr><tr><th>header3</th><td>baz</td><td>three</td><td>3</td></tr></table>',
    "transposed simple JSON data via procedure"
;
