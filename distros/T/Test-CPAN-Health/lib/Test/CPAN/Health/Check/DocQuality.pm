package Test::CPAN::Health::Check::DocQuality;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use File::Spec;
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

# Required =head1 sections for a well-documented module.
Readonly::Array my @REQUIRED_SECTIONS => qw(NAME SYNOPSIS DESCRIPTION AUTHOR);

# Regex matching a LICENSE / COPYRIGHT heading (various spellings).
Readonly::Scalar my $LICENSE_HEAD_RE => qr/ ^ =head1 \s+ (?:LICEN[CS]E|COPYRIGHT) /xi;

# Per-file score assignments.
Readonly::Scalar my $SCORE_FILE_FULL   => 100;  # no errors, all sections present
Readonly::Scalar my $SCORE_FILE_NOSEC  =>  70;  # no errors, some sections missing
Readonly::Scalar my $SCORE_FILE_ERRORS =>  30;  # POD syntax errors present
Readonly::Scalar my $SCORE_FILE_NOPOD  =>   0;  # no POD at all

# Overall status thresholds.
Readonly::Scalar my $SCORE_PASS => 90;
Readonly::Scalar my $SCORE_WARN => 50;

=head1 NAME

Test::CPAN::Health::Check::DocQuality - Check POD syntax and required section presence

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::DocQuality;

    my $check  = Test::CPAN::Health::Check::DocQuality->new;
    my $result = $check->run($dist);

    printf "%s: %s\n", $result->status, $result->summary;

=head1 DESCRIPTION

For each C<.pm> file under C<lib/>, this check:

=over 4

=item 1.

Runs L<Pod::Checker> to detect POD syntax errors.

=item 2.

Scans for the presence of required C<=head1> sections: NAME, SYNOPSIS,
DESCRIPTION, AUTHOR, and a LICENSE/COPYRIGHT section (under any of the
common spellings).

=back

Per-file score: 100 (no errors, all sections), 70 (no errors, some sections
missing), 30 (POD errors present), 0 (no POD).  The check score is the
integer average across all files.

=head1 LIMITATIONS

=over 4

=item * Only C<=head1> headings are matched for required sections.

=item * Pod::Checker errors/warnings are counted but not included verbatim
in the result details to keep output concise.

=back

=cut

sub id          { return 'doc_quality'                                              }
sub name        { return 'Documentation Quality'                                    }
sub description { return 'Checks POD syntax and the presence of required sections'  }
sub weight      { return 4                                                          }
sub category    { return 'quality'                                                  }

=head2 run

=head3 PURPOSE

Aggregate Pod::Checker results and required-section presence across all C<.pm>
files and return a single scored Result.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional

=head4 OUTPUT

L<Test::CPAN::Health::Result> with check_id C<'doc_quality'>.

=head3 MESSAGES

  Code  | Severity | Message                                          | Resolution
  ------+----------+--------------------------------------------------+-----------
  DQ001 | SKIP     | No .pm files found                               | Add lib/ modules
  DQ002 | PASS     | All files have valid POD with required sections  |
  DQ003 | WARN     | Some files have POD issues                       | Fix listed files
  DQ004 | FAIL     | Most files have POD issues                       | Fix listed files

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  DocQualityOp
  files         : seq FileName
  file_scores   : seq (0..100)
  avg_score     : 0..100
  -------------------------------------------------------
  #files = 0          => status = skip
  avg_score >= 90     => status = pass
  avg_score >= 50     => status = warn
  avg_score < 50      => status = fail

=head3 SIDE EFFECTS

Reads source files; invokes Pod::Checker which performs in-process parsing.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::DocQuality->new->run($dist);
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

	require Pod::Checker;

	my $total_score = 0;
	my @issues;

	for my $file (@pm_files) {
		my $rel = File::Spec->abs2rel($file, $dist->path);
		my ($file_score, $issue) = _score_file($file, $rel);
		$total_score += $file_score;
		push @issues, $issue if defined $issue;
	}

	my $score  = int($total_score / scalar @pm_files);
	my $status = $score >= $SCORE_PASS ? 'pass'
	           : $score >= $SCORE_WARN ? 'warn'
	           :                         'fail';

	return $self->_result(
		status  => $status,
		score   => $score,
		summary => sprintf(
			'Documentation quality score %d%% across %d file(s)%s',
			$score,
			scalar @pm_files,
			@issues ? sprintf(' (%d issue(s) found)', scalar @issues) : '',
		),
		details => \@issues,
		data    => {
			name  => $self->name,
			files => scalar @pm_files,
			score => $score,
		},
	);
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Score a single file; returns (score, issue_string_or_undef).
sub _score_file {
	my ($file, $rel) = @_;

	my $errors  = _count_pod_errors($file);
	my %secs    = _pod_sections($file);
	my $has_pod = %secs ? 1 : 0;

	if (!$has_pod && !$errors) {
		return ($SCORE_FILE_NOPOD, "$rel: no POD found");
	}
	if ($errors) {
		return ($SCORE_FILE_ERRORS, sprintf('%s: %d POD error(s)', $rel, $errors));
	}

	my @missing = grep { !$secs{$_} } @REQUIRED_SECTIONS;
	push @missing, 'LICENSE' unless $secs{LICENSE} || $secs{LICENCE} || $secs{COPYRIGHT};

	if (@missing) {
		return ($SCORE_FILE_NOSEC, sprintf('%s: missing sections: %s', $rel, join(', ', @missing)));
	}
	return ($SCORE_FILE_FULL, undef);
}

# Run Pod::Checker on $file; return count of errors (warnings ignored).
sub _count_pod_errors {
	my ($file) = @_;

	my $checker  = Pod::Checker->new;
	my $dev_null = File::Spec->devnull;

	open my $sink, '>', $dev_null
		or return 0;    # can't open devnull; skip error counting
	$checker->parse_from_file($file, $sink);
	close $sink;

	my $n = $checker->num_errors // 0;
	return $n < 0 ? 0 : $n;    # Pod::Checker returns -1 when there is no POD
}

# Return a hash of =head1 section names found in $file.
sub _pod_sections {
	my ($file) = @_;

	open my $fh, '<', $file or return ();
	my @lines = <$fh>;
	close $fh;

	my %sections;
	my $in_pod = 0;

	for my $line (@lines) {
		chomp $line;
		if ($line =~ / ^ = (\w+) /x) {
			$in_pod = ($1 ne 'cut');
		}
		if ($in_pod && $line =~ / ^ =head1 \s+ (.+) /x) {
			my $title = $1;
			$title =~ s/ \s+ $ //x;
			$sections{$title}++;
			$sections{LICENSE}++   if $title =~ / LICEN [CS] E /xi;
			$sections{LICENCE}++   if $title =~ / LICEN [CS] E /xi;
			$sections{COPYRIGHT}++ if $title =~ / COPYRIGHT /xi;
		}
	}

	return %sections;
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
