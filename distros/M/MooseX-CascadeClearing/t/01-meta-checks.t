#!/usr/bin/env perl
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

use Test::More tests => 6;

use SingleCascade;

my $foo = SingleCascade->new(master => 'abcd');
isa_ok $foo, 'SingleCascade';

my $meta = $foo->meta;
isa_ok $meta, 'Moose::Meta::Class';

my %atts = map { $_ => 1 } $meta->get_attribute_list;

my @names = keys %atts;
### hmm: @names

ok exists $atts{master}, 'master att exists';

my $master = $meta->get_attribute('master');

TODO: {
    local $TODO = q{Attributes don't seem to acknowledge being trait'ed};

    ok $master->has_applied_traits, 'traits have been applied';
}

ok $master->can('has_clear_master'), 'master can has_clear_master';
is $master->clear_master, 'foo', 'master clear_master is foo';

### traits: $master->applied_traits

