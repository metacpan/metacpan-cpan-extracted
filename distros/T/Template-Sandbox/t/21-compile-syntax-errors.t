#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;
use Test::Exception;

plan tests => 12;

my ( $template, $syntax );

#
#  1: No such token.
$syntax = '<: no_such_token :>';
$template = Template::Sandbox->new();
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: unrecognised token \(<: no_such_token :>\) at line 1, char 1 of/,
    'no such token';

#
#  2: Unterminated :>
$syntax = '<: var x';
$template = Template::Sandbox->new();
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: unrecognised token \(<: var x\) at line 1, char 1 of/,
    'unterminated :>';

#
#  3: Missing <: endif :>
$syntax = '<: if x :>a';
$template = Template::Sandbox->new();
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: unterminated if or for block at line 1, char 11 of/,
    'missing <: endif :>';

#
#  4: Unexpected <: endif :>
$syntax = 'a<: endif :>';
$template = Template::Sandbox->new();
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: endif found without opening if, elsif or else at line 1, char 2 of/,
    'unexpected <: endif :>';

#
#  5: Unexpected <: else :>
$syntax = 'a<: else :>';
$template = Template::Sandbox->new();
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: else found without opening if or elsif at line 1, char 2 of/,
    'unexpected <: else :>';

#
#  6: Unexpected <: elsif :>
$syntax = 'a<: elsif :>';
$template = Template::Sandbox->new();
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: elsif found without opening if or elsif at line 1, char 2 of/,
    'unexpected <: elsif :>';

#
#  7: Missing <: endfor :>
$syntax = '<: for x in y :>a';
$template = Template::Sandbox->new();
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: unterminated if or for block at line 1, char 17 of/,
    'missing <: endfor :>';

#
#  8: Unexpected <: endfor :>
$syntax = 'a<: endfor :>';
$template = Template::Sandbox->new();
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: endfor found without opening for at line 1, char 2 of/,
    'unexpected <: endfor :>';

#
#  9: <: endfor :> before <: endif :>
$syntax = '<: for x in y :><: if z :>a<: endfor :><: endif :>';
$template = Template::Sandbox->new();
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: endfor found without opening for at line 1, char 28 of/,
    '<: endfor :> inside if block';

#
#  10: <: endif :> before <: endfor :>
$syntax = '<: if x :><: for y in z :>a<: endif :><: endfor :>';
$template = Template::Sandbox->new();
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: endif found without opening if, elsif or else at line 1, char 28 of/,
    '<: endif :> inside for block';

#
#  11: <: else :> before <: endfor :>
$syntax = '<: if x :><: for y in z :>a<: else :><: endfor :>';
$template = Template::Sandbox->new();
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: else found without opening if or elsif at line 1, char 28 of/,
    '<: else :> inside for block';

#
#  12: <: elsif :> before <: endfor :>
$syntax = '<: if x :><: for y in z :>a<: elsif y :><: endfor :>';
$template = Template::Sandbox->new();
throws_ok { $template->set_template_string( $syntax ) }
    qr/compile error: elsif found without opening if or elsif at line 1, char 28 of/,
    '<: elsif :> inside for block';
