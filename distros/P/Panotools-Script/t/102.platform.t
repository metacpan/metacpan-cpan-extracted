#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';

use Panotools::Makefile::Utils qw/platform/;
ok (1);

ok (Panotools::Makefile::Utils::platform eq $^O);
ok (platform eq $^O);

ok (platform ('FOO'));
ok (platform eq 'FOO');

ok (platform ('MSWin32'));
ok (platform eq 'MSWin32');

ok (platform ('linux'));
ok (platform eq 'linux');

ok (platform ('BAR'));
ok (platform eq 'BAR');

ok (platform (undef));
ok (platform eq $^O);

ok (Panotools::Makefile::Utils::platform eq $^O);
