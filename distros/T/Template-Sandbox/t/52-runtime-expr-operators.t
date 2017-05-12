#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;

plan tests => 313;

my ( $template, $syntax, $expected, $left, $right, $op );

#
#  1: constant or 11
$syntax = '<: expr 1 or 1 :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'constant or 11' );

#
#  2: constant or 10
$syntax = '<: expr 1 or 0 :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'constant or 10' );

#
#  3: constant or 01
$syntax = '<: expr 0 or 1 :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'constant or 01' );

#
#  4: constant or 00
$syntax = '<: expr 0 or 0 :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'constant or 00' );

#
#  5: left-constant or 11
$syntax = '<: expr 1 or b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'left-constant or 11' );

#
#  6: left-constant or 10
$syntax = '<: expr 1 or b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    b => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'left-constant or 10' );

#
#  7: left-constant or 01
$syntax = '<: expr 0 or b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'left-constant or 01' );

#
#  8: left-constant or 00
$syntax = '<: expr 0 or b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    b => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'left-constant or 00' );

#
#  9: right-constant or 11
$syntax = '<: expr a or 1 :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'right-constant or 11' );

#
#  10: right-constant or 10
$syntax = '<: expr a or 0 :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'right-constant or 10' );

#
#  11: right-constant or 01
$syntax = '<: expr a or 1 :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'right-constant or 01' );

#
#  12: right-constant or 00
$syntax = '<: expr a or 0 :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'right-constant or 00' );

#
#  13: variable or 11
$syntax = '<: expr a or b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 1,
    b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'variable or 11' );

#
#  14: variable or 10
$syntax = '<: expr a or b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 1,
    b => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'variable or 10' );

#
#  15: variable or 01
$syntax = '<: expr a or b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 0,
    b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'variable or 01' );

#
#  16: variable or 00
$syntax = '<: expr a or b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 0,
    b => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'variable or 00' );

#
#  17: constant || 11
$syntax = '<: expr 1 || 1 :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'constant || 11' );

#
#  18: constant || 10
$syntax = '<: expr 1 || 0 :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'constant || 10' );

#
#  19: constant || 01
$syntax = '<: expr 0 || 1 :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'constant || 01' );

#
#  20: constant || 00
$syntax = '<: expr 0 || 0 :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'constant || 00' );

#
#  21: left-constant || 11
$syntax = '<: expr 1 || b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'left-constant || 11' );

#
#  22: left-constant || 10
$syntax = '<: expr 1 || b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    b => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'left-constant || 10' );

#
#  23: left-constant || 01
$syntax = '<: expr 0 || b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'left-constant || 01' );

#
#  24: left-constant || 00
$syntax = '<: expr 0 || b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    b => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'left-constant || 00' );

#
#  25: right-constant || 11
$syntax = '<: expr a || 1 :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'right-constant || 11' );

#
#  26: right-constant || 10
$syntax = '<: expr a || 0 :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'right-constant || 10' );

#
#  27: right-constant || 01
$syntax = '<: expr a || 1 :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'right-constant || 01' );

#
#  28: right-constant || 00
$syntax = '<: expr a || 0 :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'right-constant || 00' );

#
#  29: variable || 11
$syntax = '<: expr a || b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 1,
    b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'variable || 11' );

#
#  30: variable || 10
$syntax = '<: expr a || b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 1,
    b => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'variable || 10' );

#
#  31: variable || 01
$syntax = '<: expr a || b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 0,
    b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'variable || 01' );

#
#  32: variable || 00
$syntax = '<: expr a || b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 0,
    b => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'variable || 00' );

#
#  33: constant and 11
$syntax = '<: expr 1 and 1 :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'constant and 11' );

#
#  34: constant and 10
$syntax = '<: expr 1 and 0 :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'constant and 10' );

#
#  35: constant and 01
$syntax = '<: expr 0 and 1 :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'constant and 01' );

#
#  36: constant and 00
$syntax = '<: expr 0 and 0 :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'constant and 00' );

#
#  37: left-constant and 11
$syntax = '<: expr 1 and b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'left-constant and 11' );

#
#  38: left-constant and 10
$syntax = '<: expr 1 and b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    b => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'left-constant and 10' );

#
#  39: left-constant and 01
$syntax = '<: expr 0 and b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'left-constant and 01' );

#
#  40: left-constant and 00
$syntax = '<: expr 0 and b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    b => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'left-constant and 00' );

#
#  41: right-constant and 11
$syntax = '<: expr a and 1 :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'right-constant and 11' );

#
#  42: right-constant and 10
$syntax = '<: expr a and 0 :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'right-constant and 10' );

#
#  43: right-constant and 01
$syntax = '<: expr a and 1 :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'right-constant and 01' );

#
#  44: right-constant and 00
$syntax = '<: expr a and 0 :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'right-constant and 00' );

#
#  45: variable and 11
$syntax = '<: expr a and b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 1,
    b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'variable and 11' );

#
#  46: variable and 10
$syntax = '<: expr a and b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 1,
    b => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'variable and 10' );

#
#  47: variable and 01
$syntax = '<: expr a and b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 0,
    b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'variable and 01' );

#
#  48: variable and 00
$syntax = '<: expr a and b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 0,
    b => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'variable and 00' );

#
#  49: constant && 11
$syntax = '<: expr 1 && 1 :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'constant && 11' );

#
#  50: constant && 10
$syntax = '<: expr 1 && 0 :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'constant && 10' );

#
#  51: constant && 01
$syntax = '<: expr 0 && 1 :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'constant && 01' );

#
#  52: constant && 00
$syntax = '<: expr 0 && 0 :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'constant && 00' );

#
#  53: left-constant && 11
$syntax = '<: expr 1 && b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'left-constant && 11' );

#
#  54: left-constant && 10
$syntax = '<: expr 1 && b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    b => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'left-constant && 10' );

#
#  55: left-constant && 01
$syntax = '<: expr 0 && b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'left-constant && 01' );

#
#  56: left-constant && 00
$syntax = '<: expr 0 && b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    b => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'left-constant && 00' );

#
#  57: right-constant && 11
$syntax = '<: expr a && 1 :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'right-constant && 11' );

#
#  58: right-constant && 10
$syntax = '<: expr a && 0 :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'right-constant && 10' );

#
#  59: right-constant && 01
$syntax = '<: expr a && 1 :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'right-constant && 01' );

#
#  60: right-constant && 00
$syntax = '<: expr a && 0 :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'right-constant && 00' );

#
#  61: variable && 11
$syntax = '<: expr a && b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 1,
    b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', 'variable && 11' );

#
#  62: variable && 10
$syntax = '<: expr a && b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 1,
    b => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'variable && 10' );

#
#  63: variable && 01
$syntax = '<: expr a && b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 0,
    b => 1,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'variable && 01' );

#
#  64: variable && 00
$syntax = '<: expr a && b :>';
$template = Template::Sandbox->new();
$template->add_vars( {
    a => 0,
    b => 0,
    } );
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', 'variable && 00' );

#
#  65-88: arithmetic/concat operators.
foreach my $op_test (
    [ 32, '+', 8, '40' ],
    [ 32, '-', 8, '24' ],
    [ 32, '*', 8, '256' ],
    [ 32, '/', 8, '4' ],
    [ 9,  '%', 8, '1' ],
    [ 32, '.', 8, '328' ],
    )
{
    ( $left, $op, $right, $expected ) = @{$op_test};

    foreach my $constant_test (
        [ "$left $op $right", "constant"       ],
        [ "$left $op b",      "left-constant"  ],
        [ "a $op $right",     "right-constant" ],
        [ "a $op b",          "variable"       ],
        )
    {
        $syntax = '<: expr ' . $constant_test->[ 0 ] . ' :>';
        $template = Template::Sandbox->new();
        $template->add_vars( {
            a => $left,
            b => $right,
            } );
        $template->set_template_string( $syntax );
        is( ${$template->run()}, $expected, $constant_test->[ 1 ] . " $op" );
    }
}

#
#  89-312: Comparison operators.
foreach my $op_test (
    [ 'cmp', 'string', '0', '-1', '1', '0', ],
    [ 'ne',  'string', '0',  '1', '1', '0', ],
    [ 'eq',  'string', '1',  '0', '0', '1', ],
    [ 'ge',  'string', '1',  '0', '1', '1', ],
    [ 'le',  'string', '1',  '1', '0', '1', ],
    [ 'gt',  'string', '0',  '0', '1', '0', ],
    [ 'lt',  'string', '0',  '1', '0', '0', ],
    [ '<=>', 'num',    '0', '-1', '1', '0', ],
    [ '!=',  'num',    '0',  '1', '1', '0', ],
    [ '==',  'num',    '1',  '0', '0', '1', ],
    [ '>=',  'num',    '1',  '0', '1', '1', ],
    [ '<=',  'num',    '1',  '1', '0', '1', ],
    [ '>',   'num',    '0',  '0', '1', '0', ],
    [ '<',   'num',    '0',  '1', '0', '0', ],
    )
{
    my ( @expected_series, @val_pairs, $string );

    ( $op, $string, @expected_series ) = @{$op_test};

    if( $string eq 'string' )
    {
        @val_pairs = (
            [ 'aaa', 'aaa', ],
            [ 'aaa', 'bbb', ],
            [ 'bbb', 'aaa', ],
            [ 'bbb', 'bbb', ],
            );
    }
    else
    {
        @val_pairs = (
            [ 1, 1, ],
            [ 1, 2, ],
            [ 2, 1, ],
            [ 2, 2, ],
            );
    }

    foreach my $val_pair ( @val_pairs )
    {
        my ( $litleft, $litright );

        ( $left,    $right ) = @{$val_pair};
        ( $litleft, $litright ) = @{$val_pair};

        $litleft  = "'$litleft'"  if $string eq 'string';
        $litright = "'$litright'" if $string eq 'string';

        $expected = shift( @expected_series );

        foreach my $constant_test (
            [ "$litleft $op $litright", "constant"       ],
            [ "$litleft $op b",         "left-constant"  ],
            [ "a $op $litright",        "right-constant" ],
            [ "a $op b",                "variable"       ],
            )
        {
            $syntax = '<: expr ' . $constant_test->[ 0 ] . ' :>';
            $template = Template::Sandbox->new();
            $template->add_vars( {
                a => $left,
                b => $right,
                } );
            $template->set_template_string( $syntax );
            is( ${$template->run()}, $expected,
                $constant_test->[ 1 ] . " $litleft $op $litright" );
        }
    }
}

#
#  313: assign operator
#  TODO: probably best in own test file with more cases.
$syntax = '<: expr a :> <: expr a = 54 :> <: expr a :>';
$template = Template::Sandbox->new();
$template->add_var( a => 10 );
$template->set_template_string( $syntax );
is( ${$template->run()},
    '10  54',
    'assign operator' );
