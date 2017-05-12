#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;

plan tests => 8;

my ( $template, $syntax );

#
#  1-2: literal number
$syntax = '<: expr 1 :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()},
    '1',
    'atomic expr literal number' );
$syntax = '<: 1 :>';
$template = Template::Sandbox->new( allow_bare_expr => 1 );
$template->set_template_string( $syntax );
is( ${$template->run()},
    '1',
    'atomic bare expr literal number' );

#
#  3-4: literal string
$syntax = q~<: expr 'a string' :>~;
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()},
    'a string',
    'atomic expr literal string' );
$syntax = q~<: 'a string' :>~;
$template = Template::Sandbox->new( allow_bare_expr => 1 );
$template->set_template_string( $syntax );
is( ${$template->run()},
    'a string',
    'atomic bare expr literal string' );

#
#  5-6: template variable
$syntax = '<: expr a :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
$template->add_var( a => 12 );
is( ${$template->run()},
    '12',
    'atomic expr variable' );
$syntax = '<: a :>';
$template = Template::Sandbox->new( allow_bare_expr => 1 );
$template->set_template_string( $syntax );
$template->add_var( a => 12 );
is( ${$template->run()},
    '12',
    'atomic bare expr variable' );

#
#  7-8: bracketed variable
$syntax = '<: expr ( a ) :>';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
$template->add_var( a => 12 );
is( ${$template->run()},
    '12',
    'atomic expr bracketed variable' );
$syntax = '<: ( a ) :>';
$template = Template::Sandbox->new( allow_bare_expr => 1 );
$template->set_template_string( $syntax );
$template->add_var( a => 12 );
is( ${$template->run()},
    '12',
    'atomic bare expr bracketed variable' );
