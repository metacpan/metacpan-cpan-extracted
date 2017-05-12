use strict;
use warnings;

use Perl::Critic::TestUtils qw( pcritique );
use Test::More;

my @ok = (
    q{nstore \%table, 'file';},
    q{Storable::nstore \%table, 'file';},
    q{$serialized = nfreeze \%table;},
    q{$serialized = Storable::nfreeze \%table;},
    q{lock_nstore \%table, 'file';},
    q{Storable::lock_nstore \%table, 'file';},
);

my @not_ok = (
    q{store \%table, 'file';},
    q{Storable::store \%table, 'file';},
    q{$serialized = freeze \%table;},
    q{$serialized = Storable::freeze \%table;},
    q{lock_store \%table, 'file';},
    q{Storable::lock_store \%table, 'file';},
);

plan tests => @ok + @not_ok;

my $policy = 'Storable::ProhibitStoreOrFreeze';

for my $i ( 0 .. $#ok ) {
    my $violation_count = pcritique( $policy, \$ok[$i] );
    is( $violation_count, 0, "nothing wrong with $ok[$i]" );
}

for my $i ( 0 .. $#not_ok ) {
    my $violation_count = pcritique( $policy, \$not_ok[$i] );
    is( $violation_count, 1, "$not_ok[$i] is no good" );
}
