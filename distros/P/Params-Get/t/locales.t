#!/usr/bin/env perl

# Verify that Params::Get error messages are locale-independent.
#
# GeoIP tests are not applicable: this module has no geographic access
# controls or country-based logic.
#
# POSIX locale tests confirm that our hardcoded ASCII croak/confess strings
# do not accidentally incorporate OS-localised error text (e.g. from $!).

use strict;
use warnings;

use Test::Most;
use POSIX qw(LC_ALL ENOENT);

# Locales to exercise.  We probe availability at runtime because not every
# system installs all locale data.
my @wanted = (
	'en_US.UTF-8',
	'de_DE.UTF-8',
	'ja_JP.UTF-8',	# East Asian -- catches byte-level charset assumptions
	'C',		# portable ASCII baseline, always available
);

my @available;
for my $loc (@wanted) {
	# Attempt to set the locale; POSIX::setlocale returns undef on failure.
	my $got = POSIX::setlocale(LC_ALL, $loc);
	push @available, $loc if defined $got;
}

# Restore a sane locale for the rest of the setup.
POSIX::setlocale(LC_ALL, 'C');

plan skip_all => 'No testable POSIX locales available on this system'
	unless @available;

use_ok('Params::Get', 'get_params') or BAIL_OUT('Params::Get failed to load');

for my $locale (@available) {
	subtest "POSIX locale: $locale" => sub {
		# Switch locale for the duration of this subtest.
		local $ENV{LC_ALL} = $locale;
		POSIX::setlocale(LC_ALL, $locale);

		# 1. croak when $default defined but no args -- message must say "Usage".
		my $croak_msg;
		eval { Params::Get::get_params('required_key') };
		$croak_msg = $@;
		like(
			$croak_msg,
			qr/Usage/,
			"[$locale] confess on missing arg contains 'Usage'"
		);

		# 2. The croak message must not contain any OS-localised error string.
		#    We source the OS string via Perl's $! layer (NOT POSIX::strerror)
		#    to match exactly what Perl would interpolate in practice.
		{
			local $! = ENOENT;
			my $os_err = "$!";	# e.g. "No such file or directory" / "Datei oder Verzeichnis nicht gefunden"
			unlike(
				$croak_msg,
				qr/\Q$os_err\E/,
				"[$locale] error message does not contain OS string '$os_err'"
			);
		}

		# 3. croak on unrecognisable args -- message must say "Usage".
		my $bad_msg;
		eval { get_params(undef, 'lone_scalar_no_default') };
		$bad_msg = $@;
		like(
			$bad_msg,
			qr/Usage/,
			"[$locale] croak on bad args contains 'Usage'"
		);

		# 4. Normal operation must be unaffected by locale.
		is_deeply(
			get_params(undef, foo => 'bar', baz => 42),
			{ foo => 'bar', baz => 42 },
			"[$locale] named pairs work correctly"
		);

		is_deeply(
			get_params('country', 'DE'),
			{ country => 'DE' },
			"[$locale] scalar default works correctly"
		);

		is_deeply(
			get_params([qw(lang region)], 'de', 'DE'),
			{ lang => 'de', region => 'DE' },
			"[$locale] arrayref default positional mapping works"
		);
	};
}

# Restore locale so later test files (if any) are not affected.
POSIX::setlocale(LC_ALL, 'C');

done_testing();
