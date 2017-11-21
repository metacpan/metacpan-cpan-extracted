use strict;
use warnings;

use Test::More;
use Perl::Critic::TestUtils qw(pcritique);

my $code = <<'__CODE__';
if ($foo ~~ [ $bar ]) {
    say 'No!';
}
__CODE__

is( pcritique( 'Operators::ProhibitSmartmatch', \$code ), 1 );

done_testing;
