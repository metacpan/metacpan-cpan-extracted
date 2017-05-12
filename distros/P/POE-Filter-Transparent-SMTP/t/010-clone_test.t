#!/usr/bin/env perl

# Copyright (c) 2008-2009 George Nistorica
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

# 	($rcs) = (' $Id: 010-clone_test.t,v 1.5 2009/01/28 12:38:48 george Exp $ ' =~ /(\d+(\.\d+)+)/);

# Test to see if cloning works well

use strict;
use warnings;

use lib q{lib/};
use POE::Filter::Transparent::SMTP;
use Test::More;
use Data::Dumper;

plan tests => 3;

my ( $filter, $new_filter, $lines_fed_to_filter, $lines );

$lines_fed_to_filter = [ q{first line}, q{second line}, ];

$filter = POE::Filter::Transparent::SMTP->new();

# feed something to $filter
$filter->get_one_start($lines_fed_to_filter);

# should have two lines in the buffer now
$lines = $filter->get_pending();

# should have more than one element in $lines
cmp_ok( scalar @{$lines},
    q{>}, 0, q{Correct number of pending lines in buffer} );
$lines = $filter->get_pending();

# should have more than one elemen in $lines
cmp_ok( scalar @{$lines}, q{>}, 0,
        q{Correct number of pending lines in buffer }
      . q{after a second call of ->get_pending()} );

# clone a new filter
$new_filter = $filter->clone();

# check we're not having anything "pending" with this new filter
$lines = $filter->get_pending();
is( $lines, undef, q{Cloned filter should have no pending lines} );
