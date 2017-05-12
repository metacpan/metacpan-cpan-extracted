#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use PerlX::Range;

my $r = PerlX::Range->new(first => 1, last => 5);

my @n = @$r;
is_deeply(\@n, [1,2,3,4,5], 'Range can be deref as a array');

@n = $r->to_a;
is_deeply(\@n, [1,2,3,4,5], 'Range has to_a method to returns an array');

done_testing;
