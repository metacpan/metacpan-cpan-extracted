package Test::CPAN::Health::Check::SemVer;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

# Semantic versioning regex per semver.org 2.0.0 spec (strictly ASCII).
# Accepts optional leading 'v'.  Split into smaller qr// chunks for readability.
Readonly::Scalar my $SEMVER_NUM_RE => qr{ 0 | [1-9]\d* }x;
Readonly::Scalar my $SEMVER_PRE_RE => qr{ - [0-9a-zA-Z.-]+ }x;
Readonly::Scalar my $SEMVER_BLD_RE => qr{ \+ [0-9a-zA-Z.-]+ }x;
Readonly::Scalar my $SEMVER_RE => qr{
	^ v?
	($SEMVER_NUM_RE)       # major
	\.($SEMVER_NUM_RE)     # minor
	\.($SEMVER_NUM_RE)     # patch
	(?: $SEMVER_PRE_RE )?  # pre-release (optional)
	(?: $SEMVER_BLD_RE )?  # build metadata (optional)
	$
}x;

# The "decimal" convention common on CPAN: 1.000001, 0.27, etc.
# We accept it with a warning because it is pervasive but not semver.
Readonly::Scalar my $DECIMAL_RE => qr/ ^ v? [0-9]+ \. [0-9]+ $ /x;

=head1 NAME

Test::CPAN::Health::Check::SemVer - Check that a distribution version follows semantic versioning

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::SemVer;

    my $check  = Test::CPAN::Health::Check::SemVer->new;
    my $result = $check->run($dist);

    printf "%s: %s\n", $result->status, $result->summary;

=head1 DESCRIPTION

Examines the version string declared in the distribution's META.json (or
META.yml) and scores it against the Semantic Versioning 2.0.0 specification
(L<https://semver.org>).

Score matrix:

=over 4

=item * 100 -- strict semver (X.Y.Z or vX.Y.Z, optionally with pre-release
and/or build metadata).

=item *  60 -- Perl-style decimal (X.YYY), accepted with a warning because
it is ubiquitous on CPAN but not interoperable with semver tooling.

=item *   0 -- anything else (missing version, empty string, epoch-only, etc.).

=back

=head1 LIMITATIONS

=over 4

=item * Version 0.x.y is legal semver and scores 100; it is B<not> penalised
here because many mature distributions use 0.x to signal API instability.

=item * This check does not compare the declared version against the version
embedded in the main C<.pm> file.  That comparison belongs to C<MinPerl> or
a dedicated C<VersionSync> check.

=back

=cut

sub id          { return 'sem_ver'                                                 }
sub name        { return 'Semantic Versioning'                                     }
sub description { return 'Checks that the distribution version follows semver 2.0' }
sub weight      { return 3                                                         }
sub category    { return 'packaging'                                               }

=head2 run

=head3 PURPOSE

Extract the version string from the distribution's META file and score it.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional  prior check results

=head4 OUTPUT

L<Test::CPAN::Health::Result> with:

  check_id  'sem_ver'
  status    'pass' | 'warn' | 'fail' | 'skip'
  score     0 | 60 | 100
  summary   human-readable verdict
  details   arrayref of diagnostic strings (non-empty on warn/fail)

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
  SV001 | SKIP     | No META file found                 | Add META.json or META.yml
  SV002 | FAIL     | Version is missing or empty        | Declare a version in META
  SV003 | WARN     | Decimal-style version {v}          | Migrate to X.Y.Z semver
  SV004 | FAIL     | Version {v} does not match semver  | Use X.Y.Z format
  SV005 | PASS     | Version {v} follows semver 2.0     |

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  SemVerOp
  dist    : Distribution
  version : String | undefined
  score   : {0, 60, 100}
  status  : {pass, warn, fail, skip}
  -------------------------------------------------------
  version = undefined => status = skip
  version = ""        => status = fail   /\ score = 0
  version matches SEMVER_RE   => status = pass /\ score = 100
  version matches DECIMAL_RE  => status = warn /\ score = 60
  otherwise                   => status = fail /\ score = 0

=head3 SIDE EFFECTS

None.  All information comes from the already-parsed META object.

=head3 USAGE EXAMPLE

    my $result = Test::CPAN::Health::Check::SemVer->new->run($dist);
    print $result->summary;

=cut

sub run {
	my ($self, $dist, $context) = @_;

	# Validate positional arg (context is optional; Params::Validate would
	# require hash-style args here, so we validate manually for performance).
	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	my $meta = $dist->meta;

	unless (defined $meta) {
		return $self->_skip('No META.json or META.yml found -- cannot determine version');
	}

	my $version = $meta->version;

	unless (defined $version && length $version) {
		return $self->_result(
			status  => 'fail',
			score   => 0,
			summary => 'Version is missing or empty in META',
			details => ['Add a "version" key to META.json'],
			data    => { name => $self->name },
		);
	}

	# Strict semver check
	if ($version =~ $SEMVER_RE) {
		return $self->_result(
			status  => 'pass',
			score   => 100,
			summary => "Version $version follows Semantic Versioning 2.0",
			data    => { name => $self->name, version => $version },
		);
	}

	# Decimal-style (CPAN convention) -- warn, not fail, because it is legal
	# Perl and the ecosystem is saturated with it.  Nudge towards X.Y.Z.
	if ($version =~ $DECIMAL_RE) {
		return $self->_result(
			status  => 'warn',
			score   => 60,
			summary => "Version $version uses Perl-style decimals, not semver",
			details => [
				'Consider migrating to X.Y.Z format (e.g. "' . _decimal_to_semver($version) . '")',
				'See https://semver.org for the specification',
			],
			data    => { name => $self->name, version => $version },
		);
	}

	# Anything else: epoch, git-describe hash, etc.
	return $self->_result(
		status  => 'fail',
		score   => 0,
		summary => "Version $version does not match any recognised versioning scheme",
		details => [
			"Expected X.Y.Z (semver) or X.YY (Perl decimal); got: $version",
		],
		data    => { name => $self->name, version => $version },
	);
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Best-effort conversion of a decimal version to semver for display in hints.
# 0.27 -> 0.27.0, 1.002003 -> 1.2.3, etc.
# Not used for scoring; only for the human-readable suggestion string.
sub _decimal_to_semver {
	my ($decimal) = @_;

	$decimal =~ s/ ^ v //x;

	# Already has two dots -- might be close to semver already
	return $decimal if $decimal =~ tr/././ >= 2;

	my ($major, $frac) = split / \. /x, $decimal, 2;
	$frac //= '0';

	# Pad fractional part to 6 digits and split into minor+patch
	$frac = sprintf('%-06s', $frac);
	$frac =~ s/ \s /0/gx;
	my $minor = int(substr($frac, 0, 3));
	my $patch = int(substr($frac, 3, 3));

	return "$major.$minor.$patch";
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
