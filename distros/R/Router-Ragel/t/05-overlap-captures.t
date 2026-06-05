#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Router::Ragel;

# Overlapping routes with DIFFERENT capture counts. In the union DFA the shared
# transitions carry capture actions from every overlapping route; the read-back
# is gated by the winning route's placeholder count. Verify the winner's
# captures come out exactly right and the loser's extra captures don't leak.

# Two routes that BOTH match /x/y, with 1 vs 2 captures.
{
    my $r = Router::Ragel->new
        ->add('/:b/:c', 'two') # 2 captures
        ->add('/x/:a', 'one') # 1 capture, added last -> wins on /x/y
        ->compile;

    my ($d, @cap) = $r->match('/x/y');
    is $d, 'one', 'last-added 1-capture route wins on overlapping /x/y';
    is_deeply \@cap, ['y'], '...returns exactly its one capture (loser\'s 2nd does not leak)';

    my ($d2, @c2) = $r->match('/p/q');
    is $d2, 'two', '2-capture route matches a path only it can match';
    is_deeply \@c2, ['p', 'q'], '...with both captures';
}

# Reverse add-order: the 2-capture route now wins the overlap.
{
    my $r = Router::Ragel->new
        ->add('/x/:a', 'one')
        ->add('/:b/:c', 'two') # added last -> wins on /x/y
        ->compile;

    my ($d, @cap) = $r->match('/x/y');
    is $d, 'two', 'last-added 2-capture route wins on overlapping /x/y';
    is_deeply \@cap, ['x', 'y'], '...and returns both its captures';
}

# Shared prefix, different capture depths (no single path matches both).
{
    my $r = Router::Ragel->new
        ->add('/a/:x/:y', 'deep') # 2 captures
        ->add('/a/:z', 'shallow') # 1 capture
        ->compile;

    my ($d, @c) = $r->match('/a/m/n');
    is $d, 'deep', '/a/m/n -> the 2-capture route';
    is_deeply \@c, ['m', 'n'], '...both captures correct';

    my ($d2, @c2) = $r->match('/a/m');
    is $d2, 'shallow', '/a/m -> the 1-capture route';
    is_deeply \@c2, ['m'], '...single capture correct (no stale 2nd slot)';
}

done_testing;
