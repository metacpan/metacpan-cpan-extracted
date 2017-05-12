use strict;
use warnings;
use Test::More;

use Sub::Mux;

my $mux = Sub::Mux->new(
    sub { 'a' },
    sub { ['b'] },
);

isa_ok $mux => 'Sub::Mux';

is $mux->execute_first, 'a';

$mux->push_subs(sub { 'c' });

is scalar(@{$mux->subs}), 3;
is_deeply $mux->execute_list(1, 2), [ ['b'], 'c'];

$mux->unshift_subs(sub { '!' });

is scalar(@{$mux->subs}), 4;
is_deeply $mux->execute_all, ['!', 'a', ['b'], 'c'];

$mux->shift_subs;
is scalar(@{$mux->subs}), 3;
is $mux->execute, 'a';

$mux->pop_subs;
is scalar(@{$mux->subs}), 2;
is_deeply $mux->execute_list(0, 1), ['a', ['b']];

done_testing;
