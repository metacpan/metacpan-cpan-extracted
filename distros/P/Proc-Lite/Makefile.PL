use strict;
use warnings;

BEGIN {
  die "OS unsupported\n"
    if $^O eq 'MSWin32';
}

use inc::Module::Install;

name 'Proc-Lite';
all_from 'lib/Proc/Lite.pm';
license 'MIT';

requires 'Carp';
requires 'Errno';
requires 'IO::Pipe';
requires 'IO::Select';
requires 'POSIX';

test_requires 'Test::More';

auto_install;
WriteAll;
