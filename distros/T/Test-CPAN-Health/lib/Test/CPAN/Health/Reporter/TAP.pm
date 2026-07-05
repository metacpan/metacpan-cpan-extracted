package Test::CPAN::Health::Reporter::TAP;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak);
use Params::Validate::Strict qw(validate_strict);
use Scalar::Util qw(blessed);

our $VERSION = '0.1.0';

=head1 NAME

Test::CPAN::Health::Reporter::TAP - Render a health report as TAP output

=head1 SYNOPSIS

    use Test::CPAN::Health::Reporter::TAP;

    my $reporter = Test::CPAN::Health::Reporter::TAP->new;
    print $reporter->render($report);

    # Pipe into a harness:
    # cpan-health --format=tap My-Dist | prove --stdin

=head1 DESCRIPTION

Produces TAP (Test Anything Protocol) output for a
L<Test::CPAN::Health::Report>.  Each check becomes one TAP test line.

  pass    -> ok N - name: summary
  warn    -> ok N - name: summary # WARN
  fail    -> not ok N - name: summary
  error   -> not ok N - name: summary
  skip    -> ok N # SKIP name: reason

The TAP plan (C<1..N>) is printed first.  Detail strings are emitted as
TAP diagnostic lines (C<# detail>).  Overall score and status counts
appear as diagnostics at the end.

=head1 LIMITATIONS

=over 4

=item * The C<warn> status maps to C<ok ... # WARN>.  C<# WARN> is not a
standard TAP directive but is readable and does not break harnesses.

=item * Hash characters (C<#>) in check summaries are replaced with C<[#]>
to avoid confusing TAP parsers that treat C<#> as starting a directive.

=back

=cut

sub new {
	my ($class, %args) = @_;

	%args = %{ validate_strict(
		schema => {},
		input  => \%args,
	) };

	return bless {}, $class;
}

=head2 render

=head3 PURPOSE

Render a Report as a valid TAP document.

=head3 API SPECIFICATION

=head4 INPUT

  report  Test::CPAN::Health::Report  required

=head4 OUTPUT

Scalar string: TAP output ending with a newline.

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
  TAP01 | FATAL    | report must be a Report object     | Pass a Report instance

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  RenderOp
  report : Report
  tap!   : String
  -------------------------------------------------------
  tap! starts with "1.." ++ str(#results)
  valid_tap(tap!)

=head3 SIDE EFFECTS

None.

=head3 USAGE EXAMPLE

    print $reporter->render($report);

=cut

sub render {
	my ($self, $report) = @_;

	croak 'report must be a Test::CPAN::Health::Report'
		unless blessed($report) && $report->isa('Test::CPAN::Health::Report');

	my @results = sort { $a->check_id cmp $b->check_id } @{$report->results};
	my $n       = scalar @results;

	my @lines;
	push @lines, "1..$n";

	my $i = 0;
	for my $result (@results) {
		$i++;

		my $label = ($result->data->{name} // $result->check_id)
			. ': ' . $result->summary;
		$label =~ s/ [#] /[#]/gx;    # '#' is TAP-reserved; replace to avoid parse confusion

		my $line;
		if ($result->is_skip) {
			$line = "ok $i # SKIP $label";
		} elsif ($result->is_pass) {
			$line = "ok $i - $label";
		} elsif ($result->is_warn) {
			$line = "ok $i - $label # WARN";
		} else {
			$line = "not ok $i - $label";
		}

		push @lines, $line;
		push @lines, "# $_" for @{$result->details};
	}

	push @lines, '';
	push @lines, sprintf('# Overall score: %d/100', $report->overall_score);
	push @lines, sprintf('# Passed: %d  Warned: %d  Failed: %d  Skipped: %d',
		$report->pass_count,
		$report->warn_count,
		$report->fail_count,
		$report->skip_count,
	);

	return join("\n", @lines) . "\n";
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025-2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

=cut

1;
