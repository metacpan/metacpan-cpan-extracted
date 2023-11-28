#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Music::Duration::Partition';

my $mdp;

subtest throws => sub {
    throws_ok { Music::Duration::Partition->new( pool => [] ) }
        qr/Empty pool not allowed/, 'empty pool';

    $mdp = new_ok 'Music::Duration::Partition' => [
        pool    => [qw/ hn qn /],
        weights => [ 1, 1, 1 ],
    ];
    throws_ok { $mdp->motif }
        qr/weights and pool not equal/,
        'wrong pool weight';
};

subtest defaults => sub {
    $mdp = new_ok 'Music::Duration::Partition';
    ok ref($mdp->_durations) eq 'HASH', '_durations';
    is $mdp->size, 4, 'size';
    is_deeply $mdp->pool, [ keys %MIDI::Simple::Length ], 'pool';
};

subtest motif => sub {
    subtest pool => sub {
        $mdp = new_ok 'Music::Duration::Partition' => [ pool => [qw/ wn /] ];
        is_deeply $mdp->motif, ['wn'], 'motif';

        $mdp = new_ok 'Music::Duration::Partition' => [ pool => [qw/ qn /] ];
        is_deeply $mdp->motif, [ ('qn') x 4 ], 'motif';

        $mdp = new_ok 'Music::Duration::Partition' => [ pool => [qw/ tqn /] ];
        is_deeply $mdp->motif, [ ('tqn') x 6 ], 'motif';
    };

    subtest size => sub {
        $mdp = new_ok 'Music::Duration::Partition' => [
            size => 8,
            pool => [qw/ wn /]
        ];
        is_deeply $mdp->motif, [qw/ wn wn /], 'motif';

        $mdp = new_ok 'Music::Duration::Partition' => [
            size => 100,
            pool => ['d50']
        ];
        is_deeply $mdp->motif, [qw/ d50 d50 /], 'motif';
    };

    subtest pool_select => sub {
      $mdp = new_ok 'Music::Duration::Partition' => [
          pool        => [qw/ qn tqn /],
          pool_select => sub { my $self = shift; return $self->pool->[0] }
      ];
      is_deeply $mdp->motif, [ ('qn') x 4 ], 'motif';
      $mdp->pool_select( sub { return $mdp->pool->[-1] } );
      is_deeply $mdp->motif, [ ('tqn') x 6 ], 'motif';
    };

    subtest weights => sub {
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
    };

    subtest remainder => sub {
        $mdp = new_ok 'Music::Duration::Partition' => [ pool => [qw/ dhn /] ];
        is_deeply $mdp->motif, [qw/ dhn d96 /], 'remainder';
    };
};

subtest motifs => sub {
    $mdp = new_ok 'Music::Duration::Partition' => [ pool => [qw/ wn /] ];
    is_deeply [ $mdp->motifs(2) ], [ ['wn'],['wn'] ], 'motifs';
};

done_testing();
