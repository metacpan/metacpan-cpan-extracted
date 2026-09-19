use strict;
use warnings;

use Test::Most;
use POSIX qw(ENOENT);

use lib 'lib';
use_ok('Music::NWC2MusicXML::NWC');
use_ok('Music::NWC2MusicXML::Parser');

# ---------------------------------------------------------------------------
# NOTE: Geographic GeoIP locale testing is not applicable to this project.
# This module is a file-format converter with no network or GeoIP components.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# POSIX locale tests
#
# Goal: verify that our croak paths fire correctly under different system
# locales, even when the underlying OS error string ($!) changes language.
# Our modules use hardcoded English message templates (%MESSAGES), so they
# are locale-independent; only the embedded $! strings may vary.
#
# Pattern: local $! = ENOENT; my $msg = "$!";
# This sources the errno string via Perl's own layer (not POSIX::strerror),
# preventing C-library divergence across platforms.
# ---------------------------------------------------------------------------

my @locales = ('en_US.UTF-8', 'de_DE.UTF-8', 'C');

# Sanity: verify we can test at all.  If locale support is absent (common on
# minimal CI images), skip gracefully rather than producing false failures.
{
	my $locale_ok = 0;
	for my $loc (@locales) {
		my $prev = $ENV{LC_ALL} // '';
		local $ENV{LC_ALL} = $loc;
		local $! = ENOENT;
		my $msg = "$!";
		$locale_ok = 1 if length $msg;
		$ENV{LC_ALL} = $prev;
	}
	unless ($locale_ok) {
		plan skip_all => 'Cannot retrieve errno strings; locale support may be absent';
	}
}

# ---------------------------------------------------------------------------
# Under each locale, trigger a croak path in NWC::read (missing file) and
# verify that:
#   (a) the exception IS thrown (dies_ok / throws_ok)
#   (b) our module's message prefix is present (locale-independent)
#   (c) we do not accidentally swallow the error
# ---------------------------------------------------------------------------
for my $loc (@locales) {
	subtest "NWC::read croaks for missing file under locale $loc" => sub {
		local $ENV{LC_ALL} = $loc;

		# Source the locale's ENOENT string without using POSIX::strerror
		local $! = ENOENT;
		my $os_enoent = "$!";

		my $nwc = Music::NWC2MusicXML::NWC->new;

		throws_ok {
			$nwc->read('/tmp/__nwc2musicxml_does_not_exist_$$.nwc');
		} qr/Cannot read file|not found/i,
		  "NWC::read throws for missing file (locale=$loc)";

		note "ENOENT under $loc: $os_enoent";
	};
}

# ---------------------------------------------------------------------------
# Under each locale, Parser::parse croak path (empty input)
# ---------------------------------------------------------------------------
for my $loc (@locales) {
	subtest "Parser::parse croaks for empty input under locale $loc" => sub {
		local $ENV{LC_ALL} = $loc;

		my $p = Music::NWC2MusicXML::Parser->new;

		throws_ok { $p->parse(undef) }
			qr/empty/i,
			"Parser::parse croaks for undef input (locale=$loc)";

		throws_ok { $p->parse('') }
			qr/empty/i,
			"Parser::parse croaks for empty string (locale=$loc)";
	};
}

# ---------------------------------------------------------------------------
# Concurrent instances: two NWC decoders under different locales do not
# interfere with each other's error paths.
# ---------------------------------------------------------------------------
{
	subtest 'concurrent NWC instances under different locales do not interfere' => sub {
		my $nwc_a = Music::NWC2MusicXML::NWC->new;
		my $nwc_b = Music::NWC2MusicXML::NWC->new;

		my ($err_a, $err_b);

		{
			local $ENV{LC_ALL} = 'en_US.UTF-8';
			eval { $nwc_a->read('/tmp/__nwc2musicxml_a_$$.nwc') };
			$err_a = $@;
		}
		{
			local $ENV{LC_ALL} = 'C';
			eval { $nwc_b->read('/tmp/__nwc2musicxml_b_$$.nwc') };
			$err_b = $@;
		}

		ok length($err_a), 'instance A raised an error';
		ok length($err_b), 'instance B raised an error';
		like $err_a, qr/Cannot read file|not found/i, 'instance A error message correct';
		like $err_b, qr/Cannot read file|not found/i, 'instance B error message correct';
	};
}

done_testing();
