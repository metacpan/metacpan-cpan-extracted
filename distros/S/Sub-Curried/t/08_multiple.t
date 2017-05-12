#!/usr/bin/perl
use strict; use warnings;
use Data::Dumper;
use Sub::Curried;

use Test::More tests=>2;

# Check that a curry can return multiple values;
# (This isn't really the normal behaviour, but it's kinda important in a Perl context)

curry range ($from, $to) { return ($from..$to) }

is_deeply [ range(3,6) ], [3..6], 'Simple multiple value test';

curry cycle (@list) {
    my @curr = @list;
    return sub {
        @curr = @list unless @curr;
        return shift @curr;
        };
}

# convert an infinite list into a perl array
curry take ($count, $it) {
    return map { $it->() } 1..$count;
}

my $attenshun = cycle ['Left', 'Right'];

is_deeply [take 4 => $attenshun], [qw/Left Right Left Right/], 'Take returns list';

