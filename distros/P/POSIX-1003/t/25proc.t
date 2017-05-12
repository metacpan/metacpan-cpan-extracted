#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More tests => 1;

use POSIX::1003::Proc qw(EXIT_SUCCESS);

# constant from POSIX.xs
ok(defined EXIT_SUCCESS, 'EXIT_SUCCESS='.EXIT_SUCCESS);

use POSIX::1003::Proc;  # try load all
