#!perl -T

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Template::Sandbox;

my ( @tests, $template, $syntax, $value, $padding );

sub DELIM()  { 0; }
sub SYNTAX() { 1; }
sub RESULT() { 2; }

@tests = (
    [ 0,       '<: expr a :>',      'value of a',      ],
    [ 0,       '<: nosuchtoken :>', 'compile failure', ],
    [ 0,       '[% expr a %]',      'literal',         ],
    [ 0,       '[% nosuchtoken %]', 'literal',         ],
    [ '[% %]', '<: expr a :>',      'literal',         ],
    [ '[% %]', '<: nosuchtoken :>', 'literal',         ],
    [ '[% %]', '[% expr a %]',      'value of a',      ],
    [ '[% %]', '[% nosuchtoken %]', 'compile failure', ],
    );

my $num_pad_before  = 2;
my $num_pad_after   = 2;
my $num_pad_between = 2;
my $num_double_up   = 2;

plan tests => ( scalar( @tests ) * $num_pad_before * $num_pad_after *
    $num_pad_between * $num_double_up );

$value   = '42';
$padding = 'padpadpad';

#  Ew, ugly but indentation gets silly otherwise.
foreach my $pad_before ( 0, 1 )
{
foreach my $pad_after ( 0, 1 )
{
foreach my $pad_between ( 0, 1 )
{
foreach my $double_up ( 0, 1 )
{
foreach my $test ( @tests )
{
    my ( $open, $close, $test_desc, $result );

    $syntax = $test->[ SYNTAX ];

    #  This results in some duplicate tests for $pad_between when
    #  $double_up is false, but I can live with that.
    $syntax = $syntax . ( $pad_between ? $padding : '' ) . $syntax
        if $double_up;
    $syntax = $padding . $syntax  if $pad_before;
    $syntax = $syntax  . $padding if $pad_after;

    $test_desc = $syntax;

    if( $test->[ DELIM ] )
    {
        ( $open, $close ) = split( /\s+/, $test->[ DELIM ] );

        $template = Template::Sandbox->new(
            open_delimiter  => $open,
            close_delimiter => $close,
            );

        $test_desc .= ' with delim ' . $test->[ DELIM ];
    }
    else
    {
        $open  = '<:';
        $close = ':>';
        $template = Template::Sandbox->new();
        $test_desc .= ' with default delim';
    }

    if( $test->[ RESULT ] eq 'compile failure' )
    {
        my ( $char );

        $char = $pad_before ? 10 : 1;
        throws_ok { $template->set_template_string( $syntax ) }
            qr/compile error: unrecognised token \(\Q$open\E nosuchtoken \Q$close\E\) at line 1, char $char of/,
            $test_desc . ' causes compile failure';
        next;
    }

    $template->set_template_string( $syntax );
    $template->add_var( a => $value );

    if( $test->[ RESULT ] eq 'value of a' )
    {
        $result = $value;
        $test_desc .= ' gives expr';

        $result = $result . ( $pad_between ? $padding : '' ) . $result
            if $double_up;
        $result = $padding . $result  if $pad_before;
        $result = $result  . $padding if $pad_after;
    }
    elsif( $test->[ RESULT ] eq 'literal' )
    {
        $result = $syntax;
        $test_desc .= ' gives literal';
    }
    else
    {
        #  In case I fat-finger the tests.
        BAIL_OUT( 'Typo in test results: ' . $test->[ RESULT ] );
    }

    is( ${$template->run()}, $result, $test_desc );
}
}
}
}
}
