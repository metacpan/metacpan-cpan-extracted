package Test::CPAN::Health::Reporter::Terminal;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak);
use Readonly;
use Term::ANSIColor qw(colored);
use Params::Validate::Strict qw(validate_strict);
use Scalar::Util qw(blessed);

our $VERSION = '0.1.0';

# Glyphs -- defined as named constants to keep them out of logic code.
# Using Unicode escape sequences keeps the source file strictly ASCII while
# producing the expected UTF-8 glyphs at runtime.
Readonly::Scalar my $GLYPH_PASS  => "\x{2713}";   # U+2713 CHECK MARK
Readonly::Scalar my $GLYPH_WARN  => "\x{26A0}";   # U+26A0 WARNING SIGN
Readonly::Scalar my $GLYPH_FAIL  => "\x{2717}";   # U+2717 BALLOT X
Readonly::Scalar my $GLYPH_SKIP  => "\x{2014}";   # U+2014 EM DASH
Readonly::Scalar my $GLYPH_ERROR => "\x{2049}";   # U+2049 EXCLAMATION QUESTION MARK

# ANSI colour map per status
Readonly::Hash my %STATUS_COLOUR => (
	pass  => 'bold green',
	warn  => 'bold yellow',
	fail  => 'bold red',
	skip  => 'dark',
	error => 'bold magenta',
);

Readonly::Hash my %STATUS_GLYPH => (
	pass  => $GLYPH_PASS,
	warn  => $GLYPH_WARN,
	fail  => $GLYPH_FAIL,
	skip  => $GLYPH_SKIP,
	error => $GLYPH_ERROR,
);

=head1 NAME

Test::CPAN::Health::Reporter::Terminal - Render a health report as coloured terminal output

=head1 SYNOPSIS

    use Test::CPAN::Health::Reporter::Terminal;

    my $reporter = Test::CPAN::Health::Reporter::Terminal->new;
    print $reporter->render($report);

=head1 DESCRIPTION

Produces a human-readable, ANSI-coloured summary of a
L<Test::CPAN::Health::Report> for display in a terminal.  Each check result
is rendered on a single line with a status glyph, the check name, and the
per-check score.  Detail lines are indented beneath failing and warning
results.  An overall score and pass/warn/fail summary is printed at the end.

Colour can be disabled by setting C<< colour => 0 >> in the constructor,
or automatically when the C<NO_COLOR> environment variable is set (see
https://no-color.org) or when STDOUT is not a terminal.

=head1 LIMITATIONS

=over 4

=item * Long detail lines are not wrapped; the caller must ensure terminal
width is accounted for in test output if needed.

=back

=cut

sub new {
	my ($class, %args) = @_;

	%args = %{ validate_strict(
		schema => {
			colour  => { type => 'scalar', optional => 1 },
			verbose => { type => 'scalar', optional => 1, default => 0 },
		},
		input => \%args,
	) };

	# Honour NO_COLOR convention and isatty; explicit colour => 0 overrides.
	my $colour = $args{colour}
		// ($ENV{NO_COLOR} || !( -t STDOUT ) ? 0 : 1);  ## no critic (ProhibitInteractiveTest)

	my $self = bless {
		_colour  => $colour,
		_verbose => $args{verbose},
	}, $class;

	return $self;
}

=head2 render

=head3 PURPOSE

Render a Report to an ANSI-coloured string.

=head3 API SPECIFICATION

=head4 INPUT

  report  Test::CPAN::Health::Report  required

=head4 OUTPUT

Scalar string (UTF-8).  Does not include a trailing newline on the last line.

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
  TRM01 | FATAL    | report must be a Report object     | Pass a Report instance

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  RenderOp
  report  : Report
  output  : String
  -------------------------------------------------------
  #output > 0

=head3 SIDE EFFECTS

None.

=head3 USAGE EXAMPLE

    print $reporter->render($report);

=cut

sub render {
	my ($self, $report) = @_;

	croak 'report must be a Test::CPAN::Health::Report'
		unless blessed($report) && $report->isa('Test::CPAN::Health::Report');

	my @lines;

	for my $result (sort { $a->check_id cmp $b->check_id } @{$report->results}) {
		push @lines, $self->_render_result($result);
	}

	push @lines, '';
	push @lines, $self->_render_summary($report);

	return join("\n", @lines);
}

# ---------------------------------------------------------------------------
# Private rendering helpers
# ---------------------------------------------------------------------------

sub _render_result {
	my ($self, $result) = @_;

	my $status = $result->status;
	my $glyph  = $STATUS_GLYPH{$status} // '?';
	my $colour = $STATUS_COLOUR{$status} // 'reset';

	my $score_str = defined $result->score
		? sprintf(' (%d/100)', $result->score)
		: '';

	my $line = sprintf('%s  %-30s %s%s',
		$glyph,
		$result->data->{name} // $result->check_id,
		$result->summary,
		$score_str,
	);

	$line = $self->_colour($colour, $line) if $self->{_colour};

	my @lines = ($line);

	# Only expand details for warn/fail/error, or always in verbose mode.
	if ($self->{_verbose} || $status eq 'fail' || $status eq 'warn' || $status eq 'error') {
		for my $detail (@{$result->details}) {
			my $detail_line = "      $detail";
			$detail_line = $self->_colour('faint', $detail_line) if $self->{_colour};
			push @lines, $detail_line;
		}

		if ($result->url) {
			my $url_line = "      " . $result->url;
			$url_line = $self->_colour('faint', $url_line) if $self->{_colour};
			push @lines, $url_line;
		}
	}

	return @lines;
}

sub _render_summary {
	my ($self, $report) = @_;

	my $score    = $report->overall_score;
	my $score_colour = $score >= 90 ? 'bold green'
		           : $score >= 70   ? 'bold yellow'
		           :                  'bold red';

	my $score_str = sprintf('Overall score: %d/100', $score);
	$score_str = $self->_colour($score_colour, $score_str) if $self->{_colour};

	my $counts = sprintf(
		'Passed: %d  Warned: %d  Failed: %d  Skipped: %d',
		$report->pass_count,
		$report->warn_count,
		$report->fail_count,
		$report->skip_count,
	);

	return ($score_str, $counts);
}

# Wrapper that degrades gracefully when colour is disabled.
sub _colour {
	my ($self, $attr, $text) = @_;

	return $text unless $self->{_colour};

	return colored($text, $attr);
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
