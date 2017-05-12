use strict;
use warnings;
use Test::More qw(no_plan);

use_ok 'Perl::Critic::Policy::logicLAB::ProhibitShellDispatch';

require Perl::Critic;
my $critic = Perl::Critic->new(
    '-profile'       => '',
    '-single-policy' => 'logicLAB::ProhibitShellDispatch'
);
{
    my @p = $critic->policies;
    is( scalar @p, 1, 'single policy ProhibitShellDispatch' );

    my $policy = $p[0];
}

foreach my $data (
    [ 1, q{system "ls"}, q{Do not use 'system' or 'exec' statements} ],
    [ 1, q{qx/ls/}, q{Do not use 'qx' statements} ],
    [ 1, '`ls`', q{Do not use 'backticks' statements} ],
    [ 1, q{exec "ls"}, q{Do not use 'system' or 'exec' statements} ],
    [ 0, q{print "Hello World\n"}, q{'Hello World'} ],
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
