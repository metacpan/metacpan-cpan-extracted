#!/usr/bin/env perl

use 5.006;
use strict;
use inc::Module::Install;

name            'Template-Extract';
all_from        'lib/Template/Extract.pm';
requires        Template    => '2.00';

build_requires  'Test::More';
auto_include_deps;

auto_provides;
sign; WriteAll;
