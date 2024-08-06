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

    $o = rx_timer(0, 1)->pipe( op_take(1) );
    obs_is $o, ['0'], 'timer(0, 1)->pipe( op_take(1) )';

    $o = rx_timer(0, 0)->pipe( op_take(1) );
    obs_is $o, ['0'], 'timer(0, 0)->pipe( op_take(1) )';

    $o = rx_timer(0, 0)->pipe( op_take(2) );
    obs_is $o, ['(01)'], 'timer(0, 0)->pipe( op_take(2) )';
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

subtest 'op_combine_latest_with' => sub {
    my $o1 = cold('----a----b----c----|');
    my $o2 = cold('--d--e--f--g--|');
    my $e  =     ['----uv--wx-y--z----|', {
        u => 'ad', v => 'ae', w => 'af',
        x => 'bf', y => 'bg', z => 'cg',
    }];

    my $o = $o1->pipe(
        op_combine_latest_with($o2),
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
        {name => undef, grade => 'A'},
        {name => undef, grade => 'B'},
    )->pipe(
        op_distinct_until_key_changed('name'),
    );
    obs_is $o, ['(abc)', {
        a => { name => 'Peter', grade => 'A' },
        b => { name => 'Mary', grade => 'B' },
        c => { name => undef, grade => 'A' },
    }];
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

    $o = cold('12345')->pipe(
        op_map(sub {$_[1] + 2}),
    );
    obs_is $o, ['23456'], 'map with index';

    $o = cold('12345')->pipe(
        op_map(sub {$_[1] + $_}),
    );
    obs_is $o, ['13579'], 'map with index and $_';
};

subtest 'op_filter' => sub {
    my $o = rx_interval(1)->pipe( op_filter(sub {$_[0] % 2 == 1}), op_take(3) );
    obs_is $o, ['--a-b-c', {a => 1, b => 3, c => 5}], 'filter with three/six values';

    $o = rx_interval(1)->pipe( op_filter(sub {$_ % 2 == 1}), op_take(3) );
    obs_is $o, ['--a-b-c', {a => 1, b => 3, c => 5}], 'filter with three/six values and $_';

    $o = cold('1234567890')->pipe(
        op_filter(sub {$_[1] % 3 == 1}),
    );
    obs_is $o, ['-2--5--8--'], 'filter by index';
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
        rx_timer(1)->pipe( op_ignore_elements ),
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
                               d => [ 'd', 'e' ], e => ['e'],
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

subtest 'op_skip_until' => sub {
    my $o = cold('-01234567')->pipe(
        op_skip_until( rx_timer(4.5) ),
    );
    obs_is $o, ['-----4567'], 'simple case';

    $o = cold('-01234567#')->pipe(
        op_skip_until( rx_timer(4.5) ),
    );
    obs_is $o, ['-----4567#'], 'error at the end';

    $o = cold('-01#')->pipe(
        op_skip_until( rx_timer(4.5) ),
    );
    obs_is $o, ['---#'], 'error before notifier';

    $o = cold('-01234567')->pipe(
        op_skip_until(
            rx_concat(
                rx_timer(4)->pipe( op_ignore_elements ),
                rx_throw_error(undef),
            )
        ),
    );
    obs_is $o, ['----#'], 'notifier throws error';

    $o = cold('-01234567')->pipe(
        op_skip_until( rx_EMPTY ),
    );
    obs_is $o, ['---------'], 'notifier only completes';

    $o = rx_of(1, 2, 3)->pipe(
        op_skip_until( rx_of(1) ),
    );
    obs_is $o, ['(123)'], 'of with of notifier';
};

subtest 'rx_partition' => sub {
    my $source = cold('0123456789');

    my ($o1, $o2) = rx_partition(
        $source,
        sub { $_[0] % 2 == 1 },
    );

    obs_is $o1, ['-1-3-5-7-9'], 'value o1';
    obs_is $o2, ['0-2-4-6-8-'], 'value o2';

    $source = cold('1234567890');

    ($o1, $o2) = rx_partition(
        $source,
        sub { $_[1] % 2 == 1 },
    );

    obs_is $o1, ['-2-4-6-8-0'], 'index o1';
    obs_is $o2, ['1-3-5-7-9-'], 'index o2';
};

subtest 'op_ignore_elements' => sub {
    my $source = cold('0123');
    my $o = $source->pipe(op_ignore_elements());
    obs_is $o, ['----'], 'completes correctly';

    $source = cold('0123#');
    $o = $source->pipe(op_ignore_elements());
    obs_is $o, ['----#'], 'emits error correctly';
};

subtest 'op_delay' => sub {
    my $source = cold('0(12)3');
    my $o = $source->pipe(op_delay(2));
    obs_is $o, ['--0(12)3'], 'completes correctly';

    $source = cold('0123#');
    $o = $source->pipe(op_delay(2));
    obs_is $o, ['--01#'], 'emits error correctly';

    $source = cold('5-');
    $o = $source->pipe(op_delay(2));
    obs_is $o, ['--5'], 'completes correctly';

    $source = cold('5----');
    $o = $source->pipe(op_delay(2));
    obs_is $o, ['--5--'], 'completes correctly';
};

subtest 'op_buffer' => sub {
    my $source = cold('01-23-45-67-89');
    my $notifier = cold('--1--2--3');
    my $o = $source->pipe(op_buffer($notifier));
    obs_is $o, ['--a--b--c----d', {
        a => [ 0, 1 ],
        b => [ 2, 3 ],
        c => [ 4, 5 ],
        d => [ 6, 7, 8, 9 ],
    }], 'works';
};

subtest 'op_buffer_time' => sub {
    my $source = cold('-12-34-56');
    my $o = $source->pipe(op_buffer_time(3));
    obs_is $o, ['---a--b-c', {
        a => [ 1, 2 ],
        b => [ 3, 4 ],
        c => [ 5, 6 ],
    }];
};

subtest 'op_concat_with' => sub {
    my $o = rx_interval(1)->pipe(
        op_take(2),
        op_concat_with(
            rx_interval(1)->pipe(op_take(3)),
            rx_interval(1)->pipe(op_take(2)),
        ),
    );
    obs_is $o, ['-0101201'];
};

subtest 'op_count' => sub {
    my $o = rx_EMPTY->pipe(op_count);
    obs_is $o, ['0'], 'empty';

    $o = rx_interval(1)->pipe(
        op_take(7),
        op_count(sub { $_ % 2 }),
    );
    obs_is $o, ['-------3'], 'predicate';

    $o = cold('2222222')->pipe(
        op_count(sub { $_[1] % 2 == 0 }),
    );
    obs_is $o, ['------4'], 'index';
};

subtest 'op_default_if_empty' => sub {
    my $o = rx_timer(1)->pipe(
        op_ignore_elements,
        op_default_if_empty(4),
    );
    obs_is $o, ['-4'];

    $o = cold('-0-')->pipe(
        op_default_if_empty(4),
    );
    obs_is $o, ['-0-'];

    $o = rx_EMPTY->pipe(op_default_if_empty(4));
    obs_is $o, ['4'];
};

subtest 'rx_range' => sub {
    my $o = rx_range(10, 7);
    obs_is $o, ['(abcdefg)', {
        a => 10,
        b => 11,
        c => 12,
        d => 13,
        e => 14,
        f => 15,
        g => 16,
    }];
};

subtest 'op_reduce' => sub {
    my $o = cold('12345')->pipe(
        op_reduce(sub { $_[0] + $_[1] }),
    );
    obs_is $o, ['----a', { a => 15 }], 'w/o seed';

    $o = cold('12345')->pipe(
        op_reduce(sub { $_[0] + $_[1] }, 1),
    );
    obs_is $o, ['----a', { a => 16 }], 'with seed';
};

subtest 'rx_zip' => sub {
    my $o = rx_zip(
        rx_interval(1)->pipe(op_take(3)),
        rx_interval(2),
        rx_interval(3),
    );
    obs_is $o, ['---a--b--c', {
        a => [ 0, 0, 0 ],
        b => [ 1, 1, 1 ],
        c => [ 2, 2, 2 ],
    }], 'w/ rx_interval';

    $o = rx_zip(
        rx_of(1, 2, 3),
        rx_of(10, 20, 30, 40),
        rx_of(qw/ a b c /),
    );
    obs_is $o, ['(abc)', {
        a => [ 1, 10, 'a' ],
        b => [ 2, 20, 'b' ],
        c => [ 3, 30, 'c' ],
    }], 'w/ rx_of';
};

subtest 'op_every' => sub {
    my $o = rx_zip(
        rx_interval(1),
        rx_of(5, 10, 15, 18, 20),
    )->pipe(
        op_every(sub { $_->[1] % 5 == 0 }),
        op_map(sub { $_ ? 1 : 0 }),
    );
    obs_is $o, ['----0'], 'returns false';

    $o = rx_zip(
        rx_interval(1),
        rx_of(5, 10, 15, 20),
    )->pipe(
        op_every(sub { $_->[1] % 5 == 0 }),
    );
    obs_is $o, ['----1'], 'returns true';
};

subtest 'op_element_at' => sub {
    my $o = rx_interval(1)->pipe(
        op_element_at(3),
    );
    obs_is $o, ['----3'], 'finds it';

    $o = rx_interval(1)->pipe(
        op_take(2),
        op_element_at(2, 9),
    );
    obs_is $o, ['--9'], 'default';
};

subtest 'op_zip_with' => sub {
    my $o = rx_interval(0.7)->pipe(
        op_take(3),
        op_zip_with(
            rx_interval(1),
            rx_interval(2),
        ),
    );
    obs_is $o, ['--a-b-c', {
        a => [ 0, 0, 0 ],
        b => [ 1, 1, 1 ],
        c => [ 2, 2, 2 ],
    }];
};

subtest 'rx_generate' => sub {
    my $o = rx_generate(
        1,
        sub { $_ <= 5 },
        sub { $_ + 1 },
        sub { $_ ** 2 + 1 },
    );
    obs_is $o, ['(abcde)', {
        a => 2,
        b => 5,
        c => 10,
        d => 17,
        e => 26,
    }], 'squares';
};

subtest 'is_observable' => sub {
    my $o = cold('-1');
    ok is_observable($o);
};

subtest 'op_merge_with' => sub {
    my $o = rx_interval(3)->pipe(
        op_merge_with( rx_interval(4) ),
        op_take(5),
    );
    obs_is $o, ['---00-1-12'];
};

subtest 'rx_on_error_resume_next' => sub {
    my $o = rx_on_error_resume_next(
        rx_of(1, 2, 3)->pipe( op_concat_with(rx_throw_error('goo')) ),
        rx_throw_error('foo'),
        rx_of(7, 8, 9),
        rx_throw_error('foo'),
    );
    obs_is $o, ['(123789)'];
};

subtest 'op_on_error_resume_next_with' => sub {
    my $o = rx_of(1, 2, 3)->pipe(
        op_concat_with(rx_throw_error('goo')),
        op_on_error_resume_next_with(
            rx_throw_error('foo'),
            rx_of(7, 8, 9),
            rx_throw_error('foo'),
        ),
    );
    obs_is $o, ['(123789)'];
};

subtest 'op_skip_while' => sub {
    my $o = rx_of(1, 3, 5, 2, 7, 1)->pipe(
        op_skip_while(sub { $_ < 4 }),
    );
    obs_is $o, ['(5271)'];
};

subtest 'op_switch_all' => sub {
    my $o = rx_timer(0, 3)->pipe(
        op_take(3),
        op_map(sub { rx_interval(2)->pipe(op_take(5)) }),
        op_switch_all(),
        op_take(6),
    );
    obs_is $o, ['--0--0--0-1-2-3'];
};

subtest 'op_merge_all' => sub {
    my $i = 0;
    my $o = rx_timer(0, 3)->pipe(
        op_map(sub {
            my $idx = $i++;
            return rx_interval(2)->pipe(
                op_map(sub { [$idx, $_] }),
                op_take(4),
            );
        }),
        op_merge_all(1),
        op_take(12),
    );
    obs_is $o, ['--a-b-c-d-e-f-g-h-i-j-k-l', {
        a => [ 0, 0 ],
        b => [ 0, 1 ],
        c => [ 0, 2 ],
        d => [ 0, 3 ],
        e => [ 1, 0 ],
        f => [ 1, 1 ],
        g => [ 1, 2 ],
        h => [ 1, 3 ],
        i => [ 2, 0 ],
        j => [ 2, 1 ],
        k => [ 2, 2 ],
        l => [ 2, 3 ],
    }];
};

subtest 'op_concat_all' => sub {
    my $o = rx_interval(1)->pipe(
        op_map(sub { rx_interval(1)->pipe( op_take(3) ) }),
        op_concat_all(),
        op_take(10),
    );
    obs_is $o, ['--0120120120'];
};

subtest 'op_exhaust_map' => sub {
    my $o = rx_interval(3)->pipe(
        op_map(sub {
            my ($v) = @_;
            return rx_interval(1)->pipe(
                op_map(sub { [$v, $_] }),
                op_take(4),
            );
        }),
        op_exhaust_all(),
        op_take(12),
    );
    obs_is $o, ['----abcd--efgh--ijkl', {
        a => [ 0, 0 ],
        b => [ 0, 1 ],
        c => [ 0, 2 ],
        d => [ 0, 3 ],
        e => [ 2, 0 ],
        f => [ 2, 1 ],
        g => [ 2, 2 ],
        h => [ 2, 3 ],
        i => [ 4, 0 ],
        j => [ 4, 1 ],
        k => [ 4, 2 ],
        l => [ 4, 3 ],
    }];
};

subtest 'op_find' => sub {
    my $o = rx_interval(1)->pipe(
        op_find(sub { $_[0] == 7 }),
    );
    obs_is $o, ['--------7'], 'finds';

    $o = rx_interval(1)->pipe(
        op_take(5),
        op_find(sub { $_[0] == 7 }),
    );
    obs_is $o, ['-----a', {
        a => undef,
    }], "doesn't find";
};

subtest 'op_find_index' => sub {
    my $o = rx_interval(1)->pipe(
        op_map(sub { $_ * 2 }),
        op_find_index(sub { $_ == 14 }),
    );
    obs_is $o, ['--------7'], 'finds';

    $o = rx_interval(1)->pipe(
        op_take(5),
        op_find_index(sub { $_ == 14 }),
    );
    obs_is $o, ['-----a', { a => -1 }], "doesn't find";
};

subtest 'rx_iif' => sub {
    my $i;
    my $o = rx_iif(
        sub { $i > 5 },
        rx_of(7, 8, 9),
        rx_of(1, 2, 3),
    );

    $i = 4;
    obs_is $o, ['(123)'], 'false';

    $i = 6;
    obs_is $o, ['(789)'], 'true';
};

subtest 'op_is_empty' => sub {
    my $o = rx_interval(1)->pipe(
        op_is_empty,
        op_map(sub { $_ ? 1 : 0 }),
    );
    obs_is $o, ['-0'], 'full';

    $o = rx_timer(2)->pipe(
        op_ignore_elements,
        op_is_empty,
        op_map(sub { $_ ? 1 : 0 }),
    );
    obs_is $o, ['--1'], 'empty';
};

subtest 'op_last' => sub {
    my $o = cold('-5-6-')->pipe( op_last );
    obs_is $o, ['----6'];

    $o = cold('-5-6-7-')->pipe(
        op_last(sub { $_ % 2 == 0 }),
    );
    obs_is $o, ['------6'];

    $o = cold('---')->pipe(
        op_last(undef, 9),
    );
    obs_is $o, ['--9'];
};

subtest 'op_race_with' => sub {
    my $o = rx_interval(3)->pipe(
        op_race_with(
            rx_interval(2),
            rx_interval(1),
        ),
        op_take(5),
    );
    obs_is $o, ['-01234'];
};

subtest 'op_take_last' => sub {
    my $o = rx_of(1, 2, 3, 5, 6)->pipe(
        op_take_last(3),
    );
    obs_is $o, ['(356)'];

    $o = rx_of(5, 6)->pipe(
        op_take_last(3),
    );
    obs_is $o, ['(56)'];
};

subtest 'op_audit' => sub {
    my $o = cold('-01-23-45')->pipe(
        op_audit(sub { cold('--1') }),
    );
    obs_is $o, ['---1--3--5'];

    $o = cold('-01-2#')->pipe(
        op_audit(sub { cold('--1') }),
    );
    obs_is $o, ['---1-#'];

    $o = cold('-01-23-45')->pipe(
        op_audit(sub { cold('--#') }),
    );
    obs_is $o, ['---#'];
};

subtest 'op_single' => sub {
    my $o = cold('-01')->pipe(
        op_single(sub { $_ % 2 == 0 }),
    );
    obs_is $o, ['--0'];

    $o = cold('1-')->pipe(
        op_single(),
    );
    obs_is $o, ['-1'];
};

subtest 'op_merge_all' => sub {
    my $o = rx_of(0, 1, 5, 2)->pipe(
        op_map(sub { rx_timer($_) }),
        op_merge_all(1),
    );
    obs_is $o, ['00----0-0'];
};

subtest 'op_delay_when' => sub {
    my $o = rx_of(3, 4, 5)->pipe(
        op_delay_when(sub { rx_timer($_) }),
    );
    obs_is $o, ['---345'];
};

subtest 'op_distinct' => sub {
    my $o = rx_of(1, 1, 2, 2, 2, 1, 2, 3, 4, 3, 2, 1)->pipe(
        op_distinct(),
    );
    obs_is $o, ['(1234)'];

    $o = rx_of(
        { age => 4, name => 'Foo'},
        { age => 7, name => 'Bar'},
        { age => 5, name => 'Foo'},
    )->pipe(
        op_distinct(sub { $_->{name} }),
    );
    obs_is $o, ['(ab)', {
        a => { age => 4, name => 'Foo' },
        b => { age => 7, name => 'Bar' },
    }];
};

subtest 'op_skip_last' => sub {
    my $o = cold('-a--b--c-d--')->pipe(
        op_skip_last(2),
    );
    obs_is $o, ['-------a-b--'];
};

done_testing();
