use strict;
use inc::Module::Install;

name           'Parse-BooleanLogic';
all_from       'lib/Parse/BooleanLogic.pm';

requires       'Regexp::Common';

build_requires 'Test::More';
build_requires 'Test::Deep';

WriteAll;

