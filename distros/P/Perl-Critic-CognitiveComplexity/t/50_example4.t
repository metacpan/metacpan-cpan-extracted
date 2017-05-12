use strict;
use Test::More;
use Perl::Critic::TestUtils qw( pcritique_with_violations );
use Perl::Critic::Utils qw{ :severities };

my $policy = 'Perl::Critic::Policy::CognitiveComplexity::ProhibitExcessCognitiveComplexity';

### example 4
my $code = <<'END_CODE';

sub myMethod2 {
    my $a = 0 if (1 > 2);
    $a = 1 if (2 > 3);
    $a = 2 if (3 > 4);
    $a = 3 if (4 > 5);
}

END_CODE
my @violations = pcritique_with_violations( $policy, \$code );
is(scalar @violations, 1, 'Found 1 violation');

my $violation = $violations[0];
is($violation->severity(), $SEVERITY_LOWEST, 'myMethod2: Violation is info-level');
is($violation->description(), q{Subroutine 'myMethod2' with complexity score of '4'}, 'myMethod2: Violation description');


done_testing();
