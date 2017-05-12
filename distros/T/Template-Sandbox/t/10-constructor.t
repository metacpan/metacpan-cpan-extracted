#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;
use Test::Exception;

plan tests => 3;

my ( $template );

#
#  1: class constructor.
ok( Template::Sandbox->new(), "constructor via class" );

#
#  2: instance constructor.
$template = Template::Sandbox->new();
ok( $template->new(), "constructor via instance" );

#
#  3: unknown constructor option
throws_ok
    {
        Template::Sandbox->new(
            this_constructor_option_doesnt_exist => 1,
            );
    }
    qr{Template error: Unknown constructor param: 'this_constructor_option_doesnt_exist' at .*Template.*Sandbox\.pm line},
    'error on construct with unknown option';
