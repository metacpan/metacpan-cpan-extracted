#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;

plan tests => 4;

my ( $template, $syntax );

#
#  1: constant 0.
$syntax = "<: expr 0 :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '0', $syntax );

#
#  2: constant 1.
$syntax = "<: expr 1 :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '1', $syntax );

#
#  3: constant 42.
$syntax = "<: expr 42 :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, '42', $syntax );

#
#  4: constant 'constant'.
$syntax = "<: expr 'constant' :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, 'constant', $syntax );
