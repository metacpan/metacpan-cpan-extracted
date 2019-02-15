#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 55;

ok require String::Tools, 'Require String::Tools';

my @import = qw(
    define
    is_blank
    shrink
    stitch
    stitcher
    stringify
    subst
    subst_vars
    trim
    trim_lines
);
can_ok( 'String::Tools' => @import );
String::Tools->import(@import);    # I wish this returned a true value
can_ok( 'main' => @import );

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

# Some strings to test with
my $string            = "  x is \$x,  \n  y is \${ y },  \n  _ is \$_  \n";
my $stretched_string  = '  stretched  $string  ';
my $multi_line_string = <<END_STRING;
    This is a multi-line string. \t
\tIt should have several things to clear up. \n
END_STRING

# shrink
is shrink($string), 'x is $x, y is ${ y }, _ is $_', 'shrink shrunk string';
is shrink($stretched_string), 'stretched $string',
    'shrink shrunk stretched_string';
is shrink($multi_line_string),
    'This is a multi-line string. It should have several things to clear up.',
    'shrink shrunk multi_line_string';

# stitch
is stitch(qw(1 2 3 4)),    '1 2 3 4', 'stitch numbers';
is stitch('', "\n", "\0"), "\n\0",    'stitch blanks';
is stitch('a', '', 'b'),   'ab',      'stitch letters';

# stitcher
is stitcher( '-',  qw(1 2 3 4)),    '1-2-3-4', 'stitcher numbers';
is stitcher( '=',  '', "\n", "\0"), "\n\0",    'stitcher blanks';
is stitcher( '!!', 'a', '', 'b'),   'ab',      'stitcher letters';

# stringify
is stringify(undef),         '', 'undef stringifies properly';
is stringify(123_456), '123456', 'number stringifies properly';
is stringify( [] ),          '', 'Empty array stringifies properly';
is stringify( \@import ),
    stitch(qw(
        define
        is_blank
        shrink
        stitch
        stitcher
        stringify
        subst
        subst_vars
        trim
        trim_lines
    )),
    'Array stringifies properly';
is stringify( {} ),            '', 'Empty hash stringifies properly';
is stringify( { a => 1 } ), 'a 1', 'Hash stringifies properly';
{
    my $object = bless( {}, 'Foo' );
    like stringify($object), qr/\AFoo\=HASH\(0x[[:xdigit:]]+\)\z/,
        'Un-overloaded object stringifies properly';

    eval <<END_BAR;
    package Bar;
    use overload '""' => sub { __PACKAGE__ . ' is an object' };
END_BAR
    my $bar = bless( {}, 'Bar' );
    is stringify($bar), 'Bar is an object',
        'An overloaded object stringifies properly';
}

# subst
is subst( $stretched_string, string => 'string' ),
    '  stretched  string  ',
    'subst string';

local $_ = 4;
is subst( $string,   x => 11, y => 111   ),
    "  x is 11,  \n  y is 111,  \n  _ is \$_  \n",
    'subst 1';
is subst( $string, { x => 22, y => 222 } ),
    "  x is 22,  \n  y is 222,  \n  _ is \$_  \n",
    'subst 2';
is subst( $string, [ x => 33, y => 333 ] ),
    "  x is 33,  \n  y is 333,  \n  _ is \$_  \n",
    'subst 3';
is subst( $string ),
    "  x is \$x,  \n  y is \${ y },  \n  _ is 4  \n",
    'subst 4';

# subst_vars
is_deeply [ subst_vars($string) ], [qw( x y _ )],
    'subst_vars got the list of vars';
is_deeply [ subst_vars($string . "\n" . $string) ], [qw( x y _ )],
    'subst_vars got the list of vars';

# trim
is trim($stretched_string),                             'stretched  $string',
    'trim default';

is trim( $stretched_string,      qr/ /,      '' ),     ' stretched  $string  ',
    'trim left';
is trim( $stretched_string, l => qr/ /, r => '' ),     ' stretched  $string  ',
    'trim left with l =>';

is trim( $stretched_string,      '',      qr/ / ),    '  stretched  $string ',
    'trim right';
is trim( $stretched_string, l => '', r => qr/ / ),    '  stretched  $string ',
    'trim right with r =>';

is trim( $stretched_string,      qr/ /,      qr/ +/ ), ' stretched  $string',
    'trim both';
is trim( $stretched_string, l => qr/ /, r => qr/ +/ ), ' stretched  $string',
    'trim both with l => and r =>';

is trim_lines($string),
    "x is \$x,\ny is \${ y },\n_ is \$_",
    'Many lines were trimmed';
is trim_lines($multi_line_string),
    "This is a multi-line string.\n"
    . "It should have several things to clear up.",
    'Many lines were trimmed';

