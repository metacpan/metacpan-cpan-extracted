#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More;

use POSIX::1003::FS     qw/:glob/;

plan tests => 2;

cmp_ok(fnmatch("a", "a"), '!=', FNM_NOMATCH, 'static pattern, hit');
cmp_ok(fnmatch("a", "b"), '==', FNM_NOMATCH, 'static pattern, fail');
