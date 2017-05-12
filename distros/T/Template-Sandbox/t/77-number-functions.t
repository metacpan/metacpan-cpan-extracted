#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;
use Template::Sandbox::NumberFunctions qw/:all/;
use Test::Exception;

my ( @tests );

@tests = (
    [ 'int',        q/1.4/,     '1' ],
    [ 'int',        q/1.5/,     '1' ],
    [ 'round',      q/1.4/,     '1' ],
    [ 'round',      q/1.5/,     '2' ],
    [ 'abs',        q/1/,       '1' ],
    [ 'abs',        q/-3/,      '3' ],
    [ 'numeric',    q/1/,       '1' ],
    [ 'numeric',    q/100000/,  '100,000' ],
    [ 'numeric',    q/-10000/,  '-10,000' ],
    [ 'currency',   q/1234/,    '1,234.00' ],
    [ 'currency',   q/-1234.5/, '-1,234.50' ],
    [ 'accountant_currency', q/1234/,        '1,234.00' ],
    [ 'accountant_currency', q/-1234.5/,     '(1,234.50)' ],
    [ 'decimal',             q/1234.567, 2/, '1234.57' ],
    [ 'decimal',             q/1234.567, 0/, '1235' ],
    [ 'decimal',             q/1234.567, 4/, '1234.5670' ],
    [ 'exp',        q/0/,       '1' ],
    [ 'exp',        q/1/,       '' . exp( 1 ) ],
    [ 'exp',        q/2/,       '' . exp( 2 ) ],
    [ 'log',        q/1/,       '' . log( 1 ) ],
    [ 'log',        q/2/,       '' . log( 2 ) ],
    [ 'log',        q/3/,       '' . log( 3 ) ],
    [ 'pow',        q/2, 3/,    '' . ( 2 ** 3 ) ],
    [ 'sqrt',       q/4/,       '2' ],
    [ 'max',        q/4, 5/,    '5' ],
    [ 'max',        q/5, 4/,    '5' ],
    [ 'min',        q/4, 5/,    '4' ],
    [ 'min',        q/5, 4/,    '4' ],
    );

plan tests => ( 2 * scalar( @tests ) );

foreach my $test ( @tests )
{
    my ( $function, $arg, $expected ) = @{$test};
    my ( $template, $syntax );

    $syntax = "<: expr $function( $arg ) :>";
    $template = Template::Sandbox->new();
    lives_ok { $template->set_template_string( $syntax ) }
        "parse of $function( $arg )";
    is( ${$template->run()}, $expected, "run of $function( $arg )" );
}
