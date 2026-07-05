package Test::CPAN::Health::Check::Complexity;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use File::Spec;
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

# McCabe cyclomatic complexity above this value is considered "too complex".
# 20 is a widely-used industry threshold (SEI, McCabe's original guidance).
Readonly::Scalar my $COMPLEXITY_THRESHOLD => 20;

# Status thresholds: (1 - ratio_complex) * 100.
Readonly::Scalar my $SCORE_PASS => 90;
Readonly::Scalar my $SCORE_WARN => 50;

=head1 NAME

Test::CPAN::Health::Check::Complexity - Check cyclomatic complexity of subroutines

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::Complexity;

    my $check  = Test::CPAN::Health::Check::Complexity->new;
    my $result = $check->run($dist);

    printf "%s: %s\n", $result->status, $result->summary;

=head1 DESCRIPTION

Uses L<Perl::Metrics::Simple> to compute the McCabe cyclomatic complexity of
every subroutine in the distribution's C<.pm> files.  Subroutines with a
complexity score above 20 are flagged as "too complex".

Score = round((1 - complex_subs / total_subs) * 100).  Status thresholds:
pass E<ge> 90, warn E<ge> 50, fail otherwise.

If no subroutines are found (e.g. a purely declarative module) the check
passes at 100.

=head1 LIMITATIONS

=over 4

=item * Only C<.pm> files are analysed; script files (C<.pl>, C<bin/>) are
excluded because their top-level code is not part of a named subroutine.

=item * Perl::Metrics::Simple uses PPI for parsing and may not handle all
Perl syntax correctly.

=back

=cut

sub id          { return 'complexity'                                                       }
sub name        { return 'Cyclomatic Complexity'                                            }
sub description { return 'Checks cyclomatic complexity of subroutines against a threshold' }
sub weight      { return 4                                                                  }
sub category    { return 'quality'                                                          }

=head2 run

=head3 PURPOSE

Measure McCabe complexity of all named subroutines and score by the fraction
below the threshold.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional

=head4 OUTPUT

L<Test::CPAN::Health::Result> with check_id C<'complexity'>.

=head3 MESSAGES

  Code  | Severity | Message                                     | Resolution
  ------+----------+---------------------------------------------+-----------
  CX001 | SKIP     | No .pm files found                          | Add lib/ modules
  CX002 | PASS     | All N subroutines within complexity limit   |
  CX003 | WARN     | N subroutine(s) exceed complexity limit     | Refactor subs
  CX004 | FAIL     | Most subroutines exceed complexity limit    | Refactor subs

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  ComplexityOp
  total_subs   : N
  complex_subs : N
  score        : 0..100
  -------------------------------------------------------
  total_subs = 0    => status = pass /\ score = 100
  score >= 90       => status = pass
  score >= 50       => status = warn
  score < 50        => status = fail

=head3 SIDE EFFECTS

Invokes Perl::Metrics::Simple which performs in-process PPI parsing.  No
network or subprocess I/O.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::Complexity->new->run($dist);
    print $result->summary;

=cut

sub run {
	my ($self, $dist, $context) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	my @pm_files = @{ $dist->pm_files };

	unless (@pm_files) {
		return $self->_skip('No .pm files found under lib/');
	}

	require Perl::Metrics::Simple;
	my $analyzer = Perl::Metrics::Simple->new;

	my $analysis;
	my $ok = eval {
		local $SIG{__WARN__} = sub { };    # suppress PPI noise
		$analysis = $analyzer->analyze_files(@pm_files);
		1;
	};
	if (!$ok) {
		return $self->_error("Perl::Metrics::Simple failed: $@");
	}

	my @all_subs = @{ $analysis->subs };

	unless (@all_subs) {
		return $self->_result(
			status  => 'pass',
			score   => 100,
			summary => 'No named subroutines found -- nothing to measure',
			data    => { name => $self->name, total => 0, complex => 0 },
		);
	}

	my @complex = grep { $_->{mccabe_complexity} > $COMPLEXITY_THRESHOLD } @all_subs;

	my $score  = int((1 - @complex / @all_subs) * 100);
	my $status = @complex == 0          ? 'pass'
	           : $score >= $SCORE_WARN  ? 'warn'
	           :                          'fail';

	my @details = map {
		sprintf(
			'%s::%s -- complexity %d (threshold %d)',
			File::Spec->abs2rel($_->{path}, $dist->path),
			$_->{name},
			$_->{mccabe_complexity},
			$COMPLEXITY_THRESHOLD,
		)
	} @complex;

	return $self->_result(
		status  => $status,
		score   => $score,
		summary => sprintf(
			'%d of %d subroutine(s) exceed McCabe complexity threshold of %d',
			scalar @complex, scalar @all_subs, $COMPLEXITY_THRESHOLD,
		),
		details => \@details,
		data    => {
			name      => $self->name,
			total     => scalar @all_subs,
			complex   => scalar @complex,
			threshold => $COMPLEXITY_THRESHOLD,
		},
	);
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
