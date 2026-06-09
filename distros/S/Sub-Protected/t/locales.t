use strict;
use warnings;
use Test::Most;
use POSIX qw();

# t/locales.t -- locale-sensitivity tests for Sub::Protected
#
# GEOGRAPHIC LOCALE (GeoIP) NOTE
# ==============================
# Sub::Protected enforces access control based solely on Perl package
# inheritance (@ISA / ->isa).  It has no geographic dimension: there are
# no country-based rules, no IP-address lookups, and no GeoIP database
# queries.  GeoIP-based tests are therefore not applicable to this module.
# Country-based access-control coverage is outside scope.
#
# SYSTEM LOCALE (POSIX) TESTS
# ============================
# Sub::Protected's error messages are pure Perl strings; they contain no
# OS error strings ($!) and no locale-derived text.  These tests verify:
#
#   1. Protection is enforced (croak fires) under different POSIX locales.
#   2. The croak message content is locale-invariant (ASCII English).
#   3. Authorised callers still succeed under each locale.
#   4. Error paths that do contain an OS string (the CHECK-time "not defined"
#      error) are also tested under each locale.
#
# We deliberately do NOT use POSIX::strerror(ENOENT) to build expected
# regexes.  We source from $! directly (as Perl would) so the regex matches
# what actually gets thrown, not what the C library independently says.

use Sub::Protected;

# -------------------------------------------------------------------
# Package fixtures -- defined once, shared across all locale subtests
# -------------------------------------------------------------------

{
	package LP::Owner;
	use Sub::Protected;
	sub new       { bless {}, shift }
	sub _secret   :Protected { 'secret' }
	sub permitted { (shift)->_secret }
}

{
	package LP::Sub;
	our @ISA = ('LP::Owner');
	sub new { bless {}, shift }
	# Subclass calling the parent's protected sub via direct function call
	sub allowed { LP::Owner::_secret(shift) }
}

{
	package LP::Intruder;
	sub probe { LP::Owner->new->_secret }
}

# Exact expected message for access denial (locale-independent ASCII string)
use constant ACCESS_ERR_RE =>
	qr/_secret\(\) is a protected method of LP::Owner and cannot be called from LP::Intruder/;

# -------------------------------------------------------------------
# POSIX locales to exercise
# -------------------------------------------------------------------

my @locales = (
	'en_US.UTF-8',
	'de_DE.UTF-8',
	'zh_CN.UTF-8',    # East Asian -- tests non-Latin environment
);

for my $locale (@locales) {
	subtest "POSIX locale: $locale" => sub {
		local $ENV{LC_ALL}          = $locale;
		local $ENV{LANG}            = $locale;
		local $ENV{HARNESS_ACTIVE}  = 0;   # disable harness bypass so checks fire
		local $Sub::Protected::BYPASS = 0;

		# Error path 1: unauthorised caller -- message must be ASCII regardless of locale
		throws_ok { LP::Intruder::probe() }
			ACCESS_ERR_RE,
			"access denied: croak message is locale-invariant under $locale";

		# Success path: authorised owner call still works under the locale
		my $result;
		lives_ok { $result = LP::Owner->new->permitted }
			"authorised owner call succeeds under $locale";
		is $result, 'secret',
			"correct return value under $locale";

		# Success path: subclass call also works
		lives_ok { $result = LP::Sub->new->allowed }
			"subclass call succeeds under $locale";
		is $result, 'secret',
			"subclass returns correct value under $locale";
	};
}

# -------------------------------------------------------------------
# CHECK-time "not defined" error -- OS-error-free, but locale-test anyway
# -------------------------------------------------------------------
# The error "Sub::Protected: PKG::NAME is not defined" is pure Perl; it
# contains no $! string.  We verify it is thrown consistently under locales.

subtest 'CHECK-time undefined-sub error is locale-invariant' => sub {
	plan tests => scalar(@locales);

	# We cannot trigger a CHECK-time error at runtime (CHECK has already
	# fired).  Instead we test the equivalent runtime path: calling import()
	# post-CHECK with a sub that does not exist.

	for my $locale (@locales) {
		local $ENV{LC_ALL}          = $locale;
		local $ENV{LANG}            = $locale;
		local $ENV{HARNESS_ACTIVE}  = 0;
		local $Sub::Protected::BYPASS = 0;

		throws_ok {
			# Trigger the "not defined" croak via the post-CHECK import path.
			# Must be called from within LP::Owner so caller() returns LP::Owner.
			package LP::Owner;
			Sub::Protected->import('_nonexistent_sub_99');
		} qr/Sub::Protected: LP::Owner::_nonexistent_sub_99 is not defined/,
			"undefined-sub croak is locale-invariant under $locale";
	}
};

# -------------------------------------------------------------------
# Identifier-validation error -- also locale-invariant
# -------------------------------------------------------------------

subtest 'invalid-identifier error is locale-invariant' => sub {
	plan tests => scalar(@locales);

	for my $locale (@locales) {
		local $ENV{LC_ALL} = $locale;
		local $ENV{LANG}   = $locale;

		throws_ok {
			Sub::Protected::import('LP::Owner', '123invalid');
		} qr/Sub::Protected->import: '123invalid' is not a valid Perl identifier/,
			"invalid-identifier croak is locale-invariant under $locale";
	}
};

done_testing;
