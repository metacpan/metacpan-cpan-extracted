#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;

plan tests => 3;

my ( $template, $syntax );

#
#  1: cr.
$syntax = "<: expr cr :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, "\n", 'cr constant-var has "\n" value' );

#
#  2: undef.
$syntax = "<: expr defined( undef ) :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, "0", 'undef constant-var has undef value' );

#
#  3: null.
$syntax = "<: expr defined( null ) :>";
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()}, "0", 'null constant-var has undef value' );
