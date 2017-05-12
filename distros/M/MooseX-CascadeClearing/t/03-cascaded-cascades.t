#!/usr/bin/perl
#
# This file is part of MooseX-CascadeClearing
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib/";

use Test::More tests => 13;

use DoubleCascade;

my $foo = DoubleCascade->new(master => 'abcd');

isa_ok $foo, 'DoubleCascade';

is($foo->master, 'abcd', 'initial setting OK');

is($foo->sub1, 'abcd1', 'sub1 set ok');
is($foo->sub2, 'abcd2', 'sub2 set ok');
is($foo->sub3, 'abcd3', 'sub3 set ok');

is($foo->sub4, 'abcd4', 'sub4 set ok');

is($foo->sub4_sub1, 'abcd4sub1', 'sub4_sub1 set ok');

$foo->clear_master;

is($foo->has_master() ? 1 : 0, 0, 'master cleared');

is($foo->has_sub1 ? 1 : 0, 0, 'sub1 cleared as well');
is($foo->has_sub2 ? 1 : 0, 0, 'sub2 cleared as well');
is($foo->has_sub3 ? 1 : 0, 0, 'sub3 cleared as well');
is($foo->has_sub4 ? 1 : 0, 0, 'sub4 cleared as well');

is($foo->has_sub4_sub1 ? 1 : 0, 0, 'sub4_sub1 cleared as well');

