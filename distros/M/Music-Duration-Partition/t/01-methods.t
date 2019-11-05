#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use MIDI::Simple;

use_ok 'Music::Duration::Partition';

throws_ok { Music::Duration::Partition->new( pool => [] ) }
    qr/Not a non-empty ArrayRef/, 'empty pool not allowed';

my $mdp = Music::Duration::Partition->new;
isa_ok $mdp, 'Music::Duration::Partition';

ok ref($mdp->names) eq 'HASH', 'names';
ok ref($mdp->sizes) eq 'HASH', 'sizes';
is $mdp->size, 4, 'size';
is_deeply $mdp->pool, [ keys %MIDI::Simple::Length ], 'pool';

is $mdp->name(4), 'wn', 'name';
is $mdp->duration('wn'), 4, 'duration';

$mdp = Music::Duration::Partition->new( pool => [qw/ wn /] );
isa_ok $mdp, 'Music::Duration::Partition';

my $got = $mdp->motif;
isa_ok $got, 'ARRAY';
is_deeply $got, ['wn'], 'motif';

$mdp = Music::Duration::Partition->new( size => 8, pool => [qw/ wn /] );
isa_ok $mdp, 'Music::Duration::Partition';

$got = $mdp->motif;
isa_ok $got, 'ARRAY';
is_deeply $got, [qw/ wn wn /], 'motif';

$mdp = Music::Duration::Partition->new( pool => [qw/ qn /] );
isa_ok $mdp, 'Music::Duration::Partition';

$got = $mdp->motif;
isa_ok $got, 'ARRAY';
is_deeply $got, [ ('qn') x 4 ], 'motif';

$mdp = Music::Duration::Partition->new( pool => [qw/ tqn /] );
isa_ok $mdp, 'Music::Duration::Partition';

$got = $mdp->motif;
isa_ok $got, 'ARRAY';
is_deeply $got, [ ('tqn') x 6 ], 'motif';

$mdp = Music::Duration::Partition->new( pool => [qw/ qn tqn /] );
isa_ok $mdp, 'Music::Duration::Partition';

$mdp->pool_code( sub { return $mdp->pool->[0] } );

$got = $mdp->motif;
isa_ok $got, 'ARRAY';
is_deeply $got, [ ('qn') x 4 ], 'motif';

$mdp->pool_code( sub { return $mdp->pool->[-1] } );

$got = $mdp->motif;
isa_ok $got, 'ARRAY';
is_deeply $got, [ ('tqn') x 6 ], 'motif';

done_testing();
