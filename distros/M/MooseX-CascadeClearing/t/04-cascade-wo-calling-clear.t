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

#use Test::More skip_all => 'known to not work ATM';
use Test::More tests => 9;

use FindBin;
use lib "$FindBin::Bin/lib";

use SingleCascade;

my $foo = SingleCascade->new(master => 'abcd');

isa_ok $foo, 'SingleCascade';

is($foo->master, 'abcd', 'initial setting OK');

is($foo->sub1, 'abcd1', 'sub1 set ok');
is($foo->sub2, 'abcd2', 'sub2 set ok');
is($foo->sub3, 'abcd3', 'sub3 set ok');

$foo->master('qwerty');

is($foo->master, 'qwerty', 'master set ok');

=head2

These tests check to make sure client attributes are cleared on a master's
being reset.  We do not do this yet, and may not ever (depending on where we
go with this).  Soo....  right now it's a TODO.

=cut

TODO: {
    local $TODO = 'Known to not work ATM';

    is($foo->sub1, 'qwerty1', 'sub1 cleared/set ok');
    is($foo->sub2, 'qwerty2', 'sub2 cleared/set ok');
    is($foo->sub3, 'qwerty3', 'sub3 cleared/set ok');
}
