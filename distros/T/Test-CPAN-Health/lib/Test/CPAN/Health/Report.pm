package Test::CPAN::Health::Report;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use List::Util qw(sum0);
use Readonly;
use Params::Validate::Strict qw(validate_strict);
use Scalar::Util qw(blessed);

our $VERSION = '0.1.0';

# Hard ceilings: a critical check failure caps the overall score to prevent a
# dist with known CVEs or widespread test failures from scoring 90+.
Readonly::Hash my %HARD_CAPS => (
	security_advisories => 60,
	cpan_testers        => 75,
);

Readonly::Scalar my $MAX_SCORE => 100;
Readonly::Scalar my $MIN_SCORE => 0;

=head1 NAME

Test::CPAN::Health::Report - Aggregated results and overall score for a distribution health run

=head1 SYNOPSIS

    use Test::CPAN::Health::Report;

    my $report = Test::CPAN::Health::Report->new(checks => \@check_objects);

    $report->add_result($result);

    printf "Score: %d/100\n", $report->overall_score;

    for my $result (@{ $report->results }) {
        printf "  %s: %s\n", $result->check_id, $result->status;
    }

=head1 DESCRIPTION

Holds all L<Test::CPAN::Health::Result> objects produced by a run and
computes the weighted overall score.

The scoring formula is a weighted mean of per-check scores:

    score = sum(result.score * check.weight)
            ---------------------------------
            sum(check.weight)

    for all results where score is defined and status is not 'skip'

Hard caps are applied after the weighted mean: if the C<SecurityAdvisories>
check fails, the overall score is capped at 60; if C<CPANTesters> fails,
it is capped at 75.  This prevents a distribution with known CVEs or a
poor CI pass rate from achieving a misleadingly high headline score.

=head1 LIMITATIONS

=over 4

=item * Checks added after C<overall_score> has been called are included on
the next call (the score is computed lazily and cached until invalidated by
C<add_result>).

=back

=cut

sub new {
	my ($class, %args) = @_;

	%args = %{ validate_strict(
		schema => {
			checks => { type => 'arrayref', optional => 1, default => [] },
		},
		input => \%args,
	) };

	# Build a weight map keyed by check id for O(1) lookup during scoring.
	my %weight_for;
	for my $check (@{$args{checks}}) {
		$weight_for{ $check->id } = $check->weight;
	}

	my $self = bless {
		_results        => [],
		_weight_for     => \%weight_for,
		_cached_score   => undef,
		_score_dirty    => 1,
	}, $class;

	return $self;
}

=head2 add_result

=head3 PURPOSE

Append a single Result to the report and invalidate the cached score.

=head3 API SPECIFICATION

=head4 INPUT

  result  Test::CPAN::Health::Result  required

=head4 OUTPUT

Returns C<$self> to allow chaining.

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
  RPT01 | FATAL    | result must be a Result object     | Pass a Result instance

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  AddResultOp
  Report
  Report'
  result? : Result
  -------------------------------------------------------
  Report'.results = Report.results ++ [result?]
  Report'.score_dirty = true

=head3 SIDE EFFECTS

Invalidates the cached overall score.

=head3 USAGE EXAMPLE

    $report->add_result($result)->add_result($other_result);

=cut

sub add_result {
	my ($self, $result) = @_;

	croak 'result must be a Test::CPAN::Health::Result'
		unless blessed($result) && $result->isa('Test::CPAN::Health::Result');

	push @{$self->{_results}}, $result;
	$self->{_score_dirty}  = 1;
	$self->{_cached_score} = undef;

	return $self;
}

=head2 overall_score

=head3 PURPOSE

Compute and return the weighted overall health score in the range 0..100.
The result is cached until C<add_result> invalidates it.

Hard caps are applied last: a failing SecurityAdvisories caps the score at
60; a failing CPANTesters caps it at 75.  Both caps may apply simultaneously
(the lower cap wins).

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

Integer in the range 0..100.

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
        |          |                                    |

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  OverallScoreOp
  results : seq Result
  weights : check_id --> N1
  score   : 0..100
  -------------------------------------------------------
  let scorable == {r : results | r.score /= undefined /\ r.status /= skip}
  score = floor(sum{r : scorable @ r.score * weights(r.check_id)}
               / sum{r : scorable @ weights(r.check_id)})
  security_advisories_fail => score <= 60
  cpan_testers_fail        => score <= 75

=head3 SIDE EFFECTS

None.

=head3 USAGE EXAMPLE

    printf "%d/100\n", $report->overall_score;

=cut

sub overall_score {
	my ($self) = @_;

	return $self->{_cached_score} unless $self->{_score_dirty};

	my ($weighted_sum, $total_weight) = (0, 0);
	my $cap = $MAX_SCORE;

	for my $result (@{$self->{_results}}) {
		next if $result->is_skip;

		# Apply hard cap rules before folding scores in.
		if (exists $HARD_CAPS{ $result->check_id } && $result->is_fail) {
			my $ceiling = $HARD_CAPS{ $result->check_id };
			$cap = $ceiling if $ceiling < $cap;
		}

		next unless defined $result->score;

		my $weight = $self->{_weight_for}{ $result->check_id } // 1;
		$weighted_sum  += $result->score * $weight;
		$total_weight  += $weight;
	}

	my $raw = $total_weight > 0
		? int($weighted_sum / $total_weight + 0.5)
		: 0;

	my $score = $raw < $cap ? $raw : $cap;
	$score = $MIN_SCORE if $score < $MIN_SCORE;

	$self->{_cached_score} = $score;
	$self->{_score_dirty}  = 0;

	return $score;
}

=head2 results

=head3 PURPOSE

Returns all Result objects in insertion order.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

Arrayref of L<Test::CPAN::Health::Result> objects.

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
        |          |                                    |

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  results : seq Result

=head3 SIDE EFFECTS

None.

=head3 USAGE EXAMPLE

    for my $r (@{ $report->results }) { ... }

=cut

sub results { my ($self) = @_; return $self->{_results} }

=head2 by_status

=head3 PURPOSE

Group results by their status string.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

Hashref mapping status strings to arrayrefs of Result objects.

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
        |          |                                    |

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  by_status : status --> seq Result
  -------------------------------------------------------
  forall s : dom(by_status) @ forall r : by_status(s) @ r.status = s

=head3 SIDE EFFECTS

None.

=head3 USAGE EXAMPLE

    my $failures = $report->by_status->{fail};

=cut

sub by_status {
	my ($self) = @_;

	my %grouped;
	for my $result (@{$self->{_results}}) {
		push @{ $grouped{ $result->status } }, $result;
	}

	return \%grouped;
}

=head2 by_category

=head3 PURPOSE

Group results by the category of the originating check.  Requires that
each Result's C<data> hashref carries a C<category> key (populated by
the Runner when it adds results).

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

Hashref mapping category strings to arrayrefs of Result objects.

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
        |          |                                    |

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  by_category : category --> seq Result

=head3 SIDE EFFECTS

None.

=head3 USAGE EXAMPLE

    my $security_results = $report->by_category->{security};

=cut

sub by_category {
	my ($self) = @_;

	my %grouped;
	for my $result (@{$self->{_results}}) {
		my $cat = $result->data->{category} // 'unknown';
		push @{ $grouped{$cat} }, $result;
	}

	return \%grouped;
}

# Convenience counts used by reporters and the CLI exit-code logic.

sub pass_count  { my ($self) = @_; return scalar grep { $_->is_pass  } @{$self->{_results}} }
sub warn_count  { my ($self) = @_; return scalar grep { $_->is_warn  } @{$self->{_results}} }
sub fail_count  { my ($self) = @_; return scalar grep { $_->is_fail  } @{$self->{_results}} }
sub skip_count  { my ($self) = @_; return scalar grep { $_->is_skip  } @{$self->{_results}} }
sub error_count { my ($self) = @_; return scalar grep { $_->is_error } @{$self->{_results}} }

=head2 as_hash

=head3 PURPOSE

Serialise the entire report to a plain hashref (for JSON reporter).

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

Hashref with keys: overall_score, pass, warn, fail, skip, error, results.

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
        |          |                                    |

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  AsHashOp
  report : Report
  output : Hashref

=head3 SIDE EFFECTS

None.

=head3 USAGE EXAMPLE

    my $href = $report->as_hash;

=cut

sub as_hash {
	my ($self) = @_;

	return {
		overall_score => $self->overall_score,
		pass          => $self->pass_count,
		warn          => $self->warn_count,
		fail          => $self->fail_count,
		skip          => $self->skip_count,
		error         => $self->error_count,
		results       => [ map { $_->as_hash } @{$self->{_results}} ],
	};
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
