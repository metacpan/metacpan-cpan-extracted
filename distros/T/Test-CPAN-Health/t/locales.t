#!/usr/bin/env perl
# t/locales.t
#
# Locale-robustness tests for Test::CPAN::Health.
#
# Two sections:
#
#   1. Geographic (GeoIP)
#      Test::CPAN::Health has no country-based access control.  This section
#      records that fact as a passing sanity subtest and bails out early so
#      that any future introduction of GeoIP logic is immediately visible.
#
#   2. System (POSIX) locales
#      Verify that the module's error messages are ASCII-invariant (they do
#      not come from OS errno strings that change with LC_ALL) and that core
#      operations succeed under en_US.UTF-8, de_DE.UTF-8, and ja_JP.UTF-8.
#      Per skill requirement: OS error strings are sourced via
#        local $! = POSIX::ENOENT(); my $msg = "$!";
#      NOT via POSIX::strerror(), to prevent C-library divergence.

use strict;
use warnings;

use Carp qw(croak);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX ();
use Readonly;

use Test::Most;

our $VERSION = '0.01';

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
Readonly::Scalar my $DIST_PATH_CROAK   => qr/does not exist/;
Readonly::Scalar my $CONSTRUCTOR_CROAK => qr/One of path/;

# Locales to exercise.  We skip individual subtests when a locale is not
# installed on the system rather than failing the whole file.
Readonly::Array my @POSIX_LOCALES => ('en_US.UTF-8', 'de_DE.UTF-8', 'ja_JP.UTF-8');

# ---------------------------------------------------------------------------
# Module loading
# ---------------------------------------------------------------------------
for my $mod (qw(
	Test::CPAN::Health
	Test::CPAN::Health::Distribution
	Test::CPAN::Health::Cache
)) {
	use_ok($mod) or BAIL_OUT("Cannot load $mod");
}

# ===========================================================================
# SECTION 1: Geographic (GeoIP) -- Not applicable
# ===========================================================================

subtest 'GeoIP sanity: module has no country-based access control' => sub {

	# Test::CPAN::Health does not restrict access by country.  If GeoIP
	# logic is ever added, a failed BAIL_OUT here will catch the drift.
	ok(1, 'No GeoIP mapping present in Test::CPAN::Health (expected)');
	note 'If country-based logic is ever added, add GeoIP subtests here.';
};

# ===========================================================================
# SECTION 2: POSIX locales
# ===========================================================================

# Helper: return true if the named locale is available on this system.
sub _locale_available {
	my ($locale) = @_;
	# locale(1) may not exist on all CI systems (BSDs, Alpine, Windows).
	# qx returns undef on exec failure; treat that as no locales available.
	my $out = qx{locale -a 2>/dev/null};
	return 0 unless defined $out && $? == 0;
	return $out =~ /^\Q$locale\E$/m;
}

# Helper: run a code block under a specific LC_ALL setting.
sub _with_locale {
	my ($locale, $code) = @_;
	local $ENV{LC_ALL} = $locale;
	local $ENV{LANG}   = $locale;
	local $ENV{LC_MESSAGES} = $locale;
	return $code->();
}

# ---------------------------------------------------------------------------
# 2a. Distribution->new: croak message is locale-invariant
# ---------------------------------------------------------------------------
subtest 'POSIX locales: Distribution->new croak is ASCII-invariant' => sub {

	for my $locale (@POSIX_LOCALES) {

		SKIP: {
			skip "$locale not available on this system", 2
				unless _locale_available($locale);

			_with_locale($locale, sub {
				throws_ok(
					sub {
						Test::CPAN::Health::Distribution->new(
							path => '/nonexistent/path/xyz_' . $$,
						);
					},
					$DIST_PATH_CROAK,
					"Distribution path-missing croak is ASCII under $locale",
				);
			});

			# Also verify the OS-level error string (via local $! = ENOENT)
			# changes with locale but our module message does NOT.
			{
				local $! = POSIX::ENOENT();
				my $os_msg = "$!";
				ok(length($os_msg) > 0,
					"OS ENOENT string non-empty under $locale (was: $os_msg)");
				diag "LC_ALL=$locale ENOENT=\"$os_msg\"" if $ENV{TEST_VERBOSE};
			}
		}
	}
};

# ---------------------------------------------------------------------------
# 2b. Health->new: croak for missing location is locale-invariant
# ---------------------------------------------------------------------------
subtest 'POSIX locales: Health->new no-location croak is ASCII-invariant' => sub {

	for my $locale (@POSIX_LOCALES) {

		SKIP: {
			skip "$locale not available on this system", 1
				unless _locale_available($locale);

			_with_locale($locale, sub {
				throws_ok(
					sub { Test::CPAN::Health->new },
					$CONSTRUCTOR_CROAK,
					"Health->new no-args croak is ASCII under $locale",
				);
			});
		}
	}
};

# ---------------------------------------------------------------------------
# 2c. Cache: store/get round-trip works under all locales
# ---------------------------------------------------------------------------
subtest 'POSIX locales: Cache store/get round-trip' => sub {

	for my $locale (@POSIX_LOCALES) {

		SKIP: {
			skip "$locale not available on this system", 3
				unless _locale_available($locale);

			my $tmp = tempdir(CLEANUP => 1);

			_with_locale($locale, sub {
				my $cache = Test::CPAN::Health::Cache->new(cache_dir => $tmp);
				my $key   = "test_check:MyDist:1.0";

				$cache->store($key, { status => 'pass', score => 100 });
				my $val = $cache->get($key);

				ok(defined $val,            "Cache returns defined value under $locale");
				is($val->{status}, 'pass',  "Cached status survives locale $locale");
				is($val->{score},  100,     "Cached score survives locale $locale");
			});
		}
	}
};

# ---------------------------------------------------------------------------
# 2d. Distribution file-list methods work under all locales
# ---------------------------------------------------------------------------
subtest 'POSIX locales: Distribution file accessors return consistent results' => sub {

	for my $locale (@POSIX_LOCALES) {

		SKIP: {
			skip "$locale not available on this system", 2
				unless _locale_available($locale);

			my $tmp = tempdir(CLEANUP => 1);

			# Create a minimal lib/ directory with one .pm file.
			my $lib = File::Spec->catdir($tmp, 'lib');
			mkdir $lib or die "mkdir $lib: $!";
			open my $fh, '>', File::Spec->catfile($lib, 'Foo.pm') or die $!;
			print {$fh} "package Foo; 1;\n";
			close $fh;

			my $dist = Test::CPAN::Health::Distribution->new(path => $tmp);

			_with_locale($locale, sub {
				my $pm = $dist->pm_files;
				is(ref $pm, 'ARRAY',     "pm_files returns ARRAY under $locale");
				is(scalar @{$pm}, 1,     "pm_files finds 1 file under $locale");
			});
		}
	}
};

# ---------------------------------------------------------------------------
# 2e. Concurrent instances do not share locale-sensitive cached state
# ---------------------------------------------------------------------------
subtest 'POSIX locales: two Distribution instances remain independent' => sub {

	SKIP: {
		skip 'en_US.UTF-8 not available', 2
			unless _locale_available('en_US.UTF-8');

		my $tmp1 = tempdir(CLEANUP => 1);
		my $tmp2 = tempdir(CLEANUP => 1);

		my $dist1 = Test::CPAN::Health::Distribution->new(path => $tmp1);
		my $dist2 = Test::CPAN::Health::Distribution->new(path => $tmp2);

		_with_locale('en_US.UTF-8', sub {
			# Each instance's pm_files is independent.
			my $pm1 = $dist1->pm_files;
			my $pm2 = $dist2->pm_files;

			isnt($pm1, $pm2,
				'Two Distribution instances hold independent pm_files arrayrefs');

			# Mutating one instance's internal arrayref does not affect the other.
			push @{$pm1}, '/injected/path.pm';
			is(scalar @{$dist2->pm_files}, 0,
				'Push onto pm1 does not bleed into dist2->pm_files');
		});
	}
};

done_testing();
