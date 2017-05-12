#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;

plan tests => 8;

my ( $template, $syntax );

#
#  1: Define with value.
$syntax = '${ADEFINE}';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax, { ADEFINE => 'string' } );
is( ${$template->run()},
    "string",
    'define with value' );

#
#  2:  Default value.
$syntax = '${NOSUCHDEFINE:this is my default value}';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()},
    "this is my default value",
    'define falling through to default' );

#
#  3:  No such define.
$syntax = '${NOSUCHDEFINE}';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()},
    "[undefined preprocessor define 'NOSUCHDEFINE']",
    'missing define' );

#
#  4: Recursive define.
$syntax = '${RECURSIVE}';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax,
    { RECURSIVE => 'this is ${RECURSIVE}' } );
is( ${$template->run()},
    "this is [recursive define 'RECURSIVE']",
    'recursive define' );

#
#  5: Quoted define with value.
$syntax = '${\'ADEFINE\'}';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax, { ADEFINE => 'string' } );
is( ${$template->run()},
    "'string'",
    'quoted define with value' );

#
#  6: Quoted define with quotes in value.
$syntax = '${\'ADEFINE\'}';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax,
    { ADEFINE => "string with 'quotes' in it" } );
is( ${$template->run()},
    q('string with \\'quotes\\' in it'),
    'quoted define with quotes in value' );

#
#  7: Quoted define falling through to default.
$syntax = '${\'NOSUCHDEFINE:default value quoted\'}';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()},
    q('default value quoted'),
    'quoted define falling through to default' );

#
#  8: Quoted missing define.
$syntax = '${\'NOSUCHDEFINE\'}';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()},
    q('[undefined preprocessor define \\'NOSUCHDEFINE\\']'),
    'quoted missing define' );
