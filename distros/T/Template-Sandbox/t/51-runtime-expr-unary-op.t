#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;

plan tests => 20 * 2;

my ( $template, $syntax );

foreach my $bare ( 0, 1 )
{
    my ( $token, $desc, $constructor );

    if( $bare )
    {
        $token = '';
        $desc  = 'bare ';
        $constructor = sub { Template::Sandbox->new( allow_bare_expr => 1 ); };
    }
    else
    {
        $token = ' expr';
        $desc  = '';
        $constructor = sub { Template::Sandbox->new(); };
    }

#
#  1: negative literal number
$syntax = "<:$token -1 :>";
$template = $constructor->();
$template->set_template_string( $syntax );
is( ${$template->run()},
    '-1',
    $desc . 'unary op negative literal number' );

#
#  2: negated (!) true literal number
$syntax = "<:$token !1 :>";
$template = $constructor->();
$template->set_template_string( $syntax );
is( ${$template->run()},
    '0',
    $desc . 'unary op negated (!) true literal number' );

#
#  3: negated (!) false literal number
$syntax = "<:$token !0 :>";
$template = $constructor->();
$template->set_template_string( $syntax );
is( ${$template->run()},
    '1',
    $desc . 'unary op negated (!) false literal number' );

#
#  4: negated (not) true literal number
$syntax = "<:$token not 1 :>";
$template = $constructor->();
$template->set_template_string( $syntax );
is( ${$template->run()},
    '0',
    $desc . 'unary op negated (not) true literal number' );

#
#  5: negated (not) false literal number
$syntax = "<:$token not 0 :>";
$template = $constructor->();
$template->set_template_string( $syntax );
is( ${$template->run()},
    '1',
    $desc . 'unary op negated (not) false literal number' );

#
#  6: negative literal string
#  This is odd, probably should raise an error or a warning at least.
$syntax = "<:$token -'a string' :>";
$template = $constructor->();
$template->set_template_string( $syntax );
is( ${$template->run()},
    '-a string',
    $desc . 'unary op negative literal string' );

#
#  7: negated (!) true literal string
$syntax = "<:$token !'a string' :>";
$template = $constructor->();
$template->set_template_string( $syntax );
is( ${$template->run()},
    '0',
    $desc . 'unary op negated (!) true literal string' );

#
#  8: negated (!) false literal string
$syntax = "<:$token !'' :>";
$template = $constructor->();
$template->set_template_string( $syntax );
is( ${$template->run()},
    '1',
    $desc . 'unary op negated (!) false literal string' );

#
#  9: negated (not) true literal string
$syntax = "<:$token not 'a string' :>";
$template = $constructor->();
$template->set_template_string( $syntax );
is( ${$template->run()},
    '0',
    $desc . 'unary op negated (not) true literal string' );

#
#  10: negated (not) false literal string
$syntax = "<:$token not '' :>";
$template = $constructor->();
$template->set_template_string( $syntax );
is( ${$template->run()},
    '1',
    $desc . 'unary op negated (not) false literal string' );

#
#  11: negative variable number
$syntax = "<:$token -a :>";
$template = $constructor->();
$template->add_var( a => 1 );
$template->set_template_string( $syntax );
is( ${$template->run()},
    '-1',
    $desc . 'unary op negative variable number' );

#
#  12: negated (!) true variable number
$syntax = "<:$token !a :>";
$template = $constructor->();
$template->add_var( a => 1 );
$template->set_template_string( $syntax );
is( ${$template->run()},
    '0',
    $desc . 'unary op negated (!) true variable number' );

#
#  13: negated (!) false variable number
$syntax = "<:$token !a :>";
$template = $constructor->();
$template->add_var( a => 0 );
$template->set_template_string( $syntax );
is( ${$template->run()},
    '1',
    $desc . 'unary op negated (!) false variable number' );

#
#  14: negated (not) true variable number
$syntax = "<:$token not a :>";
$template = $constructor->();
$template->add_var( a => 1 );
$template->set_template_string( $syntax );
is( ${$template->run()},
    '0',
    $desc . 'unary op negated (not) true variable number' );

#
#  15: negated (not) false variable number
$syntax = "<:$token not a :>";
$template = $constructor->();
$template->add_var( a => 0 );
$template->set_template_string( $syntax );
is( ${$template->run()},
    '1',
    $desc . 'unary op negated (not) false variable number' );

#
#  16: negative variable string
#  This is odd, probably should raise an error or a warning at least.
$syntax = "<:$token -a :>";
$template = $constructor->();
$template->add_var( a => 'a string' );
$template->set_template_string( $syntax );
is( ${$template->run()},
    '-a string',
    $desc . 'unary op negative variable string' );

#
#  17: negated (!) true variable string
$syntax = "<:$token !a :>";
$template = $constructor->();
$template->add_var( a => 'a string' );
$template->set_template_string( $syntax );
is( ${$template->run()},
    '0',
    $desc . 'unary op negated (!) true variable string' );

#
#  18: negated (!) false variable string
$syntax = "<:$token !a :>";
$template = $constructor->();
$template->add_var( a => '' );
$template->set_template_string( $syntax );
is( ${$template->run()},
    '1',
    $desc . 'unary op negated (!) false variable string' );

#
#  19: negated (not) true variable string
$syntax = "<:$token not a :>";
$template = $constructor->();
$template->add_var( a => 'a string' );
$template->set_template_string( $syntax );
is( ${$template->run()},
    '0',
    $desc . 'unary op negated (not) true variable string' );

#
#  20: negated (not) false variable string
$syntax = "<:$token not a :>";
$template = $constructor->();
$template->add_var( a => '' );
$template->set_template_string( $syntax );
is( ${$template->run()},
    '1',
    $desc . 'unary op negated (not) false variable string' );
}
