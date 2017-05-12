use strict;
use Test::More;
use Perl::Critic::TestUtils qw( pcritique );

my $policy = 'Perl::Critic::Policy::CognitiveComplexity::ProhibitExcessCognitiveComplexity';

### simple check

my $code = <<'END_CODE';
sub a { }
END_CODE
my $violation_count = pcritique( $policy, \$code );
is( $violation_count, 0, 'No violation' );

done_testing();
