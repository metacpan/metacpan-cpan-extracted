#!/usr/bin/env perl

# ---------------------------------------------------------------------------
# t/unit.t -- black-box unit tests for Schema::Validator
#
# Tests ONLY the two public functions as documented in their POD:
#   is_valid_datetime      -- ISO 8601 validation
#   load_dynamic_vocabulary -- Schema.org JSON-LD vocabulary loader
#
# External dependencies (LWP::UserAgent, DateTime::Format::ISO8601) are
# mocked via Test::Mockingbird so no real network access occurs.  The
# filesystem is exercised with File::Temp scratch files to exercise the
# cache paths realistically.
#
# Cross-references between POD and code:
#   * is_valid_datetime PURPOSE was updated: timezone offsets ARE accepted,
#     calendar sanity IS enforced (both contradicted the original PURPOSE text).
#   * is_valid_datetime API spec was corrected: optional => 0 (required key).
#   * load_dynamic_vocabulary NOTES was updated: bin/validate-schema now
#     imports from this module rather than duplicating the logic.
# ---------------------------------------------------------------------------

use strict;
use warnings;

use FindBin qw($Bin);
# Under prove -t (taint mode), $Bin is tainted; detaint before use lib.
use lib (do {
	(my $d = $Bin) =~ /\A(.*)\z/s;
	("$1/../lib",
	 "$1/../../Test-Mockingbird/lib",
	 "$1/../../Test-Returns/lib");
});

use File::Temp     qw(tempfile);
use Scalar::Util   qw(blessed reftype);
use Test::Most;
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Returns;
use Test::Warn;

# Load the module under test; mocks are scoped per subtest.
use Schema::Validator qw(is_valid_datetime load_dynamic_vocabulary);

# ===========================================================================
# CONSTANTS -- all magic strings and numbers confined here.
# ===========================================================================

use Readonly;

# Schema.org JSON-LD with one class (Thing) and one property (name).
# This is the minimal structure that load_dynamic_vocabulary can parse.
Readonly::Scalar my $VALID_JSONLD =>
	'{"@graph":['
	. '{"@type":"rdfs:Class","rdfs:label":"Thing","@id":"https://schema.org/Thing"},'
	. '{"@type":"rdf:Property","rdfs:label":"name","@id":"https://schema.org/name"}'
	. ']}';

# Syntactically invalid JSON -- no decoder can parse this.
Readonly::Scalar my $BAD_JSON => '{not:"valid"json}';

# Syntactically valid JSON but without the required @graph array.
Readonly::Scalar my $NO_GRAPH_JSON => '{"version":23,"@context":"https://schema.org/"}';

# Fake URL passed to load_dynamic_vocabulary; never actually fetched.
Readonly::Scalar my $FAKE_URL => 'https://schema.invalid/vocab.jsonld';

# Duration in seconds where any file is treated as stale (0 = always stale).
Readonly::Scalar my $STALE_DURATION => 0;

# Duration that keeps a file created moments ago within the fresh window.
Readonly::Scalar my $FRESH_DURATION => 86_400;

# ===========================================================================
# CONFIGURATION -- runtime string/numeric values indexed by name.
# ===========================================================================

my %config = (
	# Valid ISO 8601 date/datetime inputs from the POD EXAMPLE section
	date_only        => '2024-11-14',
	dt_t_hhmm        => '2024-11-14T15:30',
	dt_t_hhmmss      => '2024-11-14T15:30:00',
	dt_space_hhmm    => '2024-11-14 15:30',
	dt_space_hhmmss  => '2024-11-14 15:30:00',
	dt_tz_z          => '2024-11-14T15:30:00Z',
	dt_tz_plus       => '2024-11-14T15:30:00+01:00',
	dt_tz_minus      => '2024-11-14T15:30:00-05:00',

	# Invalid inputs that must return 0
	date_bad_month   => '2024-99-01',
	date_bad_day     => '2024-11-99',
	date_dmy         => '28/06/2025',
	date_mmdash      => '06-28-2025',

	# Schema.org class/property labels used in VALID_JSONLD above
	class_thing      => 'Thing',
	prop_name        => 'name',
);

# ===========================================================================
# HELPER: build a minimal FakeResponse for LWP mocking
# ===========================================================================

{
	# Minimal HTTP::Response stand-in.  Only the three methods called by
	# _fetch_url are needed: is_success, decoded_content, status_line.
	package FakeResponse;
	sub new             { bless { ok => $_[1], body => $_[2] }, $_[0] }
	sub is_success      { $_[0]->{ok}   }
	sub decoded_content { $_[0]->{body} }
	sub status_line     { $_[0]->{ok} ? '200 OK' : '503 Service Unavailable' }
}

# Helper: write $content to $path with a plain open so we never depend on
# the module's own _spit_file in tests that are about other code paths.
sub _write_file {
	my ($path, $content) = @_;
	open my $fh, '>', $path or die "Cannot write '$path': $!";
	print $fh $content;
	close $fh;
}

# ===========================================================================
# SUBTESTS: is_valid_datetime (POD section "is_valid_datetime")
#
# Behaviour under test (from POD):
#   - Returns 1 for valid ISO 8601 date or datetime strings
#   - Returns 0 for undef or empty string WITHOUT throwing
#   - Accepts T and space separators
#   - Accepts timezone designators (Z, +HH:MM, -HH:MM)
#   - Enforces calendar sanity (month 99 is rejected)
#   - Accepts both positional and named calling conventions
#   - Return type: integer 1 or 0
#   - No side effects
# ===========================================================================

subtest 'is_valid_datetime -- YYYY-MM-DD date-only is accepted (POD EXAMPLE)' => sub {
	# POD states: is_valid_datetime('2024-11-14') returns 1.
	# Mock the underlying parser so the test is independent of that module.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	my $result = is_valid_datetime($config{date_only});

	ok($result, 'date-only YYYY-MM-DD returns true');
	is($result, 1, 'return value is exactly 1');

	diag "Result for '$config{date_only}': $result" if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- T-separator without seconds is accepted' => sub {
	# POD: YYYY-MM-DDTHH:MM returns 1.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	ok(is_valid_datetime($config{dt_t_hhmm}),
		'T-separator HH:MM format returns 1');

	diag "Tested: '$config{dt_t_hhmm}'" if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- T-separator with seconds is accepted' => sub {
	# POD: YYYY-MM-DDTHH:MM:SS returns 1.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	ok(is_valid_datetime($config{dt_t_hhmmss}),
		'T-separator HH:MM:SS format returns 1');
};

subtest 'is_valid_datetime -- space separator without seconds is accepted' => sub {
	# POD: YYYY-MM-DD HH:MM (space separator) returns 1.
	# The function normalises the space to T before delegating to the parser.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	ok(is_valid_datetime($config{dt_space_hhmm}),
		'space-separator HH:MM format returns 1');
};

subtest 'is_valid_datetime -- space separator with seconds is accepted' => sub {
	# POD: YYYY-MM-DD HH:MM:SS (space separator with seconds) returns 1.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	ok(is_valid_datetime($config{dt_space_hhmmss}),
		'space-separator HH:MM:SS format returns 1');
};

subtest 'is_valid_datetime -- UTC timezone designator Z is accepted (POD PURPOSE)' => sub {
	# POD PURPOSE: "Optional timezone designators (Z, +HH:MM, -HH:MM) are accepted."
	# POD EXAMPLE: is_valid_datetime('2024-11-14T15:30:00Z') # 1

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	ok(is_valid_datetime($config{dt_tz_z}), 'UTC Z suffix returns 1');

	diag "Tested: '$config{dt_tz_z}'" if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- positive timezone offset is accepted' => sub {
	# POD PURPOSE: "+HH:MM offset is accepted."
	# POD EXAMPLE: is_valid_datetime('2024-11-14T15:30:00+01:00') # 1

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	ok(is_valid_datetime($config{dt_tz_plus}), 'positive offset +HH:MM returns 1');
};

subtest 'is_valid_datetime -- negative timezone offset is accepted' => sub {
	# POD PURPOSE: "-HH:MM offset is accepted."

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	ok(is_valid_datetime($config{dt_tz_minus}), 'negative offset -HH:MM returns 1');
};

subtest 'is_valid_datetime -- undef returns 0 without throwing (POD RETURNS)' => sub {
	# POD RETURNS: "Returns 0 for undef or an empty string without throwing."
	# The parser mock must NOT be reached for this input.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime' => sub {
		fail 'parse_datetime should not be called for undef';
		return;
	};

	my $result = is_valid_datetime(undef);

	is($result, 0, 'undef returns 0');
	returns_ok($result, { type => 'integer' }, 'return type is integer');

	diag 'undef input handled before parser' if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- empty string returns 0 without throwing (POD RETURNS)' => sub {
	# POD RETURNS: "Returns 0 for undef or an empty string without throwing."

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime' => sub {
		fail 'parse_datetime should not be called for empty string';
		return;
	};

	my $result = is_valid_datetime('');

	is($result, 0, 'empty string returns 0');
	returns_ok($result, { type => 'integer' }, 'return type is integer');
};

subtest 'is_valid_datetime -- DD/MM/YYYY is rejected (POD EXAMPLE)' => sub {
	# POD EXAMPLE: is_valid_datetime('28/06/2025') # 0
	# The underlying parser rejects non-ISO orderings; mock throws to simulate this.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { die "not ISO 8601\n" };

	my $result = is_valid_datetime($config{date_dmy});

	is($result, 0, 'DD/MM/YYYY returns 0');
};

subtest 'is_valid_datetime -- invalid month is rejected (POD PURPOSE)' => sub {
	# POD PURPOSE: "Calendar sanity IS enforced: out-of-range values (e.g. month 99)
	# are REJECTED."
	# POD EXAMPLE: is_valid_datetime('2024-99-01') # 0

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { die "invalid month\n" };

	is(is_valid_datetime($config{date_bad_month}), 0,
		'invalid month returns 0');

	diag "Tested: '$config{date_bad_month}'" if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- invalid day is rejected (calendar sanity)' => sub {
	# POD PURPOSE: calendar sanity is enforced, so day 99 is rejected.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { die "invalid day\n" };

	is(is_valid_datetime($config{date_bad_day}), 0,
		'invalid day returns 0');
};

subtest 'is_valid_datetime -- named calling convention (POD ARGUMENTS)' => sub {
	# POD ARGUMENTS: "Both positional (...) and named (...) calling conventions
	# are accepted."
	# POD EXAMPLE: is_valid_datetime(string => '2024-11-14') # 1

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	my $positional = is_valid_datetime($config{date_only});
	my $named      = is_valid_datetime(string => $config{date_only});

	is($named, $positional,
		'named and positional conventions produce identical results');
	is($named, 1, 'named form returns 1 for a valid date');

	diag "positional=$positional  named=$named" if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- return value is an integer (POD RETURNS)' => sub {
	# POD RETURNS: "C<1> if the string is in a supported format; C<0> otherwise."
	# Neither a blessed object nor a generic truthy value.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	my $r_valid   = is_valid_datetime($config{date_only});
	my $r_invalid = is_valid_datetime(undef);

	returns_ok($r_valid,   { type => 'integer' }, 'valid input gives integer return');
	returns_ok($r_invalid, { type => 'integer' }, 'invalid input gives integer return');

	is($r_valid,   1, 'valid input returns exactly 1');
	is($r_invalid, 0, 'invalid input returns exactly 0');
};

subtest 'is_valid_datetime -- no side effects (POD SIDE EFFECTS)' => sub {
	# POD SIDE EFFECTS: "None."
	# Package globals must be unchanged before and after the call.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	# Snapshot globals that should remain untouched
	my %before_schema = %Schema::Validator::dynamic_schema;
	my %before_props  = %Schema::Validator::dynamic_properties;

	is_valid_datetime($config{date_only});

	is_deeply(\%Schema::Validator::dynamic_schema,     \%before_schema,
		'%dynamic_schema is unchanged');
	is_deeply(\%Schema::Validator::dynamic_properties, \%before_props,
		'%dynamic_properties is unchanged');

	diag 'Package globals verified unchanged' if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- return value has no memory cycles' => sub {
	# The return value is a plain scalar; verify the GC can reclaim it.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	my $r = is_valid_datetime($config{date_only});
	memory_cycle_ok(\$r, 'return value is cycle-free');
};

# ===========================================================================
# SUBTESTS: load_dynamic_vocabulary (POD section "load_dynamic_vocabulary")
#
# Behaviour under test (from POD):
#   - Returns a hashref mapping class labels to JSON-LD item hashrefs
#   - Returns {} on all failure paths, never throws
#   - Populates %dynamic_schema and %dynamic_properties as side effects
#   - Reads from a local cache when fresh; fetches otherwise
#   - Falls back to stale cache when network is unavailable
#   - Accepts optional named args: cache_file, cache_duration, vocab_url, ua_timeout
# ===========================================================================

subtest 'load_dynamic_vocabulary -- returns a hashref (POD RETURNS)' => sub {
	# POD RETURNS: "A hashref mapping class labels (e.g. 'Person') to their
	# raw JSON-LD definition hashrefs from the @graph array."
	# Minimal test: return type must be a hashref.

	my $ok_res = FakeResponse->new(1, $VALID_JSONLD);
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $ok_res },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => '/tmp/_unit_return_type_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	returns_ok($result, { type => 'hashref' }, 'return value is a hashref');

	diag "Keys in result: " . scalar(keys %$result) if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- class labels are hashref keys (POD RETURNS)' => sub {
	# POD: "A hashref mapping class labels (e.g. 'Person') to their raw
	# JSON-LD definition hashrefs."  The value for each key must be a hashref.

	my $ok_res = FakeResponse->new(1, $VALID_JSONLD);
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $ok_res },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => '/tmp/_unit_class_keys_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	# VALID_JSONLD contains "Thing"; it must appear as a key in the result
	ok(exists $result->{ $config{class_thing} },
		"'$config{class_thing}' class label is a key in the returned hashref");

	# The value under the class key must itself be a hashref (the raw item)
	ok(ref($result->{ $config{class_thing} }) eq 'HASH',
		'class value is a hashref');

	diag "Class keys: " . join(', ', keys %$result) if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- populates %dynamic_schema (POD SIDE EFFECTS)' => sub {
	# POD SIDE EFFECTS: "Populates %Schema::Validator::dynamic_schema with
	# class definitions."

	my $ok_res = FakeResponse->new(1, $VALID_JSONLD);
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $ok_res },
	);

	# Clear the global to confirm this call populates it
	%Schema::Validator::dynamic_schema = ();

	local $SIG{__WARN__} = sub {};
	load_dynamic_vocabulary(
		cache_file     => '/tmp/_unit_schema_global_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	ok(%Schema::Validator::dynamic_schema,
		'%dynamic_schema is populated after a successful call');
	ok(exists $Schema::Validator::dynamic_schema{ $config{class_thing} },
		"'$config{class_thing}' class is in %dynamic_schema");

	diag "dynamic_schema keys: " . join(', ', keys %Schema::Validator::dynamic_schema)
		if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- populates %dynamic_properties (POD SIDE EFFECTS)' => sub {
	# POD SIDE EFFECTS: "Populates %Schema::Validator::dynamic_properties with
	# property definitions."

	my $ok_res = FakeResponse->new(1, $VALID_JSONLD);
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $ok_res },
	);

	%Schema::Validator::dynamic_properties = ();

	local $SIG{__WARN__} = sub {};
	load_dynamic_vocabulary(
		cache_file     => '/tmp/_unit_props_global_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	ok(%Schema::Validator::dynamic_properties,
		'%dynamic_properties is populated after a successful call');
	ok(exists $Schema::Validator::dynamic_properties{ $config{prop_name} },
		"'$config{prop_name}' property is in %dynamic_properties");

	diag "dynamic_properties keys: " . join(', ', keys %Schema::Validator::dynamic_properties)
		if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- fresh cache is used; no HTTP request made' => sub {
	# POD: "The cache is considered fresh for cache_duration seconds (default 24 h)."
	# When the cache file is fresh, no HTTP request should occur.

	# Create a real temp file containing valid JSON-LD (exercises the real reader)
	my (undef, $path) = tempfile(UNLINK => 1);
	_write_file($path, $VALID_JSONLD);

	# Mock LWP so we can detect any attempt to fetch
	my $http_calls = 0;
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $http_calls++; FakeResponse->new(0, undef) },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	is($http_calls, 0, 'no HTTP request is made when cache is fresh');
	ok(ref($result) eq 'HASH', 'fresh-cache path returns a hashref');
	ok(exists $result->{ $config{class_thing} },
		'fresh-cache result contains the expected class');

	diag "HTTP calls: $http_calls" if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- stale cache triggers HTTP fetch' => sub {
	# POD: "The cache is considered fresh for cache_duration seconds."
	# With cache_duration => 0 any existing file is stale, so fetch must occur.

	my (undef, $path) = tempfile(UNLINK => 1);

	my $http_calls = 0;
	my $ok_res = FakeResponse->new(1, $VALID_JSONLD);

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $http_calls++; $ok_res },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $STALE_DURATION,
		vocab_url      => $FAKE_URL,
	);

	ok($http_calls > 0, 'HTTP request is made when cache is stale');
	ok(ref($result) eq 'HASH', 'stale-cache path returns a hashref');

	diag "HTTP calls: $http_calls" if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- ua_timeout is forwarded to LWP (POD ARGUMENTS)' => sub {
	# POD ARGUMENTS: "ua_timeout -- LWP::UserAgent timeout in seconds."
	# Confirm the timeout value reaches the UA constructor.

	my $captured_timeout;
	my $ok_res = FakeResponse->new(1, $VALID_JSONLD);

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub {
			my (undef, %opts) = @_;
			$captured_timeout = $opts{timeout};
			return bless {}, 'LWP::UserAgent';
		},
		'LWP::UserAgent::get' => sub { $ok_res },
	);

	local $SIG{__WARN__} = sub {};
	load_dynamic_vocabulary(
		cache_file     => '/tmp/_unit_timeout_$$.jsonld',
		cache_duration => $STALE_DURATION,
		ua_timeout     => 42,
	);

	is($captured_timeout, 42, 'ua_timeout is forwarded to LWP::UserAgent constructor');

	diag "Captured UA timeout: $captured_timeout" if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- network failure with stale cache: uses stale' => sub {
	# POD: "On network failure the function falls back to a stale cache rather
	# than returning an empty result, and emits a carp warning."

	# Create a real temp file with valid content so -e passes and file is readable
	my (undef, $path) = tempfile(UNLINK => 1);
	_write_file($path, $VALID_JSONLD);

	my $fail_res = FakeResponse->new(0, undef);
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $fail_res },
	);

	my $result;
	my @warnings;

	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	$result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $STALE_DURATION,
		vocab_url      => $FAKE_URL,
	);

	ok(ref($result) eq 'HASH', 'stale fallback: result is a hashref');

	# At least one warning must say something about network/stale
	my $has_relevant = grep { /stale|unavailable|Failed to fetch/i } @warnings;
	ok($has_relevant, 'stale fallback: carp warning about network/stale is emitted');

	ok(exists $result->{ $config{class_thing} },
		'stale fallback: content from stale file is parsed');

	diag "Warnings: " . join('; ', @warnings) if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- returns empty hashref when no content available (POD RETURNS)' => sub {
	# POD RETURNS: "Returns an empty hashref {} on all failure paths.  Never throws."
	# When network fails AND no cache exists, the function must return {}.

	my $fail_res = FakeResponse->new(0, undef);
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $fail_res },
	);

	my $result;

	# Two carps fire on this path: one for the HTTP failure, one for "no content".
	# Use warnings_exist to verify at least the "no content" warning is present.
	warnings_exist(
		sub {
			$result = load_dynamic_vocabulary(
				cache_file     => '/no/such/path/xyz_unit_$$.jsonld',
				cache_duration => $STALE_DURATION,
				vocab_url      => $FAKE_URL,
			);
		},
		[qr/no vocabulary content/i],
		'no-content path emits an appropriate carp',
	);

	returns_ok($result, { type => 'hashref' }, 'no-content: return type is hashref');
	is(scalar keys %$result, 0, 'no-content: returned hashref is empty');

	diag 'Empty {} returned when no content available' if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- never throws on failure (POD RETURNS)' => sub {
	# POD RETURNS: "Never throws."
	# Verify that even a fatal-looking situation (no network, no cache) does not die.

	my $fail_res = FakeResponse->new(0, undef);
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $fail_res },
	);

	local $SIG{__WARN__} = sub {};

	my $result = eval {
		load_dynamic_vocabulary(
			cache_file     => '/no/such/path/never_throw_$$.jsonld',
			cache_duration => $STALE_DURATION,
		);
	};

	is($@, '', 'load_dynamic_vocabulary does not throw on failure');
	ok(defined($result), 'return value is defined even on failure');

	diag 'No exception propagated from failure path' if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- malformed JSON returns empty hashref (POD RETURNS)' => sub {
	# POD: "JSON parse errors emit carp and return {}."

	my $ok_res = FakeResponse->new(1, $BAD_JSON);
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $ok_res },
	);

	my $result;

	warning_like(
		sub {
			$result = load_dynamic_vocabulary(
				cache_file     => '/tmp/_unit_bad_json_$$.jsonld',
				cache_duration => $STALE_DURATION,
			);
		},
		qr/parse|JSON/i,
		'bad JSON emits a parse-error carp',
	);

	is(scalar keys %$result, 0, 'bad JSON returns an empty hashref');

	diag 'Bad JSON handled without throw' if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- JSON without @graph returns empty hashref' => sub {
	# POD ERROR HANDLING: JSON parse errors emit carp and return {}.
	# (No @graph is a structural error caught after successful JSON decode.)

	my $ok_res = FakeResponse->new(1, $NO_GRAPH_JSON);
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $ok_res },
	);

	my $result;

	warning_like(
		sub {
			$result = load_dynamic_vocabulary(
				cache_file     => '/tmp/_unit_no_graph_$$.jsonld',
				cache_duration => $STALE_DURATION,
			);
		},
		qr/\@graph/i,
		'missing @graph emits a carp',
	);

	is(scalar keys %$result, 0, 'missing @graph returns an empty hashref');
};

subtest 'load_dynamic_vocabulary -- cache_file arg overrides default path (POD ARGUMENTS)' => sub {
	# POD ARGUMENTS: "cache_file -- path to the local cache file."
	# Confirm a caller-supplied path is honoured by checking that a fresh
	# file at that path prevents any network call.

	my (undef, $custom_path) = tempfile(UNLINK => 1);
	_write_file($custom_path, $VALID_JSONLD);

	my $http_calls = 0;
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $http_calls++; FakeResponse->new(0, undef) },
	);

	local $SIG{__WARN__} = sub {};
	load_dynamic_vocabulary(
		cache_file     => $custom_path,
		cache_duration => $FRESH_DURATION,
	);

	is($http_calls, 0,
		'custom cache_file is honoured: no HTTP call when that file is fresh');

	diag "Custom cache path: $custom_path" if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- cache_duration arg controls freshness (POD ARGUMENTS)' => sub {
	# POD ARGUMENTS: "cache_duration -- cache validity window in seconds."
	# With cache_duration => 0, even a brand-new file is stale and triggers fetch.

	my (undef, $path) = tempfile(UNLINK => 1);
	_write_file($path, $VALID_JSONLD);

	my $http_calls = 0;
	my $ok_res = FakeResponse->new(1, $VALID_JSONLD);

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $http_calls++; $ok_res },
	);

	local $SIG{__WARN__} = sub {};
	load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $STALE_DURATION,
	);

	ok($http_calls > 0, 'cache_duration => 0 forces a fetch even for a new file');

	diag "HTTP calls with stale duration: $http_calls" if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- result is cycle-free' => sub {
	# POD: The returned hashref must be garbage-collectable.

	my $ok_res = FakeResponse->new(1, $VALID_JSONLD);
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $ok_res },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => '/tmp/_unit_cycles_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	memory_cycle_ok($result, 'load_dynamic_vocabulary result has no memory cycles');
};

subtest 'load_dynamic_vocabulary -- empty hashref failure returns are cycle-free' => sub {
	# Even failure-path returns must be cycle-free.

	my $fail_res = FakeResponse->new(0, undef);
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $fail_res },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => '/no/such/path/cycles_fail_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	memory_cycle_ok($result, 'failure-path {} return is cycle-free');
};

# ---------------------------------------------------------------------------
# Final cleanup: restore every mock that might have leaked out of a subtest.
# ---------------------------------------------------------------------------
restore_all();

done_testing();
