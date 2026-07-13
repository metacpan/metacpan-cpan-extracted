package ViolationFinder;

use v5.26.0;
use strict;
use warnings;
use feature "signatures";
use experimental "signatures";

use Exporter   qw( import );
use List::Util qw( any );
use PPI        ();
use Test2::V0  qw( diag fail is like );

use Perl::Critic::PJCJ::Fixer ();

our @EXPORT_OK = qw( find_violations count_violations good bad fixes
  unchanged );

my $Fixer = Perl::Critic::PJCJ::Fixer->new;

sub _is_quoting_policy ($policy) {
  ref($policy) =~ /RequireConsistentQuoting/
}

sub find_violations ($policy, $code) {
  my $doc = PPI::Document->new(\$code);
  my @violations;
  my @applies_to = $policy->applies_to;

  # Handle policies that apply to PPI::Document directly
  if (@applies_to == 1 && $applies_to[0] eq "PPI::Document") {
    push @violations, $policy->violates($doc, $doc);
    return @violations;
  }

  # Handle policies that apply to specific element types
  $doc->find(
    sub ($top, $elem) {
      push @violations, $policy->violates($elem, $doc)
        if any { $elem->isa($_) } @applies_to;
      0
    }
  );

  @violations
}

sub count_violations ($policy, $code, $expected_violations, $description) {
  my @violations = find_violations($policy, $code);
  is @violations, $expected_violations, $description;
  @violations
}

sub good ($policy, $code, $description) {
  my @violations = count_violations($policy, $code, 0, $description);
  fail join " --- ", (map $_ // "*undef*", $_->description, $code)
    for @violations;

  is $Fixer->fix($code), $code, "$description - fixer leaves it alone"
    if _is_quoting_policy($policy);
}

sub bad ($policy, $code, $expected_message, $description) {
  my @violations = find_violations($policy, $code);
  is @violations, 1, "$description - should have one violation";
  return unless @violations;

  like $violations[0]->description, qr/\Q$expected_message\E/,
    "$description - should suggest $expected_message";

  if (_is_quoting_policy($policy)) {
    my $fixed     = $Fixer->fix($code);
    my @remaining = find_violations($policy, $fixed);
    is @remaining, 0, "$description - fixer resolves the violation"
      or diag "fixed source: $fixed";
  }
}

sub fixes ($in, $out, $desc) {
  is $Fixer->fix($in), $out, $desc;
}

sub unchanged ($in, $desc) {
  is $Fixer->fix($in), $in, $desc;
}

"
How I'm moved
How you move me
"

__END__

=head1 NAME

ViolationFinder - Test utility for finding Perl::Critic policy violations

=head1 SYNOPSIS

  use ViolationFinder qw( find_violations count_violations good bad );

  # Find all violations for a policy
  my @violations = find_violations $policy, $code;

  # Test that code has expected number of violations
  count_violations $policy, $code, 3, "should find 3 violations";

  # Test that code has no violations
  good $policy, $code, "valid code should not violate policy";

  # Test that code has exactly one violation with expected message
  bad $policy, $code, "expected message", "invalid code should violate";

=head1 DESCRIPTION

ViolationFinder provides utility functions for testing Perl::Critic policies.
It simplifies the process of checking whether code violates specific policies
and validating the violation messages.

=head1 FUNCTIONS

=head2 find_violations

  my @violations = find_violations $policy, $code;

Finds all violations of a given Perl::Critic policy in the provided code.

Parameters:

=over 4

=item * C<$policy> - A Perl::Critic policy object

=item * C<$code> - Perl source code as a string

=back

Returns a list of violation objects.

=head2 count_violations

  my @violations = count_violations$policy, $code, $expected_violations, $desc;

Tests that code has the expected number of violations for a given policy.

Parameters:

=over 4

=item * C<$policy> - A Perl::Critic policy object

=item * C<$code> - Perl source code as a string

=item * C<$expected_violations> - Number of expected violations

=item * C<$desc> - Test description for the assertion

=back

Returns the list of violations found.

=head2 good

  good $policy, $code, $description;

Tests that code has no violations for a given policy.

Parameters:

=over 4

=item * C<$policy> - A Perl::Critic policy object

=item * C<$code> - Perl source code as a string

=item * C<$description> - Test description for the assertion

=back

This is a convenience function that verifies the code passes the policy check.
For the RequireConsistentQuoting policy it also asserts that
L<Perl::Critic::PJCJ::Fixer> leaves the code unchanged.

=head2 bad

  bad $policy, $code, $expected_message, $description;

Tests that code has exactly one violation with an expected message.

Parameters:

=over 4

=item * C<$policy> - A Perl::Critic policy object

=item * C<$code> - Perl source code as a string

=item * C<$expected_message> - Expected text in the violation message

=item * C<$description> - Test description for the assertion

=back

This function verifies that the code violates the policy exactly once and that
the violation's description contains the expected text. For the
RequireConsistentQuoting policy it also asserts that
L<Perl::Critic::PJCJ::Fixer> resolves the violation.

=head2 fixes

  fixes $code, $expected, $description;

Tests that L<Perl::Critic::PJCJ::Fixer> rewrites C<$code> to C<$expected>.

=head2 unchanged

  unchanged $code, $description;

Tests that L<Perl::Critic::PJCJ::Fixer> leaves C<$code> unchanged.

=head1 AUTHOR

Paul Johnson, E<lt>paul@pjcj.netE<gt>

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
