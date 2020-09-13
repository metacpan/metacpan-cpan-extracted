use strict;
use warnings;
use Test::More;

use RxPerl ':all';

my @got;

# 10, undef, 20, 30, [], []
rx_of(10, 10, undef, undef, 20, 20, 20, 30, 30, [], [])->pipe(
    op_distinct_until_changed(),
)->subscribe(
    sub {push @got, $_[0]},
    undef,
    sub {push @got, '__DONE'},
);

is_deeply \@got, [10, undef, 20, 30, [], [], '__DONE'], 'got correct values';

undef @got;

rx_of(
    {name => 'Peter', grade => 'A'},
    {name => 'Peter', grade => 'B'},
    {name => 'Mary', grade => 'B'},
    {name => 'Mary', grade => 'A'},
)->pipe(
    op_distinct_until_changed(
        sub {$_[0]->{name} eq $_[1]->{name}},
    ),
)->subscribe(
    sub {push @got, $_[0]},
    undef,
    sub {push @got, '__DONE'},
);

is_deeply \@got, [
    {name => 'Peter', grade => 'A'},
    {name => 'Mary', grade => 'B'},
    '__DONE',
], 'got correct values';

undef @got;

rx_of(
    {name => 'Peter', grade => 'A'},
    {name => 'Peter', grade => 'B'},
    {name => 'Mary', grade => 'B'},
    {name => 'Mary', grade => 'A'},
)->pipe(
    op_distinct_until_key_changed('name'),
)->subscribe(
    sub {push @got, $_[0]},
    undef,
    sub {push @got, '__DONE'},
);

is_deeply \@got, [
    {name => 'Peter', grade => 'A'},
    {name => 'Mary', grade => 'B'},
    '__DONE',
], 'got correct values';

done_testing();
