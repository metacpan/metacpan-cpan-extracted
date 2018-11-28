use strict;
use warnings;
use Test::More qw(no_plan);

use_ok 'Perl::Critic::Policy::RegularExpressions::RequireDefault';

require Perl::Critic;
my $critic = Perl::Critic->new(
    '-profile'       => '',
    '-single-policy' => 'RegularExpressions::RequireDefault'
);
{
    my @p = $critic->policies;
    is( scalar @p, 1, 'single policy RegularExpressions::RequireDefault' );

    my $policy = $p[0];
}

foreach my $data (
    [ 1, q{/\d/}, q{Regular expression without "/a" or "/aa" flag} ],
    [ 0, q{/\d/a}, q{} ],
    [ 0, q{/\d/aa}, q{} ],
    )
{
    my ( $want_count, $str, $assertion ) = @{$data};

    my @violations = $critic->critique( \$str );
    foreach (@violations) {
        is( $_->description, $assertion, "violation: $assertion" );
    }
    is( scalar @violations, $want_count, "statement: $str" );
}

exit 0;
