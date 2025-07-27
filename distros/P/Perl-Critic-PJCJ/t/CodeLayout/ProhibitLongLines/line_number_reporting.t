#!/usr/bin/env perl

use v5.26.0;
use strict;
use warnings;

use Test2::V0    qw( done_testing is like subtest );
use feature      qw( signatures );
use experimental qw( signatures );

use lib                                                 qw( lib t/lib );
use Perl::Critic::Policy::CodeLayout::ProhibitLongLines ();
use ViolationFinder                                     qw( find_violations );

my $Policy = Perl::Critic::Policy::CodeLayout::ProhibitLongLines->new(
  max_line_length => 72);

sub line_numbers ($code, $expected_lines, $description) {
  my @violations   = find_violations($Policy, $code);
  my @actual_lines = map { $_->line_number } @violations;

  is \@actual_lines, $expected_lines, $description;

  # Check that each violation has the correct message format
  for my $violation (@violations) {
    like $violation->description,
      qr/Line is \d+ characters long \(exceeds 72\)/,
      "Violation on line " . $violation->line_number . " has correct message";
  }

  @violations
}

subtest "POD line number reporting" => sub {
  my $code_with_pod = <<'EOCODE';
#!/usr/bin/env perl

my $var = 1;

=pod

This is a short POD line
This long POD line exceeds the seventy two character limit and triggers a
Another short line

=cut

my $other = 2;
EOCODE

  my @violations = line_numbers($code_with_pod, [8],
    "POD long line should report correct line number");

  # Also check the exact message
  is $violations[0]->description, "Line is 73 characters long (exceeds 72)",
    "POD violation has exact expected message";
};

subtest "Mixed POD and code violations" => sub {
  my $mixed_code = <<'EOCODE';
my $short = 1;
my $very_long_variable_name_that_exceeds_seventy_two_char_limit = "value";

=pod

Short POD line
This long POD line exceeds the seventy two character limit and triggers a

=cut

my $another_very_long_variable_name_that_exceeds_seventy_two_char_limit = "end";
EOCODE

  my @violations = line_numbers(
    $mixed_code,
    [ 2, 7, 11 ],
    "Mixed code and POD violations should report correct line numbers"
  );

  # Check specific messages
  is $violations[0]->description, "Line is 74 characters long (exceeds 72)",
    "First code violation message";
  is $violations[1]->description, "Line is 73 characters long (exceeds 72)",
    "POD violation message";
  is $violations[2]->description, "Line is 80 characters long (exceeds 72)",
    "Second code violation message";
};

subtest "Multiple POD sections" => sub {
  my $multi_pod_code = <<'EOCODE';
my $var = 1;

=pod

This is a long POD line in the first section that exceeds seventy two char

=cut

my $middle = 2;

=head1 SECTION

Another long POD line in the second section that exceeds seventy two char

=cut

my $end = 3;
EOCODE

  line_numbers(
    $multi_pod_code,
    [ 5, 13 ],
    "Multiple POD sections should report correct line numbers"
  );
};

subtest "POD with code snippets" => sub {
  my $pod_with_code = <<'EOCODE';
=pod

=head1 EXAMPLES

  # This code example within POD is long and exceeds seventy two char!!!!
  my $example_variable_with_very_long_name = "this makes line too long!";

=cut
EOCODE

  my @violations = line_numbers(
    $pod_with_code,
    [ 5, 6 ],
    "Long lines within POD code examples should report correct line numbers"
  );

  # Check specific line lengths
  is $violations[0]->description, "Line is 73 characters long (exceeds 72)",
    "First POD code example violation";
  is $violations[1]->description, "Line is 73 characters long (exceeds 72)",
    "Second POD code example violation";
};

subtest "Comment line number reporting edge cases" => sub {
  my $comment_code = <<'EOCODE';
my $var = 1;
# This is a long comment that exceeds the seventy two character limit!!!!
my $other = 2;
EOCODE

  my @violations = line_numbers($comment_code, [2],
    "Comment long lines should report correct line numbers");

  is $violations[0]->description, "Line is 73 characters long (exceeds 72)",
    "Comment violation has correct message";
};

subtest "Empty POD blocks" => sub {
  my $empty_pod_code = <<'EOCODE';
my $var = 1;

=pod

=cut

my $very_long_variable_name_that_exceeds_seventy_two_char_limit_after_pod = "v";
EOCODE

  my @violations = line_numbers($empty_pod_code, [7],
    "Code after empty POD should report correct line numbers");

  is $violations[0]->description, "Line is 80 characters long (exceeds 72)",
    "Line after empty POD has correct violation message";
};

done_testing;
