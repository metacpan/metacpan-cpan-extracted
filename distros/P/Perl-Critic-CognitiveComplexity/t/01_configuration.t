use strict;
use Test::More;
use Perl::Critic::TestUtils qw( pcritique_with_violations );
use Perl::Critic::Utils qw{ :severities };

my $policy = 'Perl::Critic::Policy::CognitiveComplexity::ProhibitExcessCognitiveComplexity';

### policy warn_level configuration check
my $perl_critic_config = { 'warn_level' => 1 };
my $code = <<'END_CODE';
sub a {
    if (1) {}
}
END_CODE
my @violations = pcritique_with_violations( $policy, \$code, $perl_critic_config );
is(scalar @violations, 1, 'Found 1 violation');
my $violation = $violations[0];
is($violation->severity(), $SEVERITY_MEDIUM, 'a: Violation is warn-level');

### policy info_level configuration check (same code)
$perl_critic_config = { 'info_level' => 5 };
@violations = pcritique_with_violations( $policy, \$code, $perl_critic_config );
is(scalar @violations, 0, 'Found no violation');

done_testing();
