#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More tests => 1;

use POSIX::1003::FS qw(PATH_MAX mknod);

# constant from POSIX.xs
cmp_ok(PATH_MAX, '>', 10, 'PATH_MAX='.PATH_MAX);

use POSIX::1003::FS;  # try load all
