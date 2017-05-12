#!/usr/bin/env perl
use warnings;
use strict;
use Permute::Named;
use Test::More;

sub is_permutation {
    my ($args, $expect, $name) = @_;
    my @result = permute_named($args);
    is_deeply([ permute_named($args) ],
        $expect, "$name: pass array ref, list context");
    is_deeply([ permute_named(@$args) ],
        $expect, "$name: pass array, list context");
    is_deeply(scalar(permute_named($args)),
        $expect, "$name: pass array ref, scalar context");
    is_deeply(scalar(permute_named(@$args)),
        $expect, "$name: pass array, scalar context");
}
is_permutation(
    [   bool => [ 0, 1 ],
        x    => [qw(foo bar baz)]
    ],
    [   {   'bool' => 0,
            'x'    => 'foo'
        },
        {   'bool' => 0,
            'x'    => 'bar'
        },
        {   'bool' => 0,
            'x'    => 'baz'
        },
        {   'bool' => 1,
            'x'    => 'foo'
        },
        {   'bool' => 1,
            'x'    => 'bar'
        },
        {   'bool' => 1,
            'x'    => 'baz'
        }
    ],
    'multi-valued args'
);
is_permutation(
    [ foo => 1, bar => 2 ],
    [ { foo => 1, bar => 2 } ],
    'single-valued args'
);
is_permutation(
    [ should_do_baz => [ 0, 1 ] ],
    [ { should_do_baz => 0 }, { should_do_baz => 1 } ],
    'one multi-valued arg'
);
done_testing;
