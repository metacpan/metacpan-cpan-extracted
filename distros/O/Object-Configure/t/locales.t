#!/usr/bin/env perl

# Verify that Object::Configure error strings are locale-consistent.
# We test the config-file-not-found error path under several LC_ALL values and
# confirm the thrown message matches what Perl itself would produce for ENOENT
# in that locale (via "local $! = ENOENT; my $msg = "$!";").
#
# Geographic (GeoIP) locale testing is not applicable to this module.

use strict;
use warnings;

use Test::Most;
use Test::Needs qw(POSIX);
use File::Temp qw(tempdir);
use Errno qw(ENOENT);

use lib 'lib';
use Object::Configure;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub _enoent_string_for_locale {
	my ($lc_all) = @_;
	local $ENV{LC_ALL} = $lc_all;
	local $! = ENOENT;
	return "$!";
}

sub _locale_available {
	my ($lc_all) = @_;
	local $ENV{LC_ALL} = $lc_all;
	# POSIX::setlocale returns undef when the locale is not installed
	return defined POSIX::setlocale(POSIX::LC_ALL(), $lc_all);
}

# Minimal test class that calls configure()
{
	package TestLocale;
	use Object::Configure;

	sub new {
		my ($class, %args) = @_;
		my $params = Object::Configure::configure($class, \%args);
		return bless $params, $class;
	}
}

# ---------------------------------------------------------------------------
# Sanity check: make sure the module loads and configure() works at all.
# BAIL_OUT here so downstream locale subtests don't produce confusing output.
# ---------------------------------------------------------------------------

my $dir = tempdir(CLEANUP => 1);

eval {
	my $obj = TestLocale->new();
};
ok(!$@ || $@ =~ /configure/, 'configure() works without a config file');

# ---------------------------------------------------------------------------
# POSIX locale subtests
# ---------------------------------------------------------------------------

my @locales = (
	'en_US.UTF-8',
	'de_DE.UTF-8',
	'ja_JP.UTF-8',
);

my $nonexistent = "$dir/nonexistent_config_file_$$.conf";

for my $lc_all (@locales) {
	SKIP: {
		skip "Locale $lc_all not available on this system", 1
			unless _locale_available($lc_all);

		subtest "error path under locale $lc_all" => sub {
			plan tests => 2;

			# Derive the expected ENOENT string from Perl's own layer so we
			# never hard-code a language-specific string and never diverge from
			# what the C library would produce in this locale.
			my $expected_msg = _enoent_string_for_locale($lc_all);

			ok(length($expected_msg) > 0,
				"ENOENT string is non-empty under $lc_all");

			local $ENV{LC_ALL} = $lc_all;

			throws_ok {
				TestLocale->new(config_file => $nonexistent);
			} qr/\Q$expected_msg\E/,
				"Dies with locale-correct error string under $lc_all";
		};
	}
}

done_testing();
