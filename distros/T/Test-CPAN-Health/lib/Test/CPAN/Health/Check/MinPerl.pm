package Test::CPAN::Health::Check::MinPerl;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

# Score awarded when the declared version is verified to match or exceed what
# Perl::MinimumVersion detects in the source code.
Readonly::Scalar my $SCORE_VERIFIED   => 100;

# Score when a version is declared but Perl::MinimumVersion is unavailable or
# could not scan any source files -- partial credit.
Readonly::Scalar my $SCORE_UNVERIFIED =>  80;

# Score when the declared minimum is lower than what source code actually
# requires -- underdeclaring is misleading to CPAN installers.
Readonly::Scalar my $SCORE_UNDER      =>  40;

=head1 NAME

Test::CPAN::Health::Check::MinPerl - Check that a minimum Perl version is declared and accurate

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::MinPerl;

    my $check  = Test::CPAN::Health::Check::MinPerl->new;
    my $result = $check->run($dist);

    printf "%s: %s\n", $result->status, $result->summary;

=head1 DESCRIPTION

Checks two things:

=over 4

=item 1.

The distribution declares C<requires perl =E<gt> 'X.Y'> in its runtime
prerequisites (readable via META).

=item 2.

If L<Perl::MinimumVersion> is available, it scans all C<.pm> and C<.pl>
source files and confirms the declared minimum is not lower than what the
source code actually requires.

=back

Score matrix:

=over 4

=item * 100 -- Declared, and verified to match or exceed detected minimum.

=item *  80 -- Declared, but C<Perl::MinimumVersion> unavailable to verify.

=item *  40 -- Declared minimum is lower than detected source minimum (underdeclared).

=item *   0 -- No minimum Perl version declared.

=item * skip -- No META file found.

=back

=head1 LIMITATIONS

=over 4

=item * C<Perl::MinimumVersion> is an optional dependency; the check degrades
gracefully to score 80 when it is absent.

=item * Only C<runtime.requires.perl> is inspected.  A constraint in
C<configure.requires> or C<build.requires> is ignored.

=back

=cut

sub id          { return 'min_perl'                                               }
sub name        { return 'Minimum Perl Version'                                   }
sub description { return 'Checks that a minimum Perl version is declared in META' }
sub weight      { return 3                                                        }
sub category    { return 'packaging'                                              }

=head2 run

=head3 PURPOSE

Inspect C<prereqs.runtime.requires.perl> in META and, when
L<Perl::MinimumVersion> is available, verify it against the actual source code.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional  prior check results

=head4 OUTPUT

L<Test::CPAN::Health::Result> with check_id C<'min_perl'>.

=head3 MESSAGES

  Code  | Severity | Message                                        | Resolution
  ------+----------+------------------------------------------------+-----------
  MP001 | SKIP     | No META file                                   | Add META file
  MP002 | FAIL     | No min Perl version declared in prereqs        | Add requires perl
  MP003 | PASS     | Declared; Perl::MinimumVersion unavailable     |
  MP004 | WARN     | Declared minimum lower than detected minimum   | Raise declared minimum
  MP005 | PASS     | Declared minimum verified against source code  |

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  MinPerlOp
  dist      : Distribution
  declared  : String | undefined
  detected  : version | undefined
  -------------------------------------------------------
  meta = undefined        => status = skip
  declared = undefined    => status = fail /\ score = 0
  detected = undefined    => status = pass /\ score = 80
  declared_v < detected   => status = warn /\ score = 40
  declared_v >= detected  => status = pass /\ score = 100

=head3 SIDE EFFECTS

May invoke L<Perl::MinimumVersion> on all source files, which performs PPI
parsing (CPU-intensive for large distributions).

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::MinPerl->new->run($dist);
    print $result->summary;

=cut

sub run {
	my ($self, $dist, $context) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	my $meta = $dist->meta;

	unless ($meta) {
		return $self->_skip('No META file found -- cannot check minimum Perl version');
	}

	# Extract declared minimum Perl from the v2-normalised structure.
	my $struct   = $meta->as_struct;
	my $declared = $struct->{prereqs}{runtime}{requires}{perl};

	unless (defined $declared && length $declared) {
		return $self->_result(
			status  => 'fail',
			score   => 0,
			summary => 'No minimum Perl version declared in META runtime prereqs',
			details => [
				'Add: requires "perl" => "5.x.y"  to your dist prerequisites',
				'Common choices: 5.010, 5.014, 5.020, 5.032',
			],
			data => { name => $self->name },
		);
	}

	my $pmv_ok = eval { require Perl::MinimumVersion; 1 };

	unless ($pmv_ok) {
		return $self->_result(
			status  => 'pass',
			score   => $SCORE_UNVERIFIED,
			summary => "Minimum Perl $declared declared "
				. '(install Perl::MinimumVersion to verify against source)',
			data => { name => $self->name, declared => $declared },
		);
	}

	my $detected = _detect_minimum($dist->all_source_files);

	unless (defined $detected) {
		return $self->_result(
			status  => 'pass',
			score   => $SCORE_UNVERIFIED,
			summary => "Minimum Perl $declared declared "
				. '(no source files found to verify against)',
			data => { name => $self->name, declared => $declared },
		);
	}

	return _compare_versions($self, $declared, $detected);
}

## no critic (ProhibitUnusedPrivateSubroutines)
sub _detect_minimum {
	my ($files_ref) = @_;

	my $detected;
	for my $file (@{$files_ref}) {
		my $min;
		my $ok = eval {
			my $pmv = Perl::MinimumVersion->new($file);
			$min = $pmv->minimum_version;
			1;
		};
		if (!$ok) {
			carp "Perl::MinimumVersion could not parse $file: $@";
			next;
		}
		next unless defined $min;
		$detected = $min if !defined $detected || $min > $detected;
	}
	return $detected;
}

## no critic (ProhibitUnusedPrivateSubroutines)
sub _compare_versions {
	my ($self, $declared, $detected) = @_;

	(my $clean = $declared) =~ s/ ^ [><=!] =? \s* //x;
	require version;
	my $declared_v = eval { version->parse($clean) };

	if (defined $declared_v && $declared_v < $detected) {
		return $self->_result(
			status  => 'warn',
			score   => $SCORE_UNDER,
			summary => "Declared minimum Perl $declared is lower than detected minimum "
				. $detected->stringify,
			details => [
				'Update META prereqs to require perl ' . $detected->stringify,
				'Underdeclaring the minimum Perl version can cause installation failures',
			],
			data => {
				name     => $self->name,
				declared => $declared,
				detected => $detected->stringify,
			},
		);
	}

	return $self->_result(
		status  => 'pass',
		score   => $SCORE_VERIFIED,
		summary => "Minimum Perl $declared declared; detected minimum from source is "
			. $detected->stringify,
		data => {
			name     => $self->name,
			declared => $declared,
			detected => $detected->stringify,
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
