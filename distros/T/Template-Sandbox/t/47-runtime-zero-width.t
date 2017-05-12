#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;

plan tests => 4;

my ( $template, $syntax );

#
#  1: Constant true if.
$syntax = <<END_OF_TEMPLATE;
<: if 1 :>
true
<: else :>
false
<: endif :>
END_OF_TEMPLATE
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()},
    "true\n",
    'constant-true if zero-width behaviour' );

#
#  2: Constant false if.
$syntax = <<END_OF_TEMPLATE;
<: if 0 :>
true
<: else :>
false
<: endif :>
END_OF_TEMPLATE
$template = Template::Sandbox->new();
$template->set_template_string( $syntax );
is( ${$template->run()},
    "false\n",
    'constant-false if zero-width behaviour' );

#
#  3: Variable true if.
$syntax = <<END_OF_TEMPLATE;
<: if a :>
true
<: else :>
false
<: endif :>
END_OF_TEMPLATE
$template = Template::Sandbox->new();
$template->add_var( a => 1 );
$template->set_template_string( $syntax );
is( ${$template->run()},
    "true\n",
    'variable-true if zero-width behaviour' );

#
#  4: Variable false if.
$syntax = <<END_OF_TEMPLATE;
<: if a :>
true
<: else :>
false
<: endif :>
END_OF_TEMPLATE
$template = Template::Sandbox->new();
$template->add_var( a => 0 );
$template->set_template_string( $syntax );
is( ${$template->run()},
    "false\n",
    'varible-false if zero-width behaviour' );
