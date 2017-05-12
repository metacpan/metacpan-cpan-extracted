use strict;
use warnings;

BEGIN {
  die "OS unsupported\n"
    if $^O eq 'MSWin32';
}

use inc::Module::Install;

name 'Proc-Topus';
all_from 'lib/Proc/Topus.pm';
license 'MIT';

requires 'Exporter';
requires 'Socket';

test_requires 'Test::More';

auto_install;
WriteAll;
