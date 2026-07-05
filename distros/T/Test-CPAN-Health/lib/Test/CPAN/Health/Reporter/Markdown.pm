package Test::CPAN::Health::Reporter::Markdown;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak);
use Readonly;
use Params::Validate::Strict qw(validate_strict);
use Scalar::Util qw(blessed);

our $VERSION = '0.1.0';

# Glyphs -- Unicode escape sequences keep the source file strictly ASCII while
# producing the expected UTF-8 glyphs at runtime.
Readonly::Scalar my $GLYPH_PASS  => "\x{2705}";   # U+2705 CHECK MARK BUTTON
Readonly::Scalar my $GLYPH_WARN  => "\x{26A0}";   # U+26A0 WARNING SIGN
Readonly::Scalar my $GLYPH_FAIL  => "\x{2717}";   # U+2717 BALLOT X
Readonly::Scalar my $GLYPH_SKIP  => "\x{2014}";   # U+2014 EM DASH
Readonly::Scalar my $GLYPH_ERROR => "\x{2049}";   # U+2049 EXCLAMATION QUESTION MARK

Readonly::Hash my %STATUS_GLYPH => (
	pass  => $GLYPH_PASS,
	warn  => $GLYPH_WARN,
	fail  => $GLYPH_FAIL,
	skip  => $GLYPH_SKIP,
	error => $GLYPH_ERROR,
);

# Score thresholds for badge colour selection.
Readonly::Scalar my $SCORE_GREAT => 90;
Readonly::Scalar my $SCORE_OK    => 70;

=head1 NAME

Test::CPAN::Health::Reporter::Markdown - Render a health report as GitHub-Flavoured Markdown

=head1 SYNOPSIS

    use Test::CPAN::Health::Reporter::Markdown;

    my $reporter = Test::CPAN::Health::Reporter::Markdown->new;
    my $md = $reporter->render($report);
    print $md;

=head1 DESCRIPTION

Produces GitHub-Flavoured Markdown from a L<Test::CPAN::Health::Report>.
The output is suitable for PR comments, README badge sections, or wiki pages.

The document includes a header, a weighted score line with an emoji badge,
a summary counts line, a Markdown results table, collapsible detail blocks
for warn/fail/error results, and a trailing shields.io badge URL comment.

=head1 LIMITATIONS

=over 4

=item * Pipe characters and backslashes in check summaries are escaped for
GFM table compatibility; other Markdown metacharacters are not escaped.

=item * Detail strings are rendered verbatim inside C<< <details> >> blocks;
HTML embedded in detail strings is not escaped.

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

Render a Report to a GitHub-Flavoured Markdown string.

=head3 API SPECIFICATION

=head4 INPUT

  report  Test::CPAN::Health::Report  required

=head4 OUTPUT

Scalar string (UTF-8).  Ends with a trailing newline.

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
  MDR01 | FATAL    | report must be a Report object     | Pass a Report instance

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  RenderOp
  report  : Report
  output  : String
  -------------------------------------------------------
  #output > 0
  output contains report.overall_score

=head3 SIDE EFFECTS

None.

=head3 USAGE EXAMPLE

    my $md = $reporter->render($report);
    print $md;

=cut

sub render {
	my ($self, $report) = @_;

	croak 'report must be a Test::CPAN::Health::Report'
		unless blessed($report) && $report->isa('Test::CPAN::Health::Report');

	my $score = $report->overall_score;

	my $score_badge = $score >= $SCORE_GREAT ? $GLYPH_PASS
		            : $score >= $SCORE_OK    ? $GLYPH_WARN
		            :                          $GLYPH_FAIL;

	my $badge_color = $score >= $SCORE_GREAT ? 'brightgreen'
		            : $score >= $SCORE_OK    ? 'yellow'
		            :                          'red';

	my @lines;

	# 1. Header
	push @lines, '## CPAN Health Report';
	push @lines, '';

	# 2. Score line
	push @lines, sprintf( '**Overall score: %d/100** %s', $score, $score_badge );
	push @lines, '';

	# 3. Summary counts
	push @lines, sprintf(
		'Passed: %d | Warned: %d | Failed: %d | Skipped: %d',
		$report->pass_count,
		$report->warn_count,
		$report->fail_count,
		$report->skip_count,
	);
	push @lines, '';

	# 4. Results table
	push @lines, '| Status | Check | Score | Summary |';
	push @lines, '|--------|-------|-------|---------|';

	my @results = sort { $a->check_id cmp $b->check_id } @{ $report->results };
	for my $result (@results) {
		push @lines, $self->_render_table_row($result);
	}
	push @lines, '';

	# 5. Collapsible detail blocks for warn / fail / error results with details.
	for my $result (@results) {
		my $status = $result->status;
		next unless $status eq 'warn' || $status eq 'fail' || $status eq 'error';
		next unless @{ $result->details };
		push @lines, $self->_render_details_block($result);
	}

	# 6. Footer: shields.io badge URL as an HTML comment.
	push @lines, sprintf(
		'<!-- badge: https://img.shields.io/badge/cpan--health-%d%%2F100-%s?style=flat-square -->',
		$score,
		$badge_color,
	);

	return join( "\n", @lines ) . "\n";
}

# ---------------------------------------------------------------------------
# Private rendering helpers
# ---------------------------------------------------------------------------

sub _render_table_row {
	my ($self, $result) = @_;

	my $status  = $result->status;
	my $glyph   = $STATUS_GLYPH{$status} // '?';
	my $name    = _esc_md( $result->data->{name} // $result->check_id );
	my $score   = defined $result->score
		? $result->score . '/100'
		: $GLYPH_SKIP;
	my $summary = _esc_md( $result->summary );

	return sprintf( '| %s | %s | %s | %s |', $glyph, $name, $score, $summary );
}

sub _render_details_block {
	my ($self, $result) = @_;

	my $status = $result->status;
	my $glyph  = $STATUS_GLYPH{$status} // '?';
	my $name   = $result->data->{name} // $result->check_id;

	my @lines;
	push @lines, '<details>';
	push @lines, sprintf( '<summary>%s %s details</summary>', $glyph, $name );
	push @lines, '';
	for my $detail ( @{ $result->details } ) {
		push @lines, '- ' . $detail;
	}
	push @lines, '';
	push @lines, '</details>';
	push @lines, '';

	return @lines;
}

# Escape GFM table cell special characters.
# Backslash must be escaped before pipe so the escaping backslash is not
# itself subsequently escaped.
sub _esc_md {
	my ($str) = @_;
	return '' unless defined $str;
	$str =~ s/ [\\] /\\\\/gx;
	$str =~ s/ [|] /\\|/gx;
	return $str;
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
