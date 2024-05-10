use Test2::V0 -no_srand => 1;
use Test::Perl::Critic::Policy qw( all_policies_ok );

all_policies_ok( -policies => [ 'Plicease::ProhibitSignaturesAndAtUnderscore' ] );

done_testing
