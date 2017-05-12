#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More tests => 1;

use POSIX::1003::Locale qw(LC_ALL);

# constant from POSIX.xs
ok(defined LC_ALL, 'LC_ALL='.LC_ALL);

use POSIX::1003::Locale;  # try load all
