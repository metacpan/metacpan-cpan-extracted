use strict;
use Test::More;
use Perl::Critic::TestUtils qw( pcritique_with_violations );
use Perl::Critic::Utils qw{ :severities };

my $policy = 'Perl::Critic::Policy::CognitiveComplexity::ProhibitExcessCognitiveComplexity';

### example 2
my $code = <<'END_CODE';

sub sumOfPrimes {
    my ($max) = @_;
    my $total = 0;
    OUT: for (my $i = 1; $i <= $max; ++$i) {
        for (my $j = 2; $j < $i; ++$j) {
            if ($i % $j == 0) {
                 next OUT;
            }
        }
        $total += $i;
    }
    return $total;
}

END_CODE
my @violations = pcritique_with_violations( $policy, \$code );
is(scalar @violations, 1, 'Found 1 violation');

my $violation = $violations[0];
is($violation->severity(), $SEVERITY_LOWEST, 'sumOfPrimes: Violation is info-level');
is($violation->description(), q{Subroutine 'sumOfPrimes' with complexity score of '7'}, 'sumOfPrimes: Violation description');


done_testing();
