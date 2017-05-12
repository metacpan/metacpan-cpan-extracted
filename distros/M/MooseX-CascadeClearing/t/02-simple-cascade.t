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

use Test::More tests => 12;

use SingleCascade;

my $foo = SingleCascade->new(master => 'abcd');

isa_ok $foo, 'SingleCascade';

#is_defined('foo');

is($foo->master, 'abcd', 'initial setting OK');

is($foo->sub1, 'abcd1', 'sub1 set ok');
is($foo->sub2, 'abcd2', 'sub2 set ok');
is($foo->sub3, 'abcd3', 'sub3 set ok');

$foo->clear_master;

is($foo->has_master() ? 1 : 0, 0, 'master cleared');

is($foo->has_sub1 ? 1 : 0, 0, 'sub1 cleared as well');
is($foo->has_sub2 ? 1 : 0, 0, 'sub2 cleared as well');
is($foo->has_sub3 ? 1 : 0, 0, 'sub3 cleared as well');

is($foo->sub1, 'nuts1', 'sub1 set ok');
is($foo->sub2, 'nuts2', 'sub2 set ok');
is($foo->sub3, 'nuts3', 'sub3 set ok');

