use strict;
use warnings;
use Test::More;

use RxPerl ':all';

my @got;

rx_of(
    {name => {first => 'Mary'}},
    {name => {first => 'Paul'}},
    {house => {first => 'Chicago'}},
    15,
    undef,
)->pipe(
    op_pluck('name', 'first'),
)->subscribe(
    sub {push @got, $_[0]},
    undef,
    sub {push @got, '__DONE'},
);

is_deeply \@got, ['Mary', 'Paul', undef, undef, undef, '__DONE'], 'got correct values';

done_testing();

