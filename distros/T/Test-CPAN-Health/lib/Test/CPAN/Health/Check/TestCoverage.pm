package Test::CPAN::Health::Check::TestCoverage;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use File::Path qw(remove_tree);
use File::Spec;
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

Readonly::Scalar my $SCORE_PASS => 80;
Readonly::Scalar my $SCORE_WARN => 60;

=head1 NAME

Test::CPAN::Health::Check::TestCoverage - Measure test suite statement coverage

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::TestCoverage;

    my $check  = Test::CPAN::Health::Check::TestCoverage->new;
    my $result = $check->run($dist);

    printf "%s: %s\n", $result->status, $result->summary;

=head1 DESCRIPTION

Runs the distribution's own test suite under L<Devel::Cover> and reports the
overall statement-coverage percentage as the check score.

The check proceeds in three steps inside the distribution's root directory:

=over 4

=item 1.

Generates C<Makefile> (via C<perl Makefile.PL>) or C<Build> (via
C<perl Build.PL>) if the build file is absent.

=item 2.

Runs C<make test> (or C<./Build test>) with
C<HARNESS_PERL_SWITCHES=-MDevel::Cover> and C<PERL5OPT=-MDevel::Cover>
set in the environment, causing the test harness to record coverage into
C<cover_db/>.

=item 3.

Invokes C<cover -report text> to generate a coverage summary, then parses
the statement-coverage percentage from the C<Total> row.

=back

The check is skipped when any of the following apply:

=over 4

=item * C<--no-cover> was passed (C<no_cover> constructor flag).

=item * L<Devel::Cover> is not installed.

=item * No C<.t> files exist under C<t/>.

=item * Neither C<Makefile.PL> nor C<Build.PL> exists.

=item * The C<cover> binary cannot be located.

=back

Score = integer part of the statement-coverage percentage.
Status thresholds: pass E<ge> 80, warn E<ge> 60, fail otherwise.

=head1 LIMITATIONS

=over 4

=item * Running the test suite is slow; expect 2-5x the normal test time.

=item * The check temporarily changes the process working directory to the
distribution root and restores it afterwards.

=item * Requires C<make> (ExtUtils::MakeMaker dists) or a C<Build> script
(Module::Build dists).

=back

=cut

sub id          { return 'test_coverage'                                                    }
sub name        { return 'Test Coverage'                                                    }
sub description { return 'Measures statement coverage of the test suite via Devel::Cover'  }
sub weight      { return 7                                                                  }
sub category    { return 'ci'                                                               }

=head2 run

=head3 PURPOSE

Execute the distribution's test suite under C<Devel::Cover> and return the
statement-coverage percentage as a 0-100 score.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional

=head4 OUTPUT

L<Test::CPAN::Health::Result> with check_id C<'test_coverage'>.

=head3 MESSAGES

  Code  | Severity | Message                                          | Resolution
  ------+----------+--------------------------------------------------+-----------
  TC001 | SKIP     | Skipped (--no-cover is set)                      | Remove --no-cover
  TC002 | SKIP     | Devel::Cover is not installed                    | cpanm Devel::Cover
  TC003 | SKIP     | No test files found under t/                     | Add tests
  TC004 | SKIP     | No Makefile.PL or Build.PL found                 | Add build file
  TC005 | SKIP     | cover binary not found                           | Install Devel::Cover
  TC006 | ERROR    | Failed to run coverage check: ...                | See error detail
  TC007 | ERROR    | Could not parse statement coverage from report   | Check cover output
  TC008 | PASS     | Statement coverage: N%                           |
  TC009 | WARN     | Statement coverage: N%                           | Add more tests
  TC010 | FAIL     | Statement coverage: N%                           | Add more tests

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  TestCoverageOp
  stmt_pct  : 0..100
  score     : 0..100
  -------------------------------------------------------
  no_cover = true           => status = skip
  Devel::Cover unavailable  => status = skip
  t_files = {}              => status = skip
  no build file             => status = skip
  score >= 80               => status = pass
  score >= 60               => status = warn
  score < 60                => status = fail

=head3 SIDE EFFECTS

Runs the full test suite in a subprocess with coverage tracing enabled.
Writes C<cover_db/> inside the distribution root.  Temporarily changes
and then restores the process working directory.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::TestCoverage->new->run($dist);
    printf "Statement coverage: %s\n", $result->summary;

=cut

sub run {
	my ($self, $dist, $context) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	my $skip = $self->_check_preconditions($dist);
	return $skip if $skip;

	my $cover_bin = _find_cover_bin();
	return $self->_skip('cover binary not found') unless $cover_bin;

	my $has_makefile_pl = $dist->file_path('Makefile.PL') ? 1 : 0;
	my $has_build_pl    = $dist->file_path('Build.PL')    ? 1 : 0;

	my ($output, $run_err, $tests_failed)
		= _collect_coverage($dist, $has_makefile_pl, $has_build_pl, $cover_bin);

	return $self->_error("Failed to run coverage check: $run_err") if $run_err;

	return $self->_parse_and_score($output, $tests_failed);
}

## no critic (ProhibitUnusedPrivateSubroutines)
sub _check_preconditions {
	my ($self, $dist) = @_;

	return $self->_skip('Skipped (--no-cover is set)') if $self->no_cover;

	my $has_cover = eval { require Devel::Cover; 1 };
	return $self->_skip('Devel::Cover is not installed') unless $has_cover;

	my @t_files = @{ $dist->t_files };
	return $self->_skip('No test files found under t/') unless @t_files;

	unless ($dist->file_path('Makefile.PL') || $dist->file_path('Build.PL')) {
		return $self->_skip('No Makefile.PL or Build.PL found');
	}

	return;
}

## no critic (ProhibitUnusedPrivateSubroutines)
sub _parse_and_score {
	my ($self, $output, $tests_failed) = @_;

	# Parse statement coverage from the Total row of the text report.
	# "Total  91.7   88.2   50.0  100.0   75.0  100.0   88.2" (spaces or tabs)
	my $stmt_pct;
	if (defined $output && $output =~ / ^ Total [\s\t]+ ([\d.]+) /mx) {
		$stmt_pct = $1 + 0;
	}

	unless (defined $stmt_pct) {
		my $snippet = defined $output ? substr($output, 0, 300) : '(no output)';
		$snippet =~ s/ \s+ / /gx;
		return $self->_error(
			"Could not parse statement coverage from cover output. "
			. "First 300 chars: $snippet"
		);
	}

	my $score  = int($stmt_pct);
	$score     = 100 if $score > 100;
	my $status = $score >= $SCORE_PASS ? 'pass'
	           : $score >= $SCORE_WARN ? 'warn'
	           :                         'fail';

	my @details;
	push @details, 'Warning: some tests failed during the coverage run' if $tests_failed;

	return $self->_result(
		status  => $status,
		score   => $score,
		summary => sprintf('Statement coverage: %.1f%%', $stmt_pct),
		details => \@details,
		data    => {
			name               => $self->name,
			statement_coverage => $stmt_pct,
			tests_failed       => $tests_failed ? 1 : 0,
		},
	);
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

sub _collect_coverage {
	my ($dist, $has_makefile_pl, $has_build_pl, $cover_bin) = @_;

	require Cwd;
	my $orig_dir = Cwd::getcwd();
	my ($output, $run_err, $tests_failed);

	my $ok = eval {
		chdir $dist->path;

		remove_tree('cover_db') if -d 'cover_db';

		if ($has_makefile_pl && !-f 'Makefile') {
			system($^X, 'Makefile.PL') == 0
				or croak "perl Makefile.PL failed (exit $?)";
		} elsif ($has_build_pl && !-f 'Build') {
			system($^X, 'Build.PL') == 0
				or croak "perl Build.PL failed (exit $?)";
		}

		## no critic (ProhibitPackageVars)
		local $ENV{HARNESS_PERL_SWITCHES} = '-MDevel::Cover';
		local $ENV{PERL5OPT}              = '-MDevel::Cover';

		my $make = _make_command();
		{
			no autodie;
			if (-f 'Build') {
				$tests_failed = 1 if system('./Build', 'test') != 0;
			} else {
				$tests_failed = 1 if system($make, 'test') != 0;
			}
		}

		open my $fh, '-|', $cover_bin, '-report', 'text'
			or croak "Cannot exec $cover_bin -report text: $!";
		{
			local $/ = undef;
			$output = <$fh>;
		}
		{
			no autodie 'close';
			close $fh;
		}
		1;
	};
	$run_err = $ok ? undef : $@;

	{
		no autodie 'chdir';
		chdir $orig_dir;
	}

	return ($output, $run_err, $tests_failed);
}

# Locate the 'cover' binary from Devel::Cover's installation directory,
# falling back to a PATH scan.  Returns the binary path or undef.
sub _find_cover_bin {
	require Config;

	## no critic (ProhibitPackageVars)
	for my $dir (
		$Config::Config{sitebin},
		$Config::Config{bin},
		$Config::Config{installbin},
	) {
		next unless defined $dir && length $dir;
		my $candidate = File::Spec->catfile($dir, 'cover');
		return $candidate if -x $candidate;
	}

	for my $dir (File::Spec->path()) {
		my $candidate = File::Spec->catfile($dir, 'cover');
		return $candidate if -x $candidate;
	}

	return;
}

# Return the configured make command for this perl installation.
sub _make_command {
	require Config;
	## no critic (ProhibitPackageVars)
	return $Config::Config{make} || 'make';
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
