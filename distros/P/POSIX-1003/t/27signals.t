#!/usr/bin/env perl
use warnings;
use strict;
use lib 'lib', 'blib/lib', 'blib/arch';

use Test::More tests => 1;

use POSIX::1003::Signals qw(strsignal);

my $x = strsignal 1000;
ok(defined $x, $x);

use POSIX::1003::Signals;  # try load all
