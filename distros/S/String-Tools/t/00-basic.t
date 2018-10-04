#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 40;

ok require String::Tools, 'Require String::Tools';

my @import = qw(
    define
    is_blank
    shrink
    stitch
    stitcher
    subst
    trim
    trim_lines
);
can_ok( 'String::Tools' => @import );
String::Tools->import(@import);    # I wish this returned a true value

is $String::Tools::THREAD, ' ',
    'strings are threaded together with a space';
is $String::Tools::BLANK, '[[:cntrl:][:space:]]',
    'blanks are controls and spaces';

ok( eval {
    use warnings FATAL => qw(numeric);
    define(undef) == 0
}, 'define works on undef (numerically)' );
is define(undef), '', 'define works on undef (as string)';
is define(''),    '', 'define works on empty';
is define(0),      0, 'define works on 0';

# is_blank (only tests within ASCII)
ok is_blank($String::Tools::THREAD), '$THREAD is blank';
ok is_blank(undef),                    'undef is blank';
ok is_blank(''),                       'empty is blank';
ok is_blank(' '),                      'space is blank';
ok is_blank("\t"),                       'tab is blank';
ok is_blank("\n"),                   'newline is blank';
ok is_blank("\0"),                      'null is blank';
ok is_blank(" \n \t \0"), 'many blank things are blank';
ok is_blank( join( '' => map chr, 0 .. 0x20, 0x7f ) ),
    'all blank things are blank';

ok !is_blank($String::Tools::BLANK), '$BLANK is not blank';
ok !is_blank(0),                          '0 is not blank';
ok !is_blank('0'),                      '"0" is not blank';
ok !is_blank('blank'),              '"blank" is not blank';

# shrink
is shrink('  stretched  string  '), 'stretched string', 'shrink shrunk';

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
is trim('  stretched  string  '),                'stretched  string',
    'trim default';

is trim( '  stretched  string  ',      qr/ /,      '' ),
    ' stretched  string  ',
    'trim left';
is trim( '  stretched  string  ', l => qr/ /, r => '' ),
    ' stretched  string  ',
    'trim left with l =>';

is trim( '  stretched  string  ',      '',      qr/ / ),
    '  stretched  string ',
    'trim right';
is trim( '  stretched  string  ', l => '', r => qr/ / ),
    '  stretched  string ',
    'trim right with r =>';

is trim( '  stretched  string  ',      qr/ /,      qr/ +/ ),
    ' stretched  string',
    'trim both';
is trim( '  stretched  string  ', l => qr/ /, r => qr/ +/ ),
    ' stretched  string',
    'trim both with l => and r =>';

my $multi_line_string = <<END_STRING;
    This is a multi-line string. \t
\tIt should have several things to clear up. \n
END_STRING
is trim_lines($multi_line_string),
    "This is a multi-line string.\n"
    . "It should have several things to clear up.",
    'Many lines were trimmed';

