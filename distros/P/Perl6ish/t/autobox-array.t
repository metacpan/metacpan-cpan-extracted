#!/usr/bin/env perl
use strict;
use Test::More tests => 4;

use Perl6ish;
use Perl6ish::Autobox;

my $a = [1, 3, 2];
is( $a->min, 1 );
is( $a->max, 3 );
is( $a->elems, 3);

is_deeply( $a->xx(3), [qw/1 3 2 1 3 2 1 3 2/]);

