use strict;
use warnings;

use Test::More;
use Perl::Critic::TestUtils qw(pcritique);

my $switch_statements_without_CORE = <<'__CODE__';
my $foo;
given ($foo) {
    when (42) { say 'Heureka!' }
    default { die 'No!' }
}
__CODE__

is(
    pcritique(
        'ControlStructures::ProhibitSwitchStatements',
        \$switch_statements_without_CORE
    ),
    3
);

my $switch_statements_with_CORE = <<'__CODE__';
my $foo;
CORE::given ($foo) {
    CORE::when (42) { say 'Heureka!' }
    CORE::default { die 'No!' }
}
__CODE__

is(
    pcritique(
        'ControlStructures::ProhibitSwitchStatements',
        \$switch_statements_with_CORE
    ),
    3
);

done_testing;
