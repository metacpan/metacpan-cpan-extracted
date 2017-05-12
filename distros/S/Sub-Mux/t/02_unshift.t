use strict;
use warnings;
use Test::More;

use Sub::Mux;

my $mux = Sub::Mux->new(
    sub { 'a' },
);

$mux->unshift_subs(
    sub { 'b' },
    sub { 'c' },
    sub { 'd' },
);

is_deeply $mux->execute_all, ['b', 'c', 'd', 'a'];

done_testing;
