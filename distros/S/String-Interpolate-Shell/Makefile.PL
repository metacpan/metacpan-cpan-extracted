use strict;
use warnings;

use inc::Module::Install;

name 'String-Interpolate-Shell';
all_from 'lib/String/Interpolate/Shell.pm';
license 'gpl3';

requires 'Text::Balanced';
requires 'Params::Check';
requires 'base';

author_requires 'Test::Pod';
author_requires 'Test::Pod::Coverage';

test_requires 'Test::More';

author_tests( 'xt' );
WriteAll();
