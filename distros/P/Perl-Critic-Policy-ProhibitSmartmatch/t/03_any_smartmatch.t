use strict;
use warnings;

use Test::More;
use Perl::Critic::TestUtils qw(pcritique);

my $code = <<'__CODE__';
if ($foo ~~ [ $bar ]) {
    say 'No!';
}

given ($foo) {
    when (42) { say 'Heureka!' }
    default { die 'No!' }
}

CORE::given ($foo) {
    CORE::when (42) { say 'Heureka!' }
    CORE::default { die 'No!' }
}
__CODE__

is( pcritique( 'ProhibitSmartmatch', \$code ), 7 );

done_testing;
