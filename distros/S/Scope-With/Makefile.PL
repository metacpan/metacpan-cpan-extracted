use 5.008001;

use strict;
use warnings;

use inc::Module::Install;

name     'Scope-With';
author   'chocolateboy <chocolate@cpan.org>';
license  'artistic';
all_from 'lib/Scope/With.pm';

requires 'Devel::Declare' => '0.006000';
requires  Mouse           => '0.58';
requires 'mysubs'         => '1.11';

test_requires 'Test::More';
WriteAll;
