
use strict;
use warnings;
use Test::More tests => 12;

use_ok 'Perl::Critic::Policy::logicLAB::ProhibitUseLib';

require Perl::Critic;
my $critic = Perl::Critic->new(
    '-profile'       => '',
    '-single-policy' => 'logicLAB::ProhibitUseLib'
);
{
    my @p = $critic->policies;
    is( scalar @p, 1, 'single policy ProhibitUseLib' );

    my $policy = $p[0];
}

foreach my $data (
    [ 1, "use lib qw(/some/where)" ],
    [ 1, "use lib '/some/where/else'" ],
    [ 1, "use lib q{/some/where/else}" ],
    [ 1, "use lib qq{/some/where/else}" ],
    [ 0, "use library '/some/where/else'" ],
    [ 0, "use" ], #to satisfy our branch coverage
    )
{
    my ( $want_count, $str ) = @{$data};

    my @violations = $critic->critique( \$str );
    foreach (@violations) {
        is( $_->description, q{Do not use 'use lib' statements} );
    }
    is( scalar @violations, $want_count, "statement: $str" );
}

exit 0;
