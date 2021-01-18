#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use RxPerl::Test;

use RxPerl::SyncTimers ':all';

subtest 'rx_from' => sub {
    my $o = rx_from([10, 20, 30]);
    obs_is $o, ['(abc)', {a => 10, b => 20, c => 30}], 'from with array';

    $o = rx_from( rx_of(50, 100, 150) );
    obs_is $o, ['(abc)', {a => 50, b => 100, c => 150}], 'from with observable';

    $o = rx_from('hi there');
    obs_is $o, ['(hizthere)', {z => ' '}], 'from with string';
};

subtest 'rx_of' => sub {
    obs_is rx_of(), [ '' ], 'empty of';
    obs_is rx_of(10, 20, 30), [ '(abc)', { a => 10, b => 20, c => 30 } ], 'of with 3 values';
};

subtest 'rx_interval' => sub {
    my $o = rx_interval(2)->pipe( op_take(5) );
    obs_is $o, ['--0-1-2-3-4'], 'interval(2)';
};

subtest 'rx_timer' => sub {
    my $o = rx_timer(3, 1)->pipe( op_take(5) );
    obs_is $o, ['---01234'], 'timer(3, 1)';
};

subtest 'rx_combine_latest' => sub {
    my $o1 = cold('----a----b----c----|');
    my $o2 = cold('--d--e--f--g--|');
    my $e  =     ['----uv--wx-y--z----|', {
        u => 'ad', v => 'ae', w => 'af',
        x => 'bf', y => 'bg', z => 'cg',
    }];

    my $o = rx_combine_latest([$o1, $o2])->pipe(
        op_map(sub {
            my ($x, $y) = @{ $_[0] };
            return "$x$y";
        }),
    );

    obs_is($o, $e, 'combine_latest provided observables');
};

subtest 'rx_concat' => sub {
    my $o1 = cold('1-1---1-|');
    my $o2 = cold('22|');
    my $o = rx_concat($o1, $o2);
    my $e = ['1-1---1-22|'];

    obs_is($o, $e, 'concat provided observables')
};

subtest 'rx_merge' => sub {
    my $o1 = cold('-a-b-c-d-e', {a => 20, b => 40, c => 60, d => 80, e => 100});
    my $o2 = cold('------a---b', {a => 1, b => 1});
    my $o = rx_merge($o1, $o2);
    my $e = ['-a-b-cde-fg', {a => 20, b => 40, c => 60, d => 1, e => 80, f => 100, g => 1}];

    obs_is($o, $e, 'merge provided observables');
};

subtest 'rx_race' => sub {
    my $o1 = cold('--a-b-c--------|');
    my $o2 = cold('-d-e-f---------|');
    my $o3 = cold('----g-h-i------|');
    my $o = rx_race($o1, $o2, $o3);
    my $e =      ['-d-e-f---------|'];

    obs_is $o, $e, 'race provided observables';
};

subtest 'op_start_with' => sub {
    my $o = cold('----a-b')->pipe( op_start_with('c') );
    obs_is $o,  ['c---a-b'];

    $o =      cold('----a-b')->pipe( op_start_with('c', 'd') );
    obs_is $o, ['(cd)---a-b'];

    $o =   cold('----a-b')->pipe( op_start_with('c', 'd'), op_take(0) );
    obs_is $o, [''];
};

subtest 'op_with_latest_from' => sub {
    my $o1 = cold('-1--2------3-4-5-|');
    my $o2 = cold('---a-b--cd-------|');

    my $oi = $o1->pipe( op_with_latest_from($o2) );
    my $o = $oi->pipe( op_map(sub { "$_[0][0]$_[0][1]" }) );

    obs_is $o, ['----a------b-c-d-|', {a => '2a', b => '3d', c => '4d', d => '5d'}];
};

subtest 'op_debounce_time' => sub {
    my $o = cold('-1----2-345-----6---|')->pipe( op_debounce_time(3) );
    obs_is $o,  ['----1--------5-----6|'], 'normal complete';

    $o   = cold('-1----2-345-----6-|')->pipe( op_debounce_time(3) );
    obs_is $o, ['----1--------5----(6|)'], 'early complete';
};

subtest 'op_distinct_until_changed' => sub {
    my $o = cold('1-1-2-2-1-3')->pipe( op_distinct_until_changed() );
    obs_is $o,  ['1---2---1-3'];

    $o = rx_of(10, 10, undef, undef, 20, 20, 20, 30, 30, [], [])->pipe(
        op_distinct_until_changed(),
    );
    obs_is $o, ['(abcdef)', {a => 10, b => undef, c => 20, d => 30, e => [], f => []}],
        'with plain values';

    $o = rx_of(
        {name => 'Peter', grade => 'A'},
        {name => 'Peter', grade => 'B'},
        {name => 'Mary', grade => 'B'},
        {name => 'Mary', grade => 'A'},
    )->pipe(
        op_distinct_until_changed(
            sub {$_[0]->{name} eq $_[1]->{name}},
        ),
    );
    obs_is $o, ['(ab)', {a => {name => 'Peter', grade => 'A'}, b => {name => 'Mary', grade => 'B'}}],
        'names';
};

subtest 'op_distinct_until_key_changed' => sub {
    my $o = rx_of(
        {name => 'Peter', grade => 'A'},
        {name => 'Peter', grade => 'B'},
        {name => 'Mary', grade => 'B'},
        {name => 'Mary', grade => 'A'},
    )->pipe(
        op_distinct_until_key_changed('name'),
    );
    obs_is $o, ['(ab)', {a => {name => 'Peter', grade => 'A'}, b => {name => 'Mary', grade => 'B'}}];
};

subtest 'op_first' => sub {
    my $o = cold('---1-2---3-4-|')->pipe( op_first() );
    obs_is $o,  ['---1'];
};

subtest 'op_take_until' => sub {
    my $o1 = cold('-1-2-3-4-5-6-7-8');
    my $o2 = cold('--------a---b---');
    my $o = $o1->pipe( op_take_until($o2) );

    obs_is $o,   ['-1-2-3-4-'];
};

subtest 'op_take_while' => sub {
    my $o = cold('-1-3-6-4-7-2--')->pipe( op_take_while(sub {$_[0] < 5}) );
    obs_is $o,  ['-1-3-|'], 'without inclusion';

    $o =   cold('-1-3-6-4-7-2--')->pipe( op_take_while(sub {$_[0] < 5}, 1) );
    obs_is $o, ['-1-3-6'], 'with inclusion';
};

subtest 'op_map' => sub {
    my $o = rx_interval(1)->pipe( op_map(sub {$_[0] * 10}), op_take(3) );
    obs_is $o, ['-abc', {a => 0, b => 10, c => 20}], 'map with three numbers';
};

subtest 'op_filter' => sub {
    my $o = rx_interval(1)->pipe( op_filter(sub {$_[0] % 2 == 1}), op_take(3) );
    obs_is $o, ['--a-b-c', {a => 1, b => 3, c => 5}], 'filter with three/six values';
};

subtest 'op_pluck' => sub {
    my $o = rx_of(
        {name => {first => 'Mary'}},
        {name => {first => 'Paul'}},
        {house => {first => 'Chicago'}},
        15,
        undef,
    )->pipe(
        op_pluck('name', 'first'),
    );

    obs_is $o, ['(mpuuu)', {m => 'Mary', p => 'Paul', u => undef}];
};

subtest 'op_skip' => sub {
    my $o = rx_of(10, 20, 30, 40, 50)->pipe( op_skip(3) );
    obs_is $o, ['(de)', {d => 40, e => 50}], 'skip';
};

subtest 'op_repeat' => sub {
    my $o = cold('-abc-')->pipe( op_repeat(3) );
    obs_is $o,  ['-abc-abc-abc-'], 'op_repeat';

    $o =   cold('-ab#')->pipe( op_repeat(3) );
    obs_is $o, ['-ab#'], 'op_repeat with error';

    $o = cold('-abc')->pipe(
        op_repeat(-1),
        op_take(10),
    );
    obs_is $o, ['-abcabcabca'], 'op_repeat -1';
};

subtest 'rx_throw_error' => sub {
    my $o = rx_concat(
        rx_EMPTY->pipe( op_delay(1) ),
        rx_throw_error,
    );
    obs_is $o, ['-#'];
};

subtest 'op_retry' => sub {
    my $o = cold('-abc#')->pipe( op_retry(3) );
    obs_is $o,  ['-abc-abc-abc-abc#'];

    $o = cold('-abc#')->pipe( op_retry(-1), op_take(10) );
    obs_is $o,  ['-abc-abc-abc-a'];
};

subtest 'op_buffer_count' => sub {
    my $o = cold('abcdefgh')->pipe(op_buffer_count(3));
    obs_is $o, ['--a--b-c', {a => ['a', 'b', 'c'], b => ['d', 'e', 'f'], c => ['g', 'h']}];

    $o = cold('abcde')->pipe(op_buffer_count(3, 1));
    obs_is $o, ['--ab(cde)', { a => [ 'a', 'b', 'c' ], b => [ 'b', 'c', 'd' ], c => [ 'c', 'd', 'e' ],
        d                        => [ 'd', 'e' ], e => ['e'],
    }];

    $o = cold('abcde')->pipe(op_buffer_count(1));
    obs_is $o, ['abcde', {a => ['a'], b => ['b'], c => ['c'], d => ['d'], e => ['e']}];
};

subtest 'rx_EMPTY' => sub {
    my $o = rx_concat(
        rx_of('a', 'b'),
        rx_EMPTY,
        rx_EMPTY,
        rx_EMPTY,
        rx_of('c', 'd'),
    );
    obs_is $o, ['(abcd)'], 'in concat';

    obs_is rx_EMPTY, [''], 'alone';
};

subtest 'rx_fork_join' => sub {
    my $o = rx_fork_join([
        rx_of(10, 20, 30),
        rx_of(1, 2, 3),
        rx_of('a', 'b', 'c'),
    ]);
    obs_is $o, ['a', {a => [30, 3, 'c']}], 'array form';

    $o = rx_fork_join({
        x => rx_of(10, 20, 30),
        y => rx_of(1, 2, 3),
        z => rx_of('a', 'b', 'c'),
    });
    obs_is $o, ['a', {a => {
        x => 30,
        y => 3,
        z => 'c',
    }}], 'hash form';

    $o = rx_fork_join([
        rx_of(10, 20, 30),
        rx_of(1, 2, 3),
        rx_of('a', 'b', 'c'),
        rx_EMPTY,
    ]);
    obs_is $o, [''], 'array with empty';

    $o = rx_fork_join({
        x => rx_of(10, 20, 30),
        y => rx_of(1, 2, 3),
        z => rx_of('a', 'b', 'c'),
        w => rx_EMPTY,
    });
    obs_is $o, [''], 'hash with empty';
};

done_testing();
