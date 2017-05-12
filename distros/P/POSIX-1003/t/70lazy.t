#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More tests => 7;

use POSIX::1003 ':none';

use POSIX::1003 'posix_1003_names';
my @names = posix_1003_names;
cmp_ok(scalar @names, '>', 100, 'total names: '.@names);

my @fd1 = posix_1003_names ':fd';
cmp_ok(scalar @fd1, '>', 10, 'fd names: '.@fd1.' by tag');
cmp_ok(scalar @fd1, '<', scalar @names);

my @fd2 = posix_1003_names 'POSIX::1003::FdIO';
cmp_ok(scalar @fd2, '>', 10, 'fd names: '.@fd2.' by module');
cmp_ok(scalar @fd1, '==', scalar @fd2);

use POSIX::1003 'PATH_MAX';
cmp_ok(PATH_MAX, '>', 10, 'PATH_MAX='.PATH_MAX);

use POSIX::1003 ':math';
my $result = floor(sin(.5)*100);
cmp_ok($result, '!=', 0, "some math, result = $result");
