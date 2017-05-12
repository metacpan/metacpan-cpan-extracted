# This will be converted from Module::Install to plain
# ordinary ExtUtils::MakeMaker before production release.

use strict;
use inc::Module::Install;

name           'Package-Util';
all_from       'lib/Package/Util.pm';
requires       'Carp'       => 0;
build_requires 'Test::More' => '0.47';

WriteAll;
