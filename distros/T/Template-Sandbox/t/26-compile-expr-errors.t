#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;
use Test::Exception;

plan tests => 3 * 2;

my ( $template, $syntax );

foreach my $bare_expr ( 0, 1 )
{
    my ( $token, $desc, $constructor );

    if( $bare_expr )
    {
        $token = '';
        $desc  = 'bare';
        $constructor =
            sub { Template::Sandbox->new( allow_bare_expr => 1, @_ ); };
    }
    else
    {
        $token = ' expr';
        $desc  = 'expr';
        $constructor = sub { Template::Sandbox->new( @_ ); };
    }

    #
    #  1: Malformed expression.
    $syntax = "<:$token a a :>";
    $template = $constructor->();
    throws_ok { $template->set_template_string( $syntax ) }
        qr/compile error: Not a well-formed expression: a a at line 1, char 1 of/,
        "[$desc] malformed expression a a";

    #
    #  2: Too many open brackets.
    $syntax = "<:$token ( ( a ) :>";
    $template = $constructor->();
    throws_ok { $template->set_template_string( $syntax ) }
        qr/compile error: Not a well-formed expression: \( \( a \) at line 1, char 1 of/,
        "[$desc] too many open brackets";

    #
    #  3: Too many close brackets.
    $syntax = "<:$token ( a ) ) :>";
    $template = $constructor->();
    throws_ok { $template->set_template_string( $syntax ) }
        qr/compile error: Not a well-formed expression: \( a \) \) at line 1, char 1 of/,
        "[$desc] too many close brackets";
}
