#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use Sub::Iterator qw(
                        gen_array_iterator
                        gen_fh_iterator
                );

subtest gen_array_iterator => sub {
    my $ary = [1,2,3];
    my $sub = gen_array_iterator($ary);
    is(ref($sub), "CODE");
    is($sub->(), 1);
    is($sub->(), 2);
    is($sub->(), 3);
    ok(!defined($sub->()));

    # the same array can be reiterated
    $sub = gen_array_iterator($ary);
    is(ref($sub), "CODE");
    is($sub->(), 1);
};

# XXX test gen_fh_iterator

DONE_TESTING:
done_testing();
