#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use MIDI::Simple;

use_ok 'Music::Duration::Partition';

throws_ok { Music::Duration::Partition->new( pool => [] ) }
    qr/Empty pool not allowed/, 'empty pool';

my $mdp = new_ok 'Music::Duration::Partition';
ok ref($mdp->durations) eq 'HASH', 'durations';
is $mdp->size, 4, 'size';
is_deeply $mdp->pool, [ keys %MIDI::Simple::Length ], 'pool';

$mdp = new_ok 'Music::Duration::Partition' => [ pool => [qw/ wn /] ];
is_deeply $mdp->motif, ['wn'], 'motif';

$mdp = new_ok 'Music::Duration::Partition' => [
    size => 8,
    pool => [qw/ wn /]
];
is_deeply $mdp->motif, [qw/ wn wn /], 'motif';

$mdp = new_ok 'Music::Duration::Partition' => [ pool => [qw/ qn /] ];
is_deeply $mdp->motif, [ ('qn') x 4 ], 'motif';

$mdp = new_ok 'Music::Duration::Partition' => [ pool => [qw/ tqn /] ];
is_deeply $mdp->motif, [ ('tqn') x 6 ], 'motif';

$mdp = new_ok 'Music::Duration::Partition' => [ pool => [qw/ qn tqn /] ];
$mdp->pool_select( sub { return $mdp->pool->[0] } );
is_deeply $mdp->motif, [ ('qn') x 4 ], 'motif';
$mdp->pool_select( sub { return $mdp->pool->[-1] } );
is_deeply $mdp->motif, [ ('tqn') x 6 ], 'motif';

$mdp = new_ok 'Music::Duration::Partition' => [
    size => 100,
    pool => ['d50']
];
is_deeply $mdp->motif, [qw/ d50 d50 /], 'motif';

$mdp = new_ok 'Music::Duration::Partition' => [
    pool    => [qw/ hn qn /],
    weights => [ 1, 0 ],
];
is_deeply $mdp->motif, [qw/ hn hn /], 'motif';

$mdp = new_ok 'Music::Duration::Partition' => [
    pool    => [qw/ hn qn /],
    weights => [ 0, 1 ],
];
is_deeply $mdp->motif, [qw/ qn qn qn qn /], 'motif';

$mdp = new_ok 'Music::Duration::Partition' => [
    pool    => [qw/ hn qn /],
    weights => [ 1, 1, 1 ],
];
throws_ok { $mdp->motif }
    qr/weights and pool not equal/,
    'wrong pool weight';

$mdp = new_ok 'Music::Duration::Partition' => [ pool => [qw/ dhn /] ];
is_deeply $mdp->motif, [qw/ dhn d96 /], 'remainder';

done_testing();
