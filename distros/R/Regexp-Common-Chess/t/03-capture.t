#!/usr/bin/perl
# Copyright (c) 2011 - Olof Johansson <olof@cpan.org>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use warnings;
use strict;
use Test::More tests => 1;
use Regexp::Common qw/Chess/;

my $re = $RE{Chess}{SAN}{-keep};

my $str = 'Ka1 Kxa1 Qh8+ xa8=K Qh8# Qxh8+ Qxh8#';
my $refstr = 'Ka1 Kxa1 Qh8+ Qh8# Qxh8+ Qxh8#';
is(join(' ', $str =~ /$RE{Chess}{SAN}/g), $refstr, "Stripping away non-moves");

