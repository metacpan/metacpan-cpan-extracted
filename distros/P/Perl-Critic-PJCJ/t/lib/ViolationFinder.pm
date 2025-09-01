package ViolationFinder;

use v5.26.0;
use strict;
use warnings;

use Exporter     qw( import );
use PPI          ();
use Test2::V0    qw( fail is like );
use feature      qw( signatures );
use experimental qw( signatures );

our @EXPORT_OK = qw( find_violations count_violations good bad );

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
  for my $type (@applies_to) {
    $doc->find(
      sub ($top, $elem) {
        push @violations, $policy->violates($elem, $doc) if $elem->isa($type);
        0
      }
    );
  }

  @violations
}

sub count_violations ($policy, $code, $expected_violations, $description) {
  my @violations = find_violations($policy, $code);
  is @violations, $expected_violations, $description;
  @violations
}

sub good ($policy, $code, $description) {
  my @violations = count_violations($policy, $code, 0, $description);
  my $field
    = ref($policy) =~ /RequireConsistentQuoting/
    ? "explanation"
    : "description";
  fail join " --- ", (map $_ // "*undef*", $_->$field, $code) for @violations;
}

sub bad ($policy, $code, $expected_message, $description) {
  my @violations = find_violations($policy, $code);
  is @violations, 1, "$description - should have one violation";
  return unless @violations;

  # For quoting policies, check explanation instead of description
  my $field
    = ref($policy) =~ /RequireConsistentQuoting/
    ? "explanation"
    : "description";
  like $violations[0]->$field, qr/\Q$expected_message\E/,
    "$description - should suggest $expected_message";
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
the violation message contains the expected text. For most policies, it checks
the description field. For the RequireConsistentQuoting policy, it checks the
explanation field instead.

=head1 AUTHOR

Paul Johnson, E<lt>paul@pjcj.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
