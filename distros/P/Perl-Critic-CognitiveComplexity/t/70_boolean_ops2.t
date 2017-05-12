use strict;
use Test::More;
use Perl::Critic::TestUtils qw( pcritique_with_violations );
use Perl::Critic::Utils qw{ :severities };

my $policy = 'Perl::Critic::Policy::CognitiveComplexity::ProhibitExcessCognitiveComplexity';

my $code = <<'END_CODE';

sub boolMethod2 {
    if(
    $a && $b && $c ||
    $d && $e) {}
}

END_CODE
my @violations = pcritique_with_violations( $policy, \$code );
is(scalar @violations, 1, 'Found 1 violation');

my $violation = $violations[0];
is($violation->description(), q{Subroutine 'boolMethod2' with complexity score of '4'}, 'boolMethod2: Violation description');

done_testing();
