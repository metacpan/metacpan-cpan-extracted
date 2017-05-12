#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;
use Template::Sandbox::StringFunctions qw/:all/;
use Test::Exception;

my ( @tests );

@tests = (
    [ 'lc',         q/'UPPERCASE'/,    'uppercase' ],
    [ 'lcfirst',    q/'UPPERCASE'/,    'uPPERCASE' ],
    [ 'uc',         q/'lowercase'/,    'LOWERCASE' ],
    [ 'ucfirst',    q/'lowercase'/,    'Lowercase' ],
    [ 'ucfirst',    q/'lowercase'/,    'Lowercase' ],
    [ 'substr',     q/'abcdef', 2, 3/, 'cde' ],
    [ 'length',     q/'abcdef'/,        6 ],
    [ 'possessive', q/'James'/,         q/James'/ ],
    [ 'possessive', q/'Fred'/,          q/Fred's/ ],
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
