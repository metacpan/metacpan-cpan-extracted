use strict;
use Test::More;
use Perl::Critic::TestUtils qw( pcritique_with_violations );
use Perl::Critic::Utils qw{ :severities };

my $policy = 'Perl::Critic::Policy::CognitiveComplexity::ProhibitExcessCognitiveComplexity';

my $code = <<'END_CODE';
use experimental qw(switch);
                                # Cyclomatic Complexity    Cognitive Complexity

sub getWords {                  #          +1
    my ($number) = @_;
    given ($number) {           #                                  +1
      when (1)                  #          +1
        { return "one"; }
      when (2)                  #          +1
        { return "a couple"; }
      default                   #          +1
        { return "lots"; }
    }
}                               #          =4                      =1
END_CODE
my @violations = pcritique_with_violations( $policy, \$code );
is(scalar @violations, 1, 'Found 1 violation');

my $violation = $violations[0];
is($violation->severity(), $SEVERITY_LOWEST, 'getWords: Violation is info-level');
is($violation->description(), q{Subroutine 'getWords' with complexity score of '1'}, 'getWords: Violation description');

done_testing();