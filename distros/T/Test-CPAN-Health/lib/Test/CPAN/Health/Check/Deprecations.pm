package Test::CPAN::Health::Check::Deprecations;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use File::Spec;
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

# Each entry is a pair: [ qr/PATTERN/, 'Human-readable label' ].
# Patterns use /m so ^ and $ match per-line within slurped file content.
Readonly::Array my @DEPRECATED_PATTERNS => (
	[ qr/ \b given \s* \( /mx,          'given/when (experimental; removed in Perl 5.36 feature bundle)' ],
	[ qr/ \b when  \s* \( /mx,          'when (experimental; removed in Perl 5.36 feature bundle)'       ],
	[ qr/ \$ \[ /mx,                    '$[ array-base variable (deprecated since Perl 5.12)'            ],
	[ qr/ \b UNIVERSAL::isa \s* \( /mx, 'UNIVERSAL::isa() as function (deprecated since Perl 5.26)'     ],
	[ qr/ \b UNIVERSAL::can \s* \( /mx, 'UNIVERSAL::can() as function (deprecated since Perl 5.26)'     ],
	[ qr/ ^ \s* use \s+ UNIVERSAL \b /mx, 'use UNIVERSAL (deprecated since Perl 5.22)'                  ],
	[ qr/ ^ \s* use \s+ Switch    \b /mx, 'use Switch (removed from core since Perl 5.10)'              ],
);

# Score thresholds (files with at least one hit / total files).
Readonly::Scalar my $SCORE_PASS => 90;
Readonly::Scalar my $SCORE_WARN => 50;

=head1 NAME

Test::CPAN::Health::Check::Deprecations - Detect use of deprecated Perl features

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::Deprecations;

    my $check  = Test::CPAN::Health::Check::Deprecations->new;
    my $result = $check->run($dist);

    printf "%s: %s\n", $result->status, $result->summary;

=head1 DESCRIPTION

Scans all source files for a curated set of deprecated or removed Perl
features and modules, using regular-expression matching (no external CPAN
module required):

=over 4

=item * C<given>/C<when> blocks (removed from default feature set in Perl 5.36).

=item * C<$[> array-base variable (deprecated since Perl 5.12).

=item * C<UNIVERSAL::isa()> and C<UNIVERSAL::can()> called as functions
(deprecated since Perl 5.26).

=item * C<use UNIVERSAL> (deprecated since Perl 5.22).

=item * C<use Switch> (removed from core since Perl 5.10).

=back

Score = round((clean_files / total_files) * 100).  Files with any hit count
as "affected".  Status thresholds: pass E<ge> 90 %, warn E<ge> 50 %, fail
below 50 %.

=head1 LIMITATIONS

=over 4

=item * Pattern matching does not parse Perl; occurrences inside strings,
heredocs, or comments will produce false positives.  The check deliberately
errs on the side of over-reporting to prompt manual review.

=item * The list of deprecated features is curated manually and may be
incomplete.

=back

=cut

sub id          { return 'deprecations'                                                      }
sub name        { return 'Deprecations'                                                      }
sub description { return 'Detects use of deprecated Perl features or removed modules'        }
sub weight      { return 4                                                                   }
sub category    { return 'quality'                                                           }

=head2 run

=head3 PURPOSE

Search every source file for known-deprecated constructs and return a
proportional score.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional

=head4 OUTPUT

L<Test::CPAN::Health::Result> with check_id C<'deprecations'>.

=head3 MESSAGES

  Code  | Severity | Message                                       | Resolution
  ------+----------+-----------------------------------------------+-----------
  DP001 | SKIP     | No source files found                         | Add source files
  DP002 | PASS     | No deprecated constructs found                |
  DP003 | WARN     | Deprecated constructs found in N file(s)      | Remove usage
  DP004 | FAIL     | Most files use deprecated constructs          | Remove usage

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  DeprecationsOp
  clean_files  : N
  total_files  : N
  score        : 0..100
  -------------------------------------------------------
  total_files = 0    => status = skip
  score >= 90        => status = pass
  score >= 50        => status = warn
  score < 50         => status = fail

=head3 SIDE EFFECTS

Reads source files only; no network or subprocess I/O.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::Deprecations->new->run($dist);
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

	my ($clean, $total) = (0, 0);
	my @details;

	for my $file (@files) {
		my $content;
		my $ok = eval {
			open my $fh, '<', $file;
			local $/ = undef;
			$content = <$fh>;
			close $fh;
			1;
		};
		if (!$ok || !defined $content) {
			carp "Could not read $file: $@";
			next;
		}

		$total++;
		my @hits;
		for my $entry (@DEPRECATED_PATTERNS) {
			my ($pattern, $label) = @{$entry};
			push @hits, $label if $content =~ $pattern;
		}

		if (@hits) {
			my $rel = File::Spec->abs2rel($file, $dist->path);
			push @details, "$rel: " . join('; ', @hits);
		} else {
			$clean++;
		}
	}

	unless ($total) {
		return $self->_skip('No files could be read');
	}

	my $score  = int($clean / $total * 100);
	my $status = $score >= $SCORE_PASS ? 'pass'
	           : $score >= $SCORE_WARN ? 'warn'
	           :                         'fail';

	return $self->_result(
		status  => $status,
		score   => $score,
		summary => $score == 100
			? 'No deprecated constructs found in any source file'
			: sprintf(
				'Deprecated constructs found in %d of %d file(s)',
				$total - $clean, $total,
			),
		details => \@details,
		data    => {
			name    => $self->name,
			total   => $total,
			clean   => $clean,
			affected => $total - $clean,
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
