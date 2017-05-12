#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More tests => 1;

use POSIX::1003::OS qw(TMP_MAX);

# constant from POSIX.xs
ok(defined TMP_MAX, 'TMP_MAX='.TMP_MAX);

use POSIX::1003::OS;  # try load all
