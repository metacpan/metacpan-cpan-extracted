#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More tests => 2;

use POSIX::1003::Time qw(CLOCKS_PER_SEC strftime localtime);

# constant from POSIX.xs
ok(defined CLOCKS_PER_SEC, 'CLOCKS_PER_SEC='.CLOCKS_PER_SEC);

my $stamp = strftime "%FT%TZ", localtime;
ok(length $stamp, "strftime $stamp");

use POSIX::1003::Time;  # try load all
