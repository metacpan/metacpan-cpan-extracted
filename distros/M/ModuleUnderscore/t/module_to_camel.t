#!perl
#
# This file is part of ModuleUnderscore
#
# This software is copyright (c) 2014 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

use Module::Underscore ':all';
use Test::More;    # last test to print

my %module_to_underscore = (
    'Test'            => 'test',
    'Test::App'       => 'test_app',
    'test_app'        => 'test_app',
    'hello my friend' => 'hello_my_friend',
    'Test::'          => 'test_',
);

plan tests => scalar keys %module_to_underscore;

while ( my ( $module_string, $underscore_string )
    = each %module_to_underscore )
{
    is( module_to_underscore($module_string),
        $underscore_string,
        "$module_string is transformed into $underscore_string" );
}

done_testing;
