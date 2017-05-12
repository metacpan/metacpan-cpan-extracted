use strict;
use warnings;
use inc::Module::Install;

name            'Sledge-Utils';
all_from        'lib/Sledge/Utils.pm';

requires 'String::CamelCase' => 0;
test_requires 'Test::Base' => 0;

author_tests 'xt';
use_test_base;
WriteAll;

