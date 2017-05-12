
use strict;
use warnings;

use Perl::Critic::TestUtils qw(pcritique_with_violations);
use Test::More;

my $offend = "This line offends the policy maker" x 5;

my $code = <<"EOF";
my \$line_one = "This is line 1";

=head1 Offending

$offend

=cut

EOF

plan tests => 5;

my $policy = 'Tics::ProhibitLongLines';

my @violations = pcritique_with_violations( $policy, \$code );

is( scalar @violations, 1,
    '$code is no good (' . @violations . ' violations)' );

my $v = shift @violations;

is( $v->line_number,         5, "violation on line 5" );
is( $v->logical_line_number, 5, "violation on logical line 5" );

Perl::Critic::Violation::set_format('%m near \'%r\'');

unlike $v->to_string, qr/line 1/,
  'near context does not show context from line 1';

like $v->to_string, qr/the policy maker/,
  'near context shows the offending line';

