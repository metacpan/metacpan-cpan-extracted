use strict;
use Test::More;
use Perl::Critic::TestUtils qw( pcritique_with_violations );
use Perl::Critic::Utils qw{ :severities };

my $policy = 'Perl::Critic::Policy::CognitiveComplexity::ProhibitExcessCognitiveComplexity';

### example 3
my $code = <<'END_CODE';

sub myMethod2 {
    sub {
        if(1) {
            return;
        }
    }->();
}

END_CODE
my @violations = pcritique_with_violations( $policy, \$code );
is(scalar @violations, 1, 'Found 1 violation');

my $violation = $violations[0];
is($violation->severity(), $SEVERITY_LOWEST, 'myMethod2: Violation is info-level');
is($violation->description(), q{Subroutine 'myMethod2' with complexity score of '2'}, 'myMethod2: Violation description');


done_testing();
