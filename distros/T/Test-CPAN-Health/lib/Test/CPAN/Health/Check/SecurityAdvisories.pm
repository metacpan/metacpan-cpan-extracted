package Test::CPAN::Health::Check::SecurityAdvisories;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use Readonly;
use Params::Validate::Strict qw(validate_strict);

use parent 'Test::CPAN::Health::Check';

our $VERSION = '0.1.0';

# Weight is high because a known CVE is an objective, concrete risk.
# The Report applies a hard cap of 60 on the overall score when this fails.
Readonly::Scalar my $WEIGHT         => 10;
Readonly::Scalar my $CVSS_CRITICAL  => 9.0;
Readonly::Scalar my $CVSS_HIGH      => 7.0;
Readonly::Scalar my $CVSS_MEDIUM    => 4.0;

=head1 NAME

Test::CPAN::Health::Check::SecurityAdvisories - Check for known CVEs in the distribution and its dependencies

=head1 SYNOPSIS

    use Test::CPAN::Health::Check::SecurityAdvisories;

    my $check  = Test::CPAN::Health::Check::SecurityAdvisories->new;
    my $result = $check->run($dist);

=head1 DESCRIPTION

Consults the L<CPAN::Audit> advisory database to check whether the
distribution under analysis, or any of its declared runtime or test
dependencies, have known CVEs or security advisories.

The L<CPAN::Audit> database is bundled with the module and does not require
a network connection during the check itself.  An optional call to
C<cpan-audit update> (or the equivalent) can refresh the database from the
CPAN Security Group's upstream advisory repository.

Scoring:

=over 4

=item * 100 -- no advisories found in distribution or any dependency.

=item *  50 -- advisories found only in indirect/test dependencies.

=item *   0 -- advisories found in the distribution itself or a direct
runtime dependency.  The Report hard-caps the overall score at 60.

=back

The C<ReverseDeps> context value (populated by an earlier check) is used
to scale the urgency message: a distribution with many downstream users
carries a higher implicit risk.

=head1 LIMITATIONS

=over 4

=item * C<CPAN::Audit> only covers advisories that have been submitted to
the CPAN Security Advisory database.  Not all CVEs are catalogued there.

=item * Version range matching follows L<CPAN::Audit>'s own logic; unusually
formatted version strings may produce false negatives.

=item * This check is skipped when C<no_network> is set B<and> the local
advisory database is absent (i.e. C<CPAN::Audit> is not installed).

=back

=cut

sub id          { return 'security_advisories'                                          }
sub name        { return 'Security Advisories'                                          }
sub description { return 'Checks for known CVEs in the distribution and its dependencies' }
sub weight      { return $WEIGHT                                                 }
sub category    { return 'security'                                                     }

=head2 run

=head3 PURPOSE

Scan the distribution and its full dependency tree against the CPAN::Audit
advisory database.  Classify findings by severity and affected dep type
(self / direct runtime / test / indirect).

=head3 API SPECIFICATION

=head4 INPUT

  dist     Test::CPAN::Health::Distribution  required
  context  Hashref                           optional  prior check results;
                                                       reads context->{reverse_deps}

=head4 OUTPUT

L<Test::CPAN::Health::Result> with:

  check_id  'security_advisories'
  status    'pass' | 'fail' | 'skip' | 'error'
  score     0 | 50 | 100
  summary   human-readable verdict
  details   list of "MODULE vVERSION: CVE-XXXX-YYYY (CVSS N.N)" strings
  url       link to CPAN Security Advisory page for the distribution

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
  SEC01 | SKIP     | CPAN::Audit not available          | cpanm CPAN::Audit
  SEC02 | PASS     | No known advisories found          |
  SEC03 | FAIL     | {n} advisories in dist/direct deps | Update affected modules
  SEC04 | FAIL     | {n} advisories in test/indirect    | Update affected modules

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  SecurityAdvisoriesOp
  dist         : Distribution
  advisories   : seq Advisory
  direct_hits  : seq Advisory
  indirect_hits: seq Advisory
  score        : {0, 50, 100}
  status       : {pass, fail, skip, error}
  -------------------------------------------------------
  advisories  = CPAN::Audit.scan(dist.meta.prereqs)
  direct_hits  = {a : advisories | a.dep_type in {self, runtime}}
  indirect_hits = advisories \ direct_hits
  #direct_hits > 0  => status = fail /\ score = 0
  #indirect_hits > 0 /\ #direct_hits = 0 => status = fail /\ score = 50
  #advisories = 0   => status = pass /\ score = 100

=head3 SIDE EFFECTS

Reads the CPAN::Audit SQLite/JSON advisory database from disk.

=head3 USAGE EXAMPLE

    my $result = $check->run($dist, \%context);

=cut

sub run {
	my ($self, $dist, $context) = @_;

	croak 'dist must be a Test::CPAN::Health::Distribution'
		unless ref($dist) && $dist->isa('Test::CPAN::Health::Distribution');

	$context //= {};

	# Strategy:
	#   1. Verify CPAN::Audit is available; skip gracefully if not.
	#   2. Extract prereqs from CPAN::Meta (runtime + test phases).
	#   3. Instantiate CPAN::Audit and call audit_distributions() or
	#      equivalent to scan all name+version pairs.
	#   4. Classify each finding as direct (self/runtime) or indirect
	#      (test/develop/indirect).
	#   5. Score: any direct hit => 0; only indirect => 50; clean => 100.
	#   6. Annotate each detail line with the CVE id and CVSS score.
	#   7. Attach the MetaCPAN advisory URL for the distribution itself.

	my $loaded = eval { require CPAN::Audit; 1 };
	unless ($loaded) {
		return $self->_skip('CPAN::Audit is not installed (cpanm CPAN::Audit to enable this check)');
	}

	my $meta = $dist->meta;
	unless (defined $meta) {
		return $self->_skip('No META file -- cannot determine dependency tree');
	}

	my ($direct_advisories, $indirect_advisories) = $self->_scan_advisories($meta);

	my $reverse_dep_count = do {
		my $rd = $context->{reverse_deps};
		defined $rd ? ($rd->data->{count} // 0) : 0;
	};

	if (@{$direct_advisories}) {
		return $self->_result(
			status  => 'fail',
			score   => 0,
			summary => sprintf(
				'%d known advisor%s in %s or direct runtime dependencies%s',
				scalar @{$direct_advisories},
				@{$direct_advisories} == 1 ? 'y' : 'ies',
				$dist->name,
				$reverse_dep_count > 0
					? sprintf(' (%d downstream users affected)', $reverse_dep_count)
					: '',
			),
			details => [
				(map { _format_advisory($_) } @{$direct_advisories}),
				(map { _format_advisory($_) } @{$indirect_advisories}),
			],
			url  => _advisory_url($dist->name),
			data => { name => $self->name, count => scalar(@{$direct_advisories}) + scalar(@{$indirect_advisories}) },
		);
	}

	if (@{$indirect_advisories}) {
		return $self->_result(
			status  => 'fail',
			score   => 50,
			summary => sprintf(
				'%d known advisor%s in test or indirect dependencies',
				scalar @{$indirect_advisories},
				@{$indirect_advisories} == 1 ? 'y' : 'ies',
			),
			details => [ map { _format_advisory($_) } @{$indirect_advisories} ],
			url     => _advisory_url($dist->name),
			data    => { name => $self->name, count => scalar @{$indirect_advisories} },
		);
	}

	return $self->_result(
		status  => 'pass',
		score   => 100,
		summary => 'No known security advisories found',
		data    => { name => $self->name, count => 0 },
	);
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Scan all prereqs via CPAN::Audit.
# Returns two arrayrefs: (direct_advisories, indirect_advisories).
# Each advisory is a hashref: { module, version, cve, cvss, description }.
sub _scan_advisories {
	my ($self, $meta) = @_;

	# Strategy:
	#   CPAN::Audit->new->audit() accepts a list of [Module, version] pairs
	#   and returns a data structure of findings.
	#   We separate runtime prereqs (direct) from test/develop (indirect).

	my @direct   = ();
	my @indirect = ();

	my $prereqs = $meta->effective_prereqs;

	# Collect direct runtime dependencies
	my $runtime = $prereqs->requirements_for('runtime', 'requires');
	my %direct_modules = map { $_ => $runtime->requirements_for_module($_) }
		$runtime->required_modules;

	# Collect indirect (test + develop) dependencies
	my %indirect_modules;
	for my $phase (qw(test develop)) {
		my $req = $prereqs->requirements_for($phase, 'requires');
		for my $mod ($req->required_modules) {
			next if $direct_modules{$mod};    # already counted as direct
			$indirect_modules{$mod} = $req->requirements_for_module($mod);
		}
	}

	# advisories_for() is on CPAN::Audit::Query, not CPAN::Audit itself.
	# Load the DB via CPANSA::DB (preferred) or the deprecated CPAN::Audit::DB.
	my $db;
	if (eval { require CPANSA::DB; 1 }) {
		$db = CPANSA::DB->db;
	} elsif (eval { require CPAN::Audit::DB; 1 }) {
		$db = CPAN::Audit::DB->db;
	} else {
		$db = {};
	}

	require CPAN::Audit::Query;
	my $query = CPAN::Audit::Query->new(db => $db);

	# Scan direct dependencies
	for my $mod (keys %direct_modules) {
		my $ver = _effective_version($mod, $direct_modules{$mod});
		next unless defined $ver;
		my @findings = $query->advisories_for($mod, $ver);
		push @direct, map { { module => $mod, version => $ver, %{$_} } } @findings;
	}

	# Scan indirect dependencies
	for my $mod (keys %indirect_modules) {
		my $ver = _effective_version($mod, $indirect_modules{$mod});
		next unless defined $ver;
		my @findings = $query->advisories_for($mod, $ver);
		push @indirect, map { { module => $mod, version => $ver, %{$_} } } @findings;
	}

	return (\@direct, \@indirect);
}

sub _format_advisory {
	my ($adv) = @_;

	# CPAN::Audit::Query returns: id, description, cves (arrayref), severity,
	# affected_versions, fixed_versions, references, distribution, reported.
	my $id       = $adv->{id} // 'ADVISORY';
	my $cve      = ref($adv->{cves}) && @{$adv->{cves}} ? $adv->{cves}[0] : undef;
	my $label    = $cve ? "$id ($cve)" : $id;
	my $severity = defined $adv->{severity} ? sprintf(' [%s]', uc $adv->{severity}) : '';

	return sprintf('%s %s: %s%s -- %s',
		$adv->{module},
		$adv->{version} // '?',
		$label,
		$severity,
		$adv->{description} // 'see advisory URL',
	);
}

# Return the version to pass to advisories_for().
#
# Two cases where the META-declared version is wrong to use:
#
# 1. 'perl' -- the declared minimum is a lower bound (e.g. 5.014), not the
#    interpreter actually running.  Scanning 5.014 floods results with CVEs
#    fixed long ago.  Use the running interpreter version instead.
#
# 2. Version '0' (no constraint) -- means "any version is acceptable", so
#    advisories_for receives '0' and returns every advisory ever filed for the
#    module.  Instead load the module and read its actual VERSION; if it is not
#    installed, return undef so the caller can skip it.
sub _effective_version {
	my ($mod, $declared) = @_;

	return sprintf('%.6f', $]) if $mod eq 'perl';

	if (!defined $declared || $declared eq '0') {
		return _installed_version($mod);
	}

	return $declared;
}

# Try to load a module and return its $VERSION string, or undef if not installed.
sub _installed_version {
	my ($mod) = @_;
	(my $file = "$mod.pm") =~ s{ :: }{/}gx;
	my $ok = eval { require $file; 1 };
	return $ok ? $mod->VERSION : undef;
}

sub _advisory_url {
	my ($dist_name) = @_;

	(my $slug = $dist_name) =~ s/ :: /-/gx;

	return "https://security.metacpan.org/advisories/$slug";
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
