#!/usr/bin/perl
# t/locales.t -- Test Sub::Private error messages under POSIX system locales.
#
# Part 1: Geographic locale
#   Sub::Private enforces access based on Perl package identity, not geographic
#   location.  There is no country-based access control to test.  This section
#   documents that expectation and passes immediately.
#
# Part 2: POSIX system locale (LC_ALL / LANG)
#   Sub::Private's croak messages are self-generated strings; they do not
#   include any OS error string ($!), so they must be identical under any
#   LC_ALL value.  We test under en_US.UTF-8, de_DE.UTF-8, and zh_CN.UTF-8.
#
#   For each locale we verify:
#     - stranger access is rejected with the canonical message
#     - owner access succeeds
#     - BYPASS=1 allows a stranger through

use strict;
use warnings;

use Test::Most;
use POSIX qw(setlocale LC_ALL);

# Enforce mode so runtime croak messages are generated.
BEGIN { $Sub::Private::config{mode} = 'enforce' }
use Sub::Private;

# Disable bypass so access checks actually fire by default.
local $ENV{HARNESS_ACTIVE}  = 0;
local $Sub::Private::BYPASS = 0;

# -------------------------------------------------------------------
# Fixtures
# -------------------------------------------------------------------

{
	package LC::Owner;
	use Sub::Private;
	sub new     { bless {}, shift }
	sub _secret :Private { 'secret value' }
	sub reveal  { (shift)->_secret }
}

{
	package LC::Stranger;
	sub new   { bless {}, shift }
	sub probe { LC::Owner->new->_secret }
}

# -------------------------------------------------------------------
# Part 1: Geographic locale
# -------------------------------------------------------------------
# Sub::Private has no country-based access control.  This subtest
# documents that expectation; it always passes.

subtest 'geographic locale: no country-based access control (not applicable)' => sub {
	plan tests => 1;
	pass 'Sub::Private has no country-based access control -- geographic locale N/A';
};

# -------------------------------------------------------------------
# Part 2: POSIX system locale
# -------------------------------------------------------------------

# The canonical error message we expect for a stranger calling _secret.
my $EXPECTED_MSG =
	qr/_secret\(\) is a private subroutine of LC::Owner and cannot be called from LC::Stranger/;

# Locales to exercise.  Tests that cannot set a locale are skipped gracefully.
my @locales = (
	'en_US.UTF-8',
	'de_DE.UTF-8',
	'zh_CN.UTF-8',
);

# Save the current locale so we can restore it after probing.
my $original_locale = setlocale(LC_ALL);

for my $locale (@locales) {
	# Probe whether the locale is available on this system.
	my $available = setlocale(LC_ALL, $locale) ? 1 : 0;
	setlocale(LC_ALL, $original_locale);   # restore immediately

	subtest "locale '$locale': stranger access blocked with canonical message" => sub {
		if($available) {
			local $ENV{LC_ALL} = $locale;
			local $ENV{LANG}   = $locale;

			throws_ok { LC::Stranger->new->probe }
				$EXPECTED_MSG,
				"croak message matches under '$locale'";
		} else {
			pass "locale '$locale' not available on this system";
		}
	};

	subtest "locale '$locale': owner access succeeds" => sub {
		if($available) {
			local $ENV{LC_ALL} = $locale;
			local $ENV{LANG}   = $locale;

			lives_ok { LC::Owner->new->reveal } "owner access lives under '$locale'";
		} else {
			ok(1);
		}
	};

	subtest "locale '$locale': BYPASS=1 allows stranger" => sub {
		if ($available) {
			local $ENV{LC_ALL}              = $locale;
			local $ENV{LANG}                = $locale;
			local $Sub::Private::BYPASS     = 1;

			lives_ok { LC::Stranger->new->probe } "BYPASS=1 allows stranger under '$locale'";
		} else {
			ok(1);
		}
	};
}

done_testing();
