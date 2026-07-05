package Test::CPAN::Health::Check::Perlcritic;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use File::Spec;
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

# Run Perl::Critic at severity 3 (the "important" band: avoids nitpicky
# style warnings while still catching meaningful policy violations).
Readonly::Scalar my $CRITIC_SEVERITY => 3;

# Status thresholds on the "fraction of clean files * 100" scale.
Readonly::Scalar my $SCORE_PASS => 90;
Readonly::Scalar my $SCORE_WARN => 50;

=head1 NAME

Test::CPAN::Health::Check::Perlcritic - Run Perl::Critic and report policy violations

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::Perlcritic;

    my $check  = Test::CPAN::Health::Check::Perlcritic->new;
    my $result = $check->run($dist);

    printf "%s: %s\n", $result->status, $result->summary;

=head1 DESCRIPTION

Runs L<Perl::Critic> at severity 3 against every C<.pm> and C<.pl> source
file in the distribution.  Score = round((clean_files / total_files) * 100).

Status thresholds: pass E<ge> 90 %, warn E<ge> 50 %, fail below 50 %.

=head1 LIMITATIONS

=over 4

=item * No C<.perlcriticrc> from the distribution under analysis is honoured;
the check always runs at the fixed severity level to ensure comparable scores
across distributions.

=item * Files that cannot be parsed by PPI (Perl::Critic's parser) are skipped
with a warning and excluded from the score calculation.

=back

=cut

sub id          { return 'perlcritic'                                      }
sub name        { return 'Perl::Critic'                                    }
sub description { return 'Runs Perl::Critic and reports policy violations' }
sub weight      { return 6                                                 }
sub category    { return 'quality'                                         }

=head2 run

=head3 PURPOSE

Critique all source files at severity 3 and return a scored Result reflecting
the fraction that pass without violations.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional

=head4 OUTPUT

L<Test::CPAN::Health::Result> with check_id C<'perlcritic'>.

=head3 MESSAGES

  Code  | Severity | Message                                     | Resolution
  ------+----------+---------------------------------------------+-----------
  CR001 | SKIP     | No source files found                       | Add source files
  CR002 | PASS     | All N files pass Perl::Critic at sev 3     |
  CR003 | WARN     | N of M files have policy violations         | Fix violations
  CR004 | FAIL     | Most files have Perl::Critic violations     | Fix violations

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  PerlcriticOp
  total_files  : N
  clean_files  : N
  score        : 0..100
  -------------------------------------------------------
  total_files = 0    => status = skip
  score >= 90        => status = pass
  score >= 50        => status = warn
  score < 50         => status = fail

=head3 SIDE EFFECTS

Invokes Perl::Critic which performs in-process PPI parsing of source files.
No network or subprocess I/O.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::Perlcritic->new->run($dist);
    print $result->summary;

=cut

sub run {
	my ($self, $dist, $context) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	my @files = @{ $dist->all_source_files };

	unless (@files) {
		return $self->_skip('No source files found');
	}

	require Perl::Critic;
	my $critic = Perl::Critic->new('-severity' => $CRITIC_SEVERITY);

	my ($clean, $total) = (0, 0);
	my @details;

	for my $file (@files) {
		my @violations;
		my $ok = eval {
			local $SIG{__WARN__} = sub { };    # suppress PPI noise
			@violations = $critic->critique($file);
			1;
		};
		if (!$ok) {
			carp "Perl::Critic could not parse $file: $@";
			next;
		}
		$total++;
		if (@violations) {
			my $rel = File::Spec->abs2rel($file, $dist->path);
			push @details, sprintf('%s: %d violation(s)', $rel, scalar @violations);
		} else {
			$clean++;
		}
	}

	unless ($total) {
		return $self->_skip('No files could be parsed by Perl::Critic');
	}

	my $score  = int($clean / $total * 100);
	my $status = $score >= $SCORE_PASS ? 'pass'
	           : $score >= $SCORE_WARN ? 'warn'
	           :                         'fail';

	return $self->_result(
		status  => $status,
		score   => $score,
		summary => sprintf(
			'%d of %d file(s) pass Perl::Critic at severity %d',
			$clean, $total, $CRITIC_SEVERITY,
		),
		details => \@details,
		data    => {
			name     => $self->name,
			total    => $total,
			clean    => $clean,
			severity => $CRITIC_SEVERITY,
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
