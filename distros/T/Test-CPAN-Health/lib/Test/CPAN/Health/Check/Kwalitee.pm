package Test::CPAN::Health::Check::Kwalitee;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

Readonly::Scalar my $SCORE_PASS => 80;
Readonly::Scalar my $SCORE_WARN => 60;

=head1 NAME

Test::CPAN::Health::Check::Kwalitee - Check CPANTS kwalitee indicators

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::Kwalitee;

    my $check  = Test::CPAN::Health::Check::Kwalitee->new;
    my $result = $check->run($dist);

    printf "%s: %s\n", $result->status, $result->summary;

=head1 DESCRIPTION

Uses L<Module::CPANTS::Analyse> to evaluate the distribution against the
standard CPANTS kwalitee indicator set and converts the result into a
0-100 check score.

Experimental indicators (C<is_experimental = 1>) are excluded from the
score because they may change without notice and should not gate a
distribution's health status.  Core and extra indicators both count.

Score = (passed_non_experimental / total_non_experimental) * 100.
Status thresholds: pass E<ge> 80, warn E<ge> 60, fail otherwise.

=head1 LIMITATIONS

=over 4

=item * L<Module::CPANTS::Analyse> expects a directory laid out like an
unpacked CPAN tarball.  Fields like C<manifest_matches_dist> may return
false for a plain git working directory that lacks a C<MANIFEST> file.

=item * The C<_dangerous> option is required when analysing a local
directory rather than a downloaded distribution.

=back

=cut

sub id          { return 'kwalitee'                                                   }
sub name        { return 'CPANTS Kwalitee'                                            }
sub description { return 'Checks CPANTS kwalitee indicators via Module::CPANTS::Analyse' }
sub weight      { return 5                                                             }
sub category    { return 'quality'                                                    }

=head2 run

=head3 PURPOSE

Run the full CPANTS kwalitee analysis against the distribution and return
a scored result.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional

=head4 OUTPUT

L<Test::CPAN::Health::Result> with check_id C<'kwalitee'>.

=head3 MESSAGES

  Code  | Severity | Message                                       | Resolution
  ------+----------+-----------------------------------------------+-----------
  KW001 | SKIP     | Module::CPANTS::Analyse is not installed      | cpanm Module::CPANTS::Analyse
  KW002 | ERROR    | Module::CPANTS::Analyse failed: ...           | See error detail
  KW003 | ERROR    | No kwalitee indicators found                  | Upgrade Module::CPANTS::Analyse
  KW004 | PASS     | N of M kwalitee indicators passed (P%)        |
  KW005 | WARN     | N of M kwalitee indicators passed (P%)        | Fix listed indicators
  KW006 | FAIL     | N of M kwalitee indicators passed (P%)        | Fix listed indicators

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  KwaliteeOp
  passed  : N
  total   : N
  score   : 0..100
  -------------------------------------------------------
  Module::CPANTS::Analyse unavailable  => status = skip
  total = 0                            => status = error
  score >= 80                          => status = pass
  score >= 60                          => status = warn
  score < 60                           => status = fail

=head3 SIDE EFFECTS

Reads all source files in the distribution.  No network or subprocess I/O.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::Kwalitee->new->run($dist);
    printf "Kwalitee: %d/100\n", $result->score;

=cut

sub run {
	my ($self, $dist, $context) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	my $loaded = eval { require Module::CPANTS::Analyse; 1 };
	return $self->_skip('Module::CPANTS::Analyse is not installed') unless $loaded;

	require Module::CPANTS::Kwalitee;

	# Collect all indicators, scoring only the non-experimental ones.
	my $kw_obj       = Module::CPANTS::Kwalitee->new;
	my @all_inds     = @{ $kw_obj->get_indicators };
	my @scored_inds  = grep { !$_->{is_experimental} } @all_inds;
	my $total        = scalar @scored_inds;

	return $self->_error('No kwalitee indicators found') unless $total;

	my $analyser = Module::CPANTS::Analyse->new({
		distdir    => $dist->path,
		dist       => $dist->path,
		_dangerous => 1,
	});

	my $ok = eval {
		local $SIG{__WARN__} = sub {};    # suppress numerous undef-value warnings
		$analyser->analyse;
		$analyser->calc_kwalitee;
		1;
	};
	return $self->_error("Module::CPANTS::Analyse failed: $@") unless $ok;

	my $d      = $analyser->d;
	my $kwhash = $d->{kwalitee} // {};

	my ($passed, @failed_core, @failed_extra) = (0);
	for my $ind (@scored_inds) {
		my $name = $ind->{name};
		if ($kwhash->{$name}) {
			$passed++;
		} elsif ($ind->{is_extra}) {
			push @failed_extra, $name;
		} else {
			push @failed_core, $name;
		}
	}

	my $score  = int($passed / $total * 100);
	my $status = $score >= $SCORE_PASS ? 'pass'
	           : $score >= $SCORE_WARN ? 'warn'
	           :                         'fail';

	my @details = (
		(map { "Core indicator not met: $_" } sort @failed_core),
		(map { "Extra indicator not met: $_" } sort @failed_extra),
	);

	return $self->_result(
		status  => $status,
		score   => $score,
		summary => sprintf(
			'%d of %d kwalitee indicators passed (%d%%)',
			$passed, $total, $score,
		),
		details => \@details,
		data    => {
			name         => $self->name,
			passed       => $passed,
			total        => $total,
			failed_core  => \@failed_core,
			failed_extra => \@failed_extra,
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
