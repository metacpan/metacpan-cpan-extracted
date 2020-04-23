#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use MIDI::Simple;

use_ok 'Music::Duration::Partition';

throws_ok { Music::Duration::Partition->new( pool => [] ) }
    qr/Empty pool not allowed/, 'empty pool not allowed';

my $mdp = Music::Duration::Partition->new;
isa_ok $mdp, 'Music::Duration::Partition';

ok ref($mdp->durations) eq 'HASH', 'durations';
is $mdp->size, 4, 'size';
is_deeply $mdp->pool, [ keys %MIDI::Simple::Length ], 'pool';

$mdp = Music::Duration::Partition->new( pool => [qw/ wn /] );
isa_ok $mdp, 'Music::Duration::Partition';

my $got = $mdp->motif;
is_deeply $got, ['wn'], 'motif';

$mdp = Music::Duration::Partition->new( size => 8, pool => [qw/ wn /] );
isa_ok $mdp, 'Music::Duration::Partition';

$got = $mdp->motif;
is_deeply $got, [qw/ wn wn /], 'motif';

$mdp = Music::Duration::Partition->new( pool => [qw/ qn /] );
isa_ok $mdp, 'Music::Duration::Partition';

$got = $mdp->motif;
is_deeply $got, [ ('qn') x 4 ], 'motif';

$mdp = Music::Duration::Partition->new( pool => [qw/ tqn /] );
isa_ok $mdp, 'Music::Duration::Partition';

$got = $mdp->motif;
is_deeply $got, [ ('tqn') x 6 ], 'motif';

$mdp = Music::Duration::Partition->new( pool => [qw/ qn tqn /] );
isa_ok $mdp, 'Music::Duration::Partition';

$mdp->pool_select( sub { return $mdp->pool->[0] } );

$got = $mdp->motif;
is_deeply $got, [ ('qn') x 4 ], 'motif';

$mdp->pool_select( sub { return $mdp->pool->[-1] } );

$got = $mdp->motif;
is_deeply $got, [ ('tqn') x 6 ], 'motif';

$mdp = Music::Duration::Partition->new( size => 100, pool => ['d50'] );
isa_ok $mdp, 'Music::Duration::Partition';

$got = $mdp->motif;
is_deeply $got, [qw/ d50 d50 /], 'motif';

$mdp = Music::Duration::Partition->new(
    pool    => [qw/ hn qn /],
    weights => [ 1, 0 ],
);
isa_ok $mdp, 'Music::Duration::Partition';

$got = $mdp->motif;
is_deeply $got, [qw/ hn hn /], 'motif';

$mdp = Music::Duration::Partition->new(
    pool    => [qw/ hn qn /],
    weights => [ 0, 1 ],
);
isa_ok $mdp, 'Music::Duration::Partition';

$got = $mdp->motif;
is_deeply $got, [qw/ qn qn qn qn /], 'motif';

$mdp = Music::Duration::Partition->new(
    pool    => [qw/ hn qn /],
    weights => [ 1, 1, 1 ],
);
isa_ok $mdp, 'Music::Duration::Partition';

throws_ok { $mdp->motif }
    qr/Number of values must equal number of weights/,
    'wrong pool weight';

done_testing();
