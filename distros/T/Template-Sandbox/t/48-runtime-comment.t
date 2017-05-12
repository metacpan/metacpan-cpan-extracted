#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;

plan tests => 1;

my ( $template, $syntax );

#
#  1: Simple comment
$syntax = 'this sentence should<: # this is invisible :> be seamless';
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()},
    'this sentence should be seamless',
    'comments are hidden' );
