#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Resource::Silo;

my $counter = 0;
resource bunny =>
    ignore_cache    => 1,
    init            => sub { ++$counter };

is silo->bunny, 1, 'first bunny';
is silo->bunny, 2, 'second bunny';
is silo->bunny, 3, 'third bunny';

done_testing;
