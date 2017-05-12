#! /usr/bin/env perl

use Test::More tests => 29;

ok require String::Tools, 'Require String::Tools';

String::Tools->import( qw(define is_blank shrink stitch stitcher subst trim) );

is define(undef), '', 'define works on undef';
is define(''),    '', 'define works on empty';
is define(0),      0, 'define works on 0';

# is_blank
ok is_blank(undef),        'undef is blank';
ok is_blank(''),           'empty is blank';
ok is_blank(' '),          'space is blank';
ok is_blank("\t"),           'tab is blank';
ok is_blank("\n"),       'newline is blank';
ok is_blank("\0"),          'null is blank';
ok is_blank(" \n \t \0"), 'string is blank';

ok !is_blank(0),             '0 is not blank';
ok !is_blank('0'),         '"0" is not blank';
ok !is_blank('blank'), '"blank" is not blank';

# shrink
is shrink('  stretched  string '), 'stretched string', 'shrink shrunk';

# stitch
is stitch(qw(1 2 3 4)),    '1 2 3 4', 'stitch numbers';
is stitch('', "\n", "\0"), "\n\0",    'stitch blanks';
is stitch('a', '', 'b'),   'ab',      'stitch letters';

# stitcher
is stitcher( '-',  qw(1 2 3 4)),    '1-2-3-4', 'stitcher numbers';
is stitcher( '=',  '', "\n", "\0"), "\n\0",    'stitcher blanks';
is stitcher( '!!', 'a', '', 'b'),   'ab',      'stitcher letters';

# subst
my $string = 'x is $x, y is ${ y }, _ is $_';
local $_ = 4;
is subst( $string,   x => 11, y => 111   ), 'x is 11, y is 111, _ is $_',
    'subst 1';
is subst( $string, { x => 22, y => 222 } ), 'x is 22, y is 222, _ is $_',
    'subst 2';
is subst( $string, [ x => 33, y => 333 ] ), 'x is 33, y is 333, _ is $_',
    'subst 3';
is subst( $string ),                        'x is $x, y is ${ y }, _ is 4',
    'subst 4';

# trim
is trim('  stretched  string '),                'stretched  string',
    'trim default';
is trim('  stretched  string ', qr/ /,     ''), ' stretched  string ',
    'trim left';
is trim('  stretched  string ',     '', qr/ /), '  stretched  string',
    'trim right';
is trim('  stretched  string ', qr/ /, qr/ +/), ' stretched  string',
    'trim both';

