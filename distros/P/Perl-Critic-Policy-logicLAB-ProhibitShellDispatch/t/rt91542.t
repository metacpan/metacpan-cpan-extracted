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

my $str = q[$startSSH-> system( {async => 1} , "$setRemoteProfile $patCmd 1> /dev/null" );];

my @violations = $critic->critique( \$str );

is(scalar @violations, 0, "We have a violation");

exit 0;
