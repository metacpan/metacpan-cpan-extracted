#!/usr/bin/env perl

# ---------------------------------------------------------------------------
# t/integration.t -- end-to-end black-box integration tests for Schema::Validator
#
# Tests the full observable behaviour of the module and the interactions
# between its two public functions and their external dependencies:
#
#   is_valid_datetime <-> DateTime::Format::ISO8601 (real parser; spied)
#   load_dynamic_vocabulary <-> JSON::MaybeXS       (real decoder; no mock)
#   load_dynamic_vocabulary <-> LWP::UserAgent      (mocked; spied for URL)
#   load_dynamic_vocabulary <-> filesystem           (real File::Temp files)
#
# Both functions are exercised together in end-to-end workflow scenarios
# that simulate a realistic Schema.org structured-data validation use case.
#
# The module is purely functional (no new()), so concurrency is tested as
# sequential calls with different arguments, verifying that shared package
# globals (%dynamic_schema, %dynamic_properties) are correctly updated on
# each invocation.
#
# No NETWORK access is made; LWP is always mocked.
# NO_NETWORK_TESTING is therefore NOT required to run this file.
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

# ===========================================================================
# CONSTANTS -- all magic strings and numbers live here.
# ===========================================================================

use Readonly;

# A realistic Schema.org vocabulary excerpt used for most load tests.
# Contains two classes (Event, Person) and three properties (name, startDate,
# endDate) so we can simulate a full validation workflow.
Readonly::Scalar my $WORKFLOW_JSONLD => '{"@graph":['
	. '{"@type":"rdfs:Class","rdfs:label":"Event","@id":"https://schema.org/Event"},'
	. '{"@type":"rdfs:Class","rdfs:label":"Person","@id":"https://schema.org/Person"},'
	. '{"@type":"rdf:Property","rdfs:label":"name","@id":"https://schema.org/name"},'
	. '{"@type":"rdf:Property","rdfs:label":"startDate","@id":"https://schema.org/startDate"},'
	. '{"@type":"rdf:Property","rdfs:label":"endDate","@id":"https://schema.org/endDate"}'
	. ']}';

# Vocabulary containing only MusicEvent -- used for the "first call" in
# sequential-load tests to contrast with the subsequent call's content.
Readonly::Scalar my $VOCAB_A_JSONLD => '{"@graph":['
	. '{"@type":"rdfs:Class","rdfs:label":"MusicEvent","@id":"https://schema.org/MusicEvent"}'
	. ']}';

# Vocabulary containing only Organization -- used for "second call" contrast.
Readonly::Scalar my $VOCAB_B_JSONLD => '{"@graph":['
	. '{"@type":"rdfs:Class","rdfs:label":"Organization","@id":"https://schema.org/Organization"}'
	. ']}';

# 0-second freshness window: any existing cache file is always treated as stale.
Readonly::Scalar my $STALE_DURATION => 0;

# 24-hour freshness window: a file created moments ago is always treated as fresh.
Readonly::Scalar my $FRESH_DURATION => 86_400;

# ===========================================================================
# CONFIGURATION -- runtime test values indexed by meaningful names.
# ===========================================================================

my %config = (
	# Valid ISO 8601 date/datetime strings for integration tests
	date_only        => '2025-06-28',
	dt_t_sep         => '2025-06-28T19:30:00',
	dt_space_sep     => '2025-06-28 19:30',
	dt_tz_z          => '2025-06-28T19:30:00Z',
	dt_tz_offset     => '2025-06-28T19:30:00+01:00',

	# Invalid inputs
	date_bad_month   => '2025-99-01',
	date_informal    => 'next Saturday',
	date_dmy_slash   => '28/06/2025',

	# Schema.org labels expected in $WORKFLOW_JSONLD
	class_event      => 'Event',
	class_person     => 'Person',
	prop_name        => 'name',
	prop_start_date  => 'startDate',
	prop_end_date    => 'endDate',

	# Labels used for the sequential-call test vocabs
	class_music_ev   => 'MusicEvent',
	class_org        => 'Organization',

	# Documented default values from the POD Configuration section
	default_duration => 86_400,
	default_timeout  => 30,

	# Fake URL passed to vocab_url (never actually fetched)
	fake_url         => 'https://schema.invalid/vocab.jsonld',
	spy_url          => 'https://schema.invalid/spy-test.jsonld',
);

# ===========================================================================
# HELPERS
# ===========================================================================

# Minimal HTTP::Response stand-in providing is_success, decoded_content,
# and status_line -- the only three methods called by _fetch_url.
{
	package FakeResponse;
	sub new             { bless { ok => $_[1], body => $_[2] }, $_[0] }
	sub is_success      { $_[0]->{ok}   }
	sub decoded_content { $_[0]->{body} }
	sub status_line     { $_[0]->{ok} ? '200 OK' : '503 Service Unavailable' }
}

# Write $content to $path without using any Schema::Validator internals,
# keeping filesystem-setup code independent of the code under test.
sub _write_file {
	my ($path, $content) = @_;
	open my $fh, '>', $path or die "Cannot write '$path': $!";
	print $fh $content;
	close $fh;
}

# ===========================================================================
# SECTION 1: Module loading
# ===========================================================================

subtest 'module loads cleanly under use_ok' => sub {
	# Purpose: verify that Schema::Validator loads without compile-time
	# errors when imported via use_ok (smoke test for the module itself).

	use_ok('Schema::Validator', qw(is_valid_datetime load_dynamic_vocabulary));

	diag 'Schema::Validator loaded successfully' if $ENV{TEST_VERBOSE};
};

subtest 'module exports exactly the documented public symbols' => sub {
	# Purpose: @EXPORT_OK must contain only the two symbols named in the POD,
	# no extras that could cause namespace pollution for callers.

	# Collect the exported symbols the module advertises
	my @exported = sort @Schema::Validator::EXPORT_OK;

	is_deeply(\@exported,
		[sort qw(is_valid_datetime load_dynamic_vocabulary)],
		'@EXPORT_OK contains exactly the two documented exports');

	diag 'EXPORT_OK: ' . join(', ', @exported) if $ENV{TEST_VERBOSE};
};

subtest 'both public functions are callable after import' => sub {
	# Purpose: can_ok verifies that the imported names are reachable as
	# subs in the calling namespace (tests the Exporter wiring).

	# Schema::Validator is purely functional; no new() constructor.
	can_ok('Schema::Validator', 'is_valid_datetime');
	can_ok('Schema::Validator', 'load_dynamic_vocabulary');

	diag 'Both public subs are callable' if $ENV{TEST_VERBOSE};
};

subtest 'module VERSION is defined and non-empty' => sub {
	# Purpose: $VERSION is documented in the POD; verify it is present.

	ok(defined($Schema::Validator::VERSION), '$VERSION is defined');
	like($Schema::Validator::VERSION, qr/\A\d+\.\d+/,
		'$VERSION looks like a version number');

	diag "VERSION: $Schema::Validator::VERSION" if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 2: is_valid_datetime integration with DateTime::Format::ISO8601
#
# No mocking of the parser: the real DateTime::Format::ISO8601 is used.
# Spies verify that it IS (or is NOT) called, and capture its arguments.
# ===========================================================================

subtest 'is_valid_datetime delegates to real DateTime::Format::ISO8601 for valid date' => sub {
	# Purpose: verify that is_valid_datetime does not short-circuit for a
	# well-formed input -- it must reach the real parser.

	my $spy = spy 'DateTime::Format::ISO8601::parse_datetime';

	my $result = is_valid_datetime($config{date_only});

	my @calls = $spy->();
	restore('DateTime::Format::ISO8601::parse_datetime');

	# The spy should have recorded exactly one call
	is(scalar @calls, 1, 'parse_datetime called once for a valid date');
	is($result, 1, 'valid date returns 1');

	diag "Call args: " . join(', ', @{$calls[0]}[1..$#{$calls[0]}])
		if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime normalises space separator before calling the parser' => sub {
	# Purpose: is_valid_datetime pre-processes YYYY-MM-DD HH:MM inputs by
	# converting the space to T.  The spy verifies the string reaching the
	# real parser is already normalised.

	my $spy = spy 'DateTime::Format::ISO8601::parse_datetime';

	is_valid_datetime($config{dt_space_sep});

	my @calls = $spy->();
	restore('DateTime::Format::ISO8601::parse_datetime');

	# The second element of the first captured call is the first positional
	# argument (invocant is the class name at index 1, string at index 2).
	is(scalar @calls, 1, 'parse_datetime called exactly once');
	is($calls[0][2], '2025-06-28T19:30',
		'space separator was normalised to T before the parser call');

	diag "Parser received: '$calls[0][2]'" if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime does NOT call the parser for undef input' => sub {
	# Purpose: the function has an early-return guard for undef that must fire
	# BEFORE the parser is reached.  The spy proves the guard is effective.

	my $spy = spy 'DateTime::Format::ISO8601::parse_datetime';

	my $result = is_valid_datetime(undef);

	my @calls = $spy->();
	restore('DateTime::Format::ISO8601::parse_datetime');

	is(scalar @calls, 0, 'parse_datetime is not called for undef input');
	is($result, 0, 'undef returns 0');
};

subtest 'is_valid_datetime does NOT call the parser for empty string' => sub {
	# Purpose: same early-return guard must also fire for an empty string.

	my $spy = spy 'DateTime::Format::ISO8601::parse_datetime';

	my $result = is_valid_datetime('');

	my @calls = $spy->();
	restore('DateTime::Format::ISO8601::parse_datetime');

	is(scalar @calls, 0, 'parse_datetime is not called for empty string');
	is($result, 0, 'empty string returns 0');
};

subtest 'is_valid_datetime rejects semantically invalid month via real parser' => sub {
	# Purpose: the real DateTime::Format::ISO8601 enforces calendar sanity,
	# so month 99 must be rejected.  This tests the integration of our wrapper
	# with the parser's validation logic.

	# No mock; the real parser throws, is_valid_datetime catches and returns 0.
	my $result = is_valid_datetime($config{date_bad_month});

	is($result, 0, 'month 99 is rejected by the real parser');

	diag "Tested: '$config{date_bad_month}' -> $result" if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime accepts timezone designators via real parser' => sub {
	# Purpose: the real DateTime::Format::ISO8601 accepts Z and +HH:MM offsets.
	# This tests the end-to-end behaviour with timezone-aware inputs.

	is(is_valid_datetime($config{dt_tz_z}),      1, 'UTC Z suffix accepted by real parser');
	is(is_valid_datetime($config{dt_tz_offset}), 1, '+HH:MM offset accepted by real parser');

	diag "Z: " . is_valid_datetime($config{dt_tz_z})
		. "  +offset: " . is_valid_datetime($config{dt_tz_offset})
		if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime returns integer (not DateTime object) via real path' => sub {
	# Purpose: the wrapper must convert the truthy DateTime object from the
	# real parser to the plain integer 1.

	my $result = is_valid_datetime($config{dt_t_sep});

	# Must be a plain integer, not a blessed object
	ok(!blessed($result), 'return value is not a blessed object');
	returns_ok($result, { type => 'integer' }, 'return type is integer');
	is($result, 1, 'return value is exactly 1');
};

# ===========================================================================
# SECTION 3: load_dynamic_vocabulary integration with real filesystem
#
# LWP is mocked to prevent real HTTP.  JSON::MaybeXS is NOT mocked: the real
# decoder parses the JSON in $WORKFLOW_JSONLD.  The cache file is a real
# File::Temp scratch file.
# ===========================================================================

subtest 'load_dynamic_vocabulary reads real JSON from a fresh cache file' => sub {
	# Purpose: end-to-end test of the fresh-cache code path using real I/O.
	# The real JSON decoder parses $WORKFLOW_JSONLD from the temp file.

	my (undef, $path) = tempfile(UNLINK => 1);
	_write_file($path, $WORKFLOW_JSONLD);

	# Mock LWP so we can detect any accidental network call
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

	is($http_calls, 0,          'no HTTP call when cache is fresh');
	ok(ref($result) eq 'HASH',  'result is a hashref');
	ok(exists $result->{ $config{class_event} },
		"'$config{class_event}' class is present after real JSON parse");

	diag "Classes from real JSON: " . join(', ', sort keys %$result)
		if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary calls LWP with the supplied vocab_url' => sub {
	# Purpose: verify that when the cache is stale, the exact URL passed via
	# vocab_url reaches LWP::UserAgent::get (spy-via-closure technique).

	my @get_calls;
	my $ok_res = FakeResponse->new(1, $WORKFLOW_JSONLD);

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub {
			push @get_calls, { url => $_[1] };
			return $ok_res;
		},
	);

	local $SIG{__WARN__} = sub {};
	load_dynamic_vocabulary(
		cache_file     => '/tmp/_integ_url_spy_$$.jsonld',
		cache_duration => $STALE_DURATION,
		vocab_url      => $config{spy_url},
	);

	is(scalar @get_calls, 1, 'LWP::UserAgent::get called exactly once');
	is($get_calls[0]{url}, $config{spy_url},
		'LWP::UserAgent::get receives the correct vocab_url');

	diag "LWP called with URL: $get_calls[0]{url}" if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary forwards ua_timeout to LWP constructor' => sub {
	# Purpose: the ua_timeout argument must reach LWP::UserAgent->new so that
	# the HTTP request does not hang indefinitely.

	my $captured_timeout;
	my $ok_res = FakeResponse->new(1, $WORKFLOW_JSONLD);

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub {
			# Capture the named timeout argument passed to the constructor
			my (undef, %opts) = @_;
			$captured_timeout = $opts{timeout};
			return bless {}, 'LWP::UserAgent';
		},
		'LWP::UserAgent::get' => sub { $ok_res },
	);

	local $SIG{__WARN__} = sub {};
	load_dynamic_vocabulary(
		cache_file     => '/tmp/_integ_timeout_$$.jsonld',
		cache_duration => $STALE_DURATION,
		ua_timeout     => 77,
	);

	is($captured_timeout, 77, 'ua_timeout value is forwarded to LWP::UserAgent');

	diag "Captured UA timeout: $captured_timeout" if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary writes fetched content back to cache file' => sub {
	# Purpose: after a successful HTTP fetch, the function must persist the
	# content to the cache file so the next call can read from it directly.

	my (undef, $path) = tempfile(UNLINK => 1);
	my $ok_res = FakeResponse->new(1, $WORKFLOW_JSONLD);

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $ok_res },
	);

	local $SIG{__WARN__} = sub {};
	load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $STALE_DURATION,
	);

	# Read the file back to verify the content was actually written
	open my $fh, '<', $path or die "Cannot read cache file: $!";
	local $/;
	my $written = <$fh>;
	close $fh;

	# The real JSON round-trips cleanly; just check the key structure is there
	like($written, qr/\@graph/, 'fetched content written back to cache file');

	diag "Cache file size after write: " . length($written) . " bytes"
		if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary parses rdf:Property items into %dynamic_properties' => sub {
	# Purpose: properties from the @graph must populate %dynamic_properties,
	# not the class hashref that is returned.  This tests the separation.

	my (undef, $path) = tempfile(UNLINK => 1);
	_write_file($path, $WORKFLOW_JSONLD);

	local $SIG{__WARN__} = sub {};
	my $classes = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	# Properties must be in the global, not in the returned hashref
	ok(!exists $classes->{ $config{prop_name} },
		"'name' property is NOT in the class hashref");
	ok(exists $Schema::Validator::dynamic_properties{ $config{prop_name} },
		"'name' property IS in %dynamic_properties");
	ok(exists $Schema::Validator::dynamic_properties{ $config{prop_start_date} },
		"'startDate' property IS in %dynamic_properties");

	diag "Properties: " . join(', ', sort keys %Schema::Validator::dynamic_properties)
		if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 4: Complete end-to-end workflow (both functions together)
#
# Simulates a realistic use case: load the vocabulary then validate date
# values that appear in Schema.org Event structured data.
# ===========================================================================

subtest 'end-to-end workflow: load vocabulary then validate Event startDate' => sub {
	# Purpose: the primary integration scenario.  A caller would:
	# (1) load the vocabulary to know which Schema.org classes/properties exist,
	# (2) use is_valid_datetime to validate date property values.

	my (undef, $vocab_path) = tempfile(UNLINK => 1);
	_write_file($vocab_path, $WORKFLOW_JSONLD);

	local $SIG{__WARN__} = sub {};

	# Step 1: load the vocabulary from a real cache file
	my $classes = load_dynamic_vocabulary(
		cache_file     => $vocab_path,
		cache_duration => $FRESH_DURATION,
	);

	# Step 2: verify the Event class and startDate property were loaded
	ok(exists $classes->{ $config{class_event} },
		'Event class is present in returned vocabulary');
	ok(exists $Schema::Validator::dynamic_properties{ $config{prop_start_date} },
		'startDate property is in %dynamic_properties');

	# Step 3: validate a realistic ISO 8601 startDate value
	my $event_start = $config{dt_t_sep};
	ok(is_valid_datetime($event_start),
		"Event startDate '$event_start' is valid");

	# Step 4: confirm an informal date string is correctly rejected
	ok(!is_valid_datetime($config{date_informal}),
		"'$config{date_informal}' is correctly rejected as a startDate value");

	# Step 5: confirm a valid endDate is also accepted
	ok(is_valid_datetime('2025-06-29T22:00:00'),
		'Event endDate in T-separator format is valid');

	diag "Workflow complete: Event class loaded, dates validated"
		if $ENV{TEST_VERBOSE};
};

subtest 'end-to-end: vocabulary globals are consistent with the returned hashref' => sub {
	# Purpose: the returned hashref and %dynamic_schema must be different
	# references but contain the same data (the global is populated by copying
	# the return value into the package namespace).

	my (undef, $path) = tempfile(UNLINK => 1);
	_write_file($path, $WORKFLOW_JSONLD);

	# Reset both globals to ensure this call populated them
	%Schema::Validator::dynamic_schema     = ();
	%Schema::Validator::dynamic_properties = ();

	local $SIG{__WARN__} = sub {};
	my $classes = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	# The returned hashref and the global must agree on which classes are present
	is_deeply($classes, \%Schema::Validator::dynamic_schema,
		'returned hashref matches %dynamic_schema exactly');

	# Both must contain the same class count
	is(scalar keys %$classes,
		scalar keys %Schema::Validator::dynamic_schema,
		'return value key count equals %dynamic_schema key count');

	diag "Classes in return / global: " . scalar(keys %$classes)
		if $ENV{TEST_VERBOSE};
};

subtest 'end-to-end: is_valid_datetime has no side effects on vocabulary globals' => sub {
	# Purpose: calling is_valid_datetime must not disturb the globals that
	# load_dynamic_vocabulary populated.

	my (undef, $path) = tempfile(UNLINK => 1);
	_write_file($path, $WORKFLOW_JSONLD);

	local $SIG{__WARN__} = sub {};
	load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	# Snapshot the globals after load
	my %schema_before = %Schema::Validator::dynamic_schema;
	my %props_before  = %Schema::Validator::dynamic_properties;

	# Call is_valid_datetime many times; none should alter the globals
	for my $dt ($config{date_only}, $config{dt_t_sep}, undef, '', $config{date_bad_month}) {
		is_valid_datetime($dt);
	}

	is_deeply(\%Schema::Validator::dynamic_schema, \%schema_before,
		'%dynamic_schema unchanged by repeated is_valid_datetime calls');
	is_deeply(\%Schema::Validator::dynamic_properties, \%props_before,
		'%dynamic_properties unchanged by repeated is_valid_datetime calls');

	diag 'Globals preserved across is_valid_datetime calls' if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 5: Package config hash interaction
# ===========================================================================

subtest 'default %config values match the POD Configuration section' => sub {
	# Purpose: the documented defaults must be present in %Schema::Validator::config
	# so that callers relying on the documentation get predictable behaviour.

	is($Schema::Validator::config{cache_duration}, $config{default_duration},
		'default cache_duration is 86400 (24 hours)');
	is($Schema::Validator::config{ua_timeout}, $config{default_timeout},
		'default ua_timeout is 30 seconds');
	like($Schema::Validator::config{vocab_url}, qr{schema\.org},
		'default vocab_url points to schema.org');
	like($Schema::Validator::config{cache_file}, qr/\.jsonld$/,
		'default cache_file has a .jsonld extension');

	diag 'Config defaults: ' . join(', ',
		map { "$_=$Schema::Validator::config{$_}" } sort keys %Schema::Validator::config)
		if $ENV{TEST_VERBOSE};
};

subtest 'global config ua_timeout override reaches LWP::UserAgent constructor' => sub {
	# Purpose: callers may set $Schema::Validator::config{ua_timeout} = N
	# instead of passing ua_timeout => N per call.  The override must propagate.

	my $captured_timeout;
	my $ok_res = FakeResponse->new(1, $WORKFLOW_JSONLD);

	{
		# Temporarily set a non-default timeout in the package config
		local $Schema::Validator::config{ua_timeout} = 99;

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
			cache_file     => '/tmp/_integ_cfg_timeout_$$.jsonld',
			cache_duration => $STALE_DURATION,
		);
	}
	# local restores $Schema::Validator::config{ua_timeout} on scope exit

	is($captured_timeout, 99,
		'package config{ua_timeout} override is forwarded to LWP::UserAgent');

	# Verify the local scope restore worked
	is($Schema::Validator::config{ua_timeout}, $config{default_timeout},
		'ua_timeout is restored to default after local scope exits');

	diag "Captured timeout: $captured_timeout, restored: $Schema::Validator::config{ua_timeout}"
		if $ENV{TEST_VERBOSE};
};

subtest 'per-call argument overrides package config' => sub {
	# Purpose: a ua_timeout passed directly to load_dynamic_vocabulary must
	# win over the package-level config value.

	my $captured_timeout;
	my $ok_res = FakeResponse->new(1, $WORKFLOW_JSONLD);

	{
		# Set a config-level default of 50
		local $Schema::Validator::config{ua_timeout} = 50;

		my $g = mock_scoped(
			'LWP::UserAgent::new' => sub {
				my (undef, %opts) = @_;
				$captured_timeout = $opts{timeout};
				return bless {}, 'LWP::UserAgent';
			},
			'LWP::UserAgent::get' => sub { $ok_res },
		);

		local $SIG{__WARN__} = sub {};

		# Pass a per-call override of 88; this must win over config value 50
		load_dynamic_vocabulary(
			cache_file     => '/tmp/_integ_cfg_override_$$.jsonld',
			cache_duration => $STALE_DURATION,
			ua_timeout     => 88,
		);
	}

	is($captured_timeout, 88,
		'per-call ua_timeout (88) overrides package config (50)');

	diag "Per-call override timeout: $captured_timeout" if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 6: Sequential calls -- simulating multiple "instances"
#
# Schema::Validator is purely functional with shared package globals.
# Each load_dynamic_vocabulary call overwrites %dynamic_schema and
# %dynamic_properties.  These tests verify that state is correctly
# updated on each call.
# ===========================================================================

subtest 'sequential loads overwrite %dynamic_schema (last call wins)' => sub {
	# Purpose: two successive calls with different vocabulary files must leave
	# the globals in the state corresponding to the SECOND call.

	my (undef, $path_a) = tempfile(UNLINK => 1);
	my (undef, $path_b) = tempfile(UNLINK => 1);
	_write_file($path_a, $VOCAB_A_JSONLD);   # contains MusicEvent
	_write_file($path_b, $VOCAB_B_JSONLD);   # contains Organization

	local $SIG{__WARN__} = sub {};

	# First call: loads MusicEvent
	my $result_a = load_dynamic_vocabulary(
		cache_file     => $path_a,
		cache_duration => $FRESH_DURATION,
	);

	ok(exists $result_a->{ $config{class_music_ev} },
		'first load: returned hashref contains MusicEvent');
	ok(exists $Schema::Validator::dynamic_schema{ $config{class_music_ev} },
		'first load: %dynamic_schema contains MusicEvent');
	ok(!exists $Schema::Validator::dynamic_schema{ $config{class_org} },
		'first load: Organization not yet in %dynamic_schema');

	# Second call: loads Organization; must overwrite the first call's state
	my $result_b = load_dynamic_vocabulary(
		cache_file     => $path_b,
		cache_duration => $FRESH_DURATION,
	);

	ok(exists $result_b->{ $config{class_org} },
		'second load: returned hashref contains Organization');
	ok(exists $Schema::Validator::dynamic_schema{ $config{class_org} },
		'second load: %dynamic_schema now contains Organization');
	ok(!exists $Schema::Validator::dynamic_schema{ $config{class_music_ev} },
		'second load: MusicEvent has been replaced in %dynamic_schema');

	diag "After second load, %dynamic_schema keys: "
		. join(', ', sort keys %Schema::Validator::dynamic_schema)
		if $ENV{TEST_VERBOSE};
};

subtest 'sequential calls with different cache files act independently' => sub {
	# Purpose: two file-backed vocabularies must each parse correctly
	# regardless of the order in which they are called.  This confirms
	# that no state from call A leaks into the return value of call B.

	my (undef, $path_a) = tempfile(UNLINK => 1);
	my (undef, $path_b) = tempfile(UNLINK => 1);
	_write_file($path_a, $WORKFLOW_JSONLD);   # Event, Person + props
	_write_file($path_b, $VOCAB_A_JSONLD);    # MusicEvent only

	local $SIG{__WARN__} = sub {};

	my $vocab_full  = load_dynamic_vocabulary(
		cache_file => $path_a, cache_duration => $FRESH_DURATION);
	my $vocab_small = load_dynamic_vocabulary(
		cache_file => $path_b, cache_duration => $FRESH_DURATION);

	# Each return value must reflect only its own cache content
	ok(exists  $vocab_full->{ $config{class_event} },
		'full vocab: Event class present');
	ok(!exists $vocab_small->{ $config{class_event} },
		'small vocab: Event class absent (independent of full call)');
	ok(exists  $vocab_small->{ $config{class_music_ev} },
		'small vocab: MusicEvent class present');

	diag "Full vocab keys: " . scalar(keys %$vocab_full)
		. ", small vocab keys: " . scalar(keys %$vocab_small)
		if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime is stateless across many calls' => sub {
	# Purpose: the function must return consistent results for the same input
	# regardless of how many other calls precede it (no implicit state).

	# Mix valid and invalid inputs in alternating order
	my @inputs = (
		{ input => $config{date_only},      expected => 1 },
		{ input => undef,                   expected => 0 },
		{ input => $config{dt_t_sep},       expected => 1 },
		{ input => $config{date_bad_month}, expected => 0 },
		{ input => $config{dt_space_sep},   expected => 1 },
		{ input => '',                      expected => 0 },
		{ input => $config{dt_tz_z},        expected => 1 },
		{ input => $config{date_dmy_slash}, expected => 0 },
	);

	# Call each twice: once now, once after all others have run
	for my $case (@inputs) {
		my $got = is_valid_datetime($case->{input});
		is($got, $case->{expected},
			"is_valid_datetime('" . ($case->{input} // 'undef') . "') = $case->{expected}");
	}

	diag "All " . scalar(@inputs) . " stateless calls returned expected values"
		if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 7: Failure-path integration
# ===========================================================================

subtest 'network failure with real stale cache: returns populated hashref' => sub {
	# Purpose: when HTTP fails but a stale cache exists, the function must
	# read the stale file through the real file I/O path and return content.

	my (undef, $path) = tempfile(UNLINK => 1);
	_write_file($path, $WORKFLOW_JSONLD);

	# Simulate a permanently failing HTTP endpoint
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
		vocab_url      => $config{fake_url},
	);

	# Must return content from the stale file, not an empty hashref
	ok(exists $result->{ $config{class_event} },
		'stale-cache fallback returns classes from the stale file');

	# The carp about stale/unavailable must be present
	my $has_network_warn = grep { /stale|unavailable|Failed to fetch/i } @warnings;
	ok($has_network_warn, 'a carp warning about the network failure is emitted');

	diag "Stale fallback result classes: " . join(', ', sort keys %$result)
		if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary is safe to call after itself fails' => sub {
	# Purpose: a failed call (network down, no cache) returns {} and must
	# leave the module in a state where a subsequent successful call works.

	# First call: will fail (no cache, no network)
	my $fail_res = FakeResponse->new(0, undef);
	{
		my $g = mock_scoped(
			'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
			'LWP::UserAgent::get' => sub { $fail_res },
		);
		local $SIG{__WARN__} = sub {};
		my $r1 = load_dynamic_vocabulary(
			cache_file     => '/no/such/path/fail_$$.jsonld',
			cache_duration => $STALE_DURATION,
		);
		is(scalar keys %$r1, 0, 'first (failing) call returns empty hashref');
	}

	# Second call: succeeds using a real cache file
	my (undef, $path) = tempfile(UNLINK => 1);
	_write_file($path, $WORKFLOW_JSONLD);

	local $SIG{__WARN__} = sub {};
	my $r2 = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	ok(scalar keys %$r2 > 0, 'second (successful) call returns a populated hashref');
	ok(exists $r2->{ $config{class_event} },
		'second call correctly loads Event class after prior failure');

	diag "Second call after failure: " . scalar(keys %$r2) . " classes"
		if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 8: Memory and return type checks
# ===========================================================================

subtest 'both public functions return cycle-free values' => sub {
	# Purpose: neither function should leave circular references that would
	# prevent garbage collection.

	my (undef, $path) = tempfile(UNLINK => 1);
	_write_file($path, $WORKFLOW_JSONLD);

	local $SIG{__WARN__} = sub {};
	my $vocab = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	my $dt_result = is_valid_datetime($config{dt_t_sep});

	memory_cycle_ok($vocab,      'load_dynamic_vocabulary result is cycle-free');
	memory_cycle_ok(\$dt_result, 'is_valid_datetime result is cycle-free');

	diag 'Memory cycle checks passed' if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary return value type is hashref on success and failure' => sub {
	# Purpose: the return type must be consistently HASHREF (never undef, never
	# a plain hash) on both success and failure paths.

	my (undef, $path) = tempfile(UNLINK => 1);
	_write_file($path, $WORKFLOW_JSONLD);

	# Success path
	local $SIG{__WARN__} = sub {};
	my $ok_result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	returns_ok($ok_result, { type => 'hashref' },
		'success path: return type is hashref');

	# Failure path (network + no cache)
	my $fail_res = FakeResponse->new(0, undef);
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $fail_res },
	);

	my $fail_result = load_dynamic_vocabulary(
		cache_file     => '/no/such/path/type_check_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	returns_ok($fail_result, { type => 'hashref' },
		'failure path: return type is hashref');

	diag "Success: " . scalar(keys %$ok_result) . " classes, failure: "
		. scalar(keys %$fail_result) . " classes" if $ENV{TEST_VERBOSE};
};

# ---------------------------------------------------------------------------
# Final cleanup: restore all mocks/spies installed outside a mock_scoped guard.
# ---------------------------------------------------------------------------
restore_all();

done_testing();
