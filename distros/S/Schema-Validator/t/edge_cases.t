#!/usr/bin/env perl

# ---------------------------------------------------------------------------
# t/edge_cases.t -- destructive, pathological, boundary and security tests
#                  for Schema::Validator
#
# Goal: actively try to break the module by passing extreme, malformed,
# or adversarial inputs and by designing mock upstreams that return edge-case
# values (undef, 0, "", empty arrays, non-object JSON).
#
# Bug found and fixed before this file was written:
#   load_dynamic_vocabulary did not check ref($data) eq 'HASH' before calling
#   exists $data->{'@graph'}.  When decode_json succeeded but returned an
#   arrayref (e.g. "[1,2]"), the subsequent dereference died "Not a HASH
#   reference", violating the "never throws" contract.  A ref check was added.
# ---------------------------------------------------------------------------

use strict;
use warnings;

use FindBin qw($Bin);
# Under prove -t (taint mode) $Bin is tainted; detaint via regex.
use lib (do {
	(my $d = $Bin) =~ /\A(.*)\z/s;
	("$1/../lib",
	 "$1/../../Test-Mockingbird/lib",
	 "$1/../../Test-Returns/lib");
});

use File::Temp     qw(tempfile);
use Scalar::Util   qw(blessed);
use Test::Most;
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Returns;
use Test::Warn;

use Schema::Validator qw(is_valid_datetime load_dynamic_vocabulary);

# ===========================================================================
# CONSTANTS
# ===========================================================================

use Readonly;

# Sentinel used to detect $_ mutation inside tested code.
Readonly::Scalar my $SENTINEL => 'do_not_clobber';

# Very large repeat count for denial-of-service / resource-exhaustion tests.
Readonly::Scalar my $HUGE_LEN => 100_000;

# A fresh-cache window long enough that a file created now is always fresh.
Readonly::Scalar my $FRESH_DURATION => 86_400;

# A duration of zero: every cache file is treated as stale immediately.
Readonly::Scalar my $STALE_DURATION => 0;

# Minimal valid JSON-LD used in load tests where the content itself is fine.
Readonly::Scalar my $VALID_JSONLD =>
	'{"@graph":[{"@type":"rdfs:Class","rdfs:label":"Thing",'
	. '"@id":"https://schema.org/Thing"}]}';

# ===========================================================================
# CONFIGURATION -- all magic strings and numbers go here.
# ===========================================================================

my %config = (
	# Valid date used in mock tests (the value itself is not what is being tested)
	valid_date     => '2025-06-28',
	valid_datetime => '2025-06-28T19:30:00',

	# Leap-year boundaries
	leap_valid     => '2024-02-29',
	leap_invalid   => '2023-02-29',

	# Calendar boundary inputs: these should all be rejected
	month_zero     => '2025-00-01',
	month_13       => '2025-13-01',
	day_zero       => '2025-06-00',
	day_32         => '2025-06-32',
	april_31       => '2025-04-31',

	# Pathological string inputs
	string_zero    => '0',
	whitespace     => '   ',
	trailing_nl    => "2025-06-28\n",
	embedded_null  => "2025\x00-06-28",
	int_zero       => 0,

	# Known exact error-message fragments (from Params::Validate::Strict)
	err_not_string => 'must be a string',
	err_unknown_p  => 'Unknown parameter',
	err_usage      => 'Usage',
	err_not_int    => 'cache_duration',

	# Edge-case JSON bodies for HTTP mock tests
	json_array     => '[1,2,3]',
	json_null_str  => '{"@graph":null}',
	json_graph_0   => '{"@graph":0}',
	json_empty_g   => '{"@graph":[]}',
	json_number    => '{"@graph":42}',
);

# ===========================================================================
# HELPER: minimal fake HTTP response
# ===========================================================================

{
	package FakeResp;
	sub new             { bless { ok => $_[1], body => $_[2] }, $_[0] }
	sub is_success      { $_[0]->{ok}   }
	sub decoded_content { $_[0]->{body} }
	sub status_line     { $_[0]->{ok} ? '200 OK' : '503 Unavailable' }
}

# Write content to a path without using any module-internal helper.
sub _write { open my $f, '>', $_[0] or die $!; print $f $_[1]; close $f }

# ===========================================================================
# SECTION 1: is_valid_datetime -- pathological STRING inputs
# ===========================================================================

subtest 'is_valid_datetime -- whitespace-only string returns 0' => sub {
	# Whitespace has non-zero length but is not a valid ISO 8601 date.
	# The early guard passes (length > 0), but the parser must reject it.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { die "not a date\n" };

	is(is_valid_datetime($config{whitespace}), 0,
		'whitespace-only string returns 0');

	diag "Tested: '$config{whitespace}'" if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- string "0" returns 0' => sub {
	# The string "0" has length 1 and is defined, so it passes the guard.
	# "0" is not an ISO 8601 date and must return 0.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { die "not a date\n" };

	is(is_valid_datetime($config{string_zero}), 0,
		'string "0" returns 0');
};

subtest 'is_valid_datetime -- integer 0 coerced to string returns 0' => sub {
	# Perl silently stringifies 0 to "0"; behaviour must be the same as above.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { die "not a date\n" };

	is(is_valid_datetime($config{int_zero}), 0,
		'integer 0 coerced to string returns 0');
};

subtest 'is_valid_datetime -- trailing newline returns 0' => sub {
	# A date with a trailing newline must be rejected; the parser will fail.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { die "not a date\n" };

	is(is_valid_datetime($config{trailing_nl}), 0,
		'date with trailing newline returns 0');
};

subtest 'is_valid_datetime -- embedded null byte returns 0' => sub {
	# A null byte inside the string must be handled gracefully.
	# The function must not crash, and must return 0.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { die "not a date\n" };

	my $result = is_valid_datetime($config{embedded_null});

	is($result, 0, 'string with embedded null byte returns 0');

	diag "Null-byte test returned: $result" if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- very long string returns 0 without hanging' => sub {
	# Denial-of-service guard: a 100,000-character string must be rejected
	# promptly.  The space-normalisation regex is anchored to ^ so it does
	# not backtrack over the whole string.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { die "not a date\n" };

	my $huge = 'x' x $HUGE_LEN;
	my $result = is_valid_datetime($huge);

	is($result, 0, 'very long string returns 0');

	diag "100k-char string rejected without hang" if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- string with shell metacharacters returns 0' => sub {
	# Security: strings containing shell injection sequences must not be
	# executed or cause the process to do anything unexpected.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { die "not a date\n" };

	my @injection_attempts = (
		'$(rm -rf /)',
		'`date`',
		'; cat /etc/passwd',
		'../../etc/passwd',
		"2025-06-28'; DROP TABLE vocab; --",
	);

	for my $attempt (@injection_attempts) {
		my $result = is_valid_datetime($attempt);
		is($result, 0, "injection attempt rejected: '$attempt'");
	}

	diag "All " . scalar(@injection_attempts) . " injection attempts returned 0"
		if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 2: is_valid_datetime -- REFERENCE TYPE inputs (must croak)
# ===========================================================================

subtest 'is_valid_datetime -- arrayref input throws a validation error' => sub {
	# Passing an arrayref is a programmer error.  validate_strict must croak
	# with an error that mentions "must be a string".

	throws_ok(
		sub { is_valid_datetime([1, 2, 3]) },
		qr/$config{err_not_string}/,
		'arrayref input throws "must be a string" error',
	);

	diag 'arrayref correctly rejected by validate_strict' if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- hashref input throws a validation error' => sub {
	# A hashref is parsed by Params::Get as named arguments; the first key
	# is not "string" so validate_strict sees an unknown parameter.

	throws_ok(
		sub { is_valid_datetime({ foo => 'bar' }) },
		qr/$config{err_unknown_p}/,
		'hashref with unknown key throws "Unknown parameter" error',
	);
};

subtest 'is_valid_datetime -- coderef input throws a validation error' => sub {
	# A coderef is positionally mapped to the "string" parameter.
	# validate_strict must reject it as not a string.

	throws_ok(
		sub { is_valid_datetime(sub { 'date' }) },
		qr/$config{err_not_string}/,
		'coderef input throws "must be a string" error',
	);
};

subtest 'is_valid_datetime -- scalar reference: Params::Get dereferences it' => sub {
	# Params::Get transparently dereferences scalar references.  Calling
	# is_valid_datetime(\$date) is therefore equivalent to calling it with
	# the underlying string value.  A ref to a valid date returns 1;
	# a ref to an invalid string returns 0.

	my $valid   = $config{valid_date};
	my $invalid = 'not-a-date';

	my $r_valid   = eval { is_valid_datetime(\$valid) };
	my $r_invalid = eval { is_valid_datetime(\$invalid) };

	is($@,        '',  'scalar-ref to valid date does not throw');
	is($r_valid,   1,  'scalar-ref to valid date: Params::Get dereferences, returns 1');
	is($r_invalid, 0,  'scalar-ref to invalid string: dereferences and rejects');

	diag "Scalar-ref deref: valid=$r_valid, invalid=$r_invalid"
		if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- typeglob input throws a usage error from Params::Get' => sub {
	# A GLOB reference confuses Params::Get's argument-normalisation logic,
	# which raises a "Usage: ..." error rather than the validate_strict type
	# error raised for arrayref/coderef.  The important invariant is that
	# a typeglob still causes an exception (no silent success).

	throws_ok(
		sub { is_valid_datetime(\*STDOUT) },
		qr/$config{err_usage}/i,
		'typeglob-ref input throws a usage/argument error',
	);
};

subtest 'is_valid_datetime -- blessed-object input throws a validation error' => sub {
	# A blessed reference is still a reference, not a plain string.

	my $obj = bless {}, 'SomeClass';

	throws_ok(
		sub { is_valid_datetime($obj) },
		qr/$config{err_not_string}/,
		'blessed-object input throws "must be a string" error',
	);
};

subtest 'is_valid_datetime -- no-argument call throws a usage error' => sub {
	# Calling the function with no arguments is a programmer error.
	# Params::Get must surface a helpful "Usage: ..." message.

	throws_ok(
		sub { is_valid_datetime() },
		qr/$config{err_usage}/i,
		'zero-argument call throws a usage error',
	);
};

# ===========================================================================
# SECTION 3: is_valid_datetime -- calendar BOUNDARY conditions (real parser)
# ===========================================================================

subtest 'is_valid_datetime -- leap-year Feb 29 is valid' => sub {
	# 2024 is a leap year; February 29 must be accepted by the real parser.
	# No mock: we need the real DateTime::Format::ISO8601 to verify this.

	is(is_valid_datetime($config{leap_valid}), 1,
		'2024-02-29 (leap year) is valid');
};

subtest 'is_valid_datetime -- non-leap-year Feb 29 is rejected' => sub {
	# 2023 is NOT a leap year; February 29 must be rejected.

	is(is_valid_datetime($config{leap_invalid}), 0,
		'2023-02-29 (non-leap year) is rejected');
};

subtest 'is_valid_datetime -- month 0 is rejected' => sub {
	# Month 0 does not exist in the Gregorian calendar.

	is(is_valid_datetime($config{month_zero}), 0, 'month 0 is rejected');
};

subtest 'is_valid_datetime -- month 13 is rejected' => sub {
	# Month 13 does not exist in the Gregorian calendar.

	is(is_valid_datetime($config{month_13}), 0, 'month 13 is rejected');
};

subtest 'is_valid_datetime -- day 0 is rejected' => sub {
	# Day 0 does not exist.

	is(is_valid_datetime($config{day_zero}), 0, 'day 0 is rejected');
};

subtest 'is_valid_datetime -- day 32 is rejected' => sub {
	# No month has 32 days.

	is(is_valid_datetime($config{day_32}), 0, 'day 32 is rejected');
};

subtest 'is_valid_datetime -- April 31 is rejected (April has 30 days)' => sub {
	# April has only 30 days; day 31 is invalid.

	is(is_valid_datetime($config{april_31}), 0, 'April 31 is rejected');
};

# ===========================================================================
# SECTION 4: is_valid_datetime -- edge-case MOCK RETURNS from the parser
#
# These test how the wrapper handles upstream failures: falsy returns,
# zero returns, empty-string dies, and other anomalies.
# ===========================================================================

subtest 'is_valid_datetime -- parser returns undef: function returns 0' => sub {
	# The eval wrapper uses truthiness; undef (falsy) must yield 0.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { return undef };

	is(is_valid_datetime($config{valid_date}), 0,
		'parser returning undef causes function to return 0');
};

subtest 'is_valid_datetime -- parser returns 0 (falsy integer): function returns 0' => sub {
	# Perl integer 0 is falsy; the ternary must produce 0.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { return 0 };

	is(is_valid_datetime($config{valid_date}), 0,
		'parser returning 0 causes function to return 0');
};

subtest 'is_valid_datetime -- parser returns empty string (falsy): function returns 0' => sub {
	# An empty string is falsy; the ternary must produce 0.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { return '' };

	is(is_valid_datetime($config{valid_date}), 0,
		'parser returning "" causes function to return 0');
};

subtest 'is_valid_datetime -- parser dies with empty string: function returns 0' => sub {
	# die "" is caught by the eval; the function must not rethrow, just return 0.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { die '' };

	my $result = eval { is_valid_datetime($config{valid_date}) };

	is($@,      '',  'function does not rethrow when parser dies with ""');
	is($result, 0,   'function returns 0 when parser dies with ""');
};

subtest 'is_valid_datetime -- parser dies with "0": function returns 0' => sub {
	# die "0" is a falsy die message.  The eval catches it and the function
	# returns 0 without propagating the exception.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { die '0' };

	my $result = eval { is_valid_datetime($config{valid_date}) };

	is($@,      '',  'function does not rethrow when parser dies with "0"');
	is($result, 0,   'function returns 0 when parser dies with "0"');
};

subtest 'is_valid_datetime -- parser dies with very long error: function returns 0' => sub {
	# A very long die message must not cause any special behaviour.

	my $long_err = 'X' x $HUGE_LEN;
	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { die $long_err };

	my $result = eval { is_valid_datetime($config{valid_date}) };

	is($@,      '',  'function does not rethrow a very long parser error');
	is($result, 0,   'function returns 0 when parser dies with a long error');
};

subtest 'is_valid_datetime -- $_ is not mutated by the function' => sub {
	# The space-normalisation regex copies $string into a new variable;
	# $_ must be untouched.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	local $_ = $SENTINEL;
	is_valid_datetime($config{valid_date});
	is($_, $SENTINEL, 'is_valid_datetime does not mutate $_');
};

subtest 'is_valid_datetime -- list vs scalar context: consistent result' => sub {
	# The function returns a plain integer; list and scalar contexts must agree.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	my $scalar  = is_valid_datetime($config{valid_date});
	my @list    = is_valid_datetime($config{valid_date});

	is($scalar,   1, 'scalar context returns 1');
	is($list[0],  1, 'list context first element is 1');
	is(scalar @list, 1, 'list context returns exactly one element');
};

# ===========================================================================
# SECTION 5: load_dynamic_vocabulary -- edge-case HTTP BODY responses
#
# Mock decoded_content to return pathological values and verify the module
# returns {} without throwing (the "never throws" contract).
# ===========================================================================

subtest 'load_dynamic_vocabulary -- decoded_content returns undef: returns {}' => sub {
	# A nil response body must be treated as missing content.

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { FakeResp->new(1, undef) },
	);

	local $SIG{__WARN__} = sub {};
	my $result = eval {
		load_dynamic_vocabulary(
			cache_file     => '/tmp/_ec_undef_body_$$.jsonld',
			cache_duration => $STALE_DURATION,
		)
	};

	is($@, '', 'no exception when decoded_content is undef');
	is(scalar keys %$result, 0, 'returns empty hashref when body is undef');

	diag 'undef body handled cleanly' if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- decoded_content returns "": returns {}' => sub {
	# An empty body string fails JSON parsing; must return {} without throwing.

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { FakeResp->new(1, '') },
	);

	local $SIG{__WARN__} = sub {};
	my $result = eval {
		load_dynamic_vocabulary(
			cache_file     => '/tmp/_ec_empty_body_$$.jsonld',
			cache_duration => $STALE_DURATION,
		)
	};

	is($@, '', 'no exception when decoded_content is empty string');
	is(scalar keys %$result, 0, 'returns empty hashref for empty body');
};

subtest 'load_dynamic_vocabulary -- JSON array body does not crash (was a bug)' => sub {
	# When decoded_content is valid JSON but an array "[1,2,3]", decode_json
	# returns an arrayref.  The old code called exists on an arrayref, dying
	# "Not a HASH reference".  The fix adds a ref($data) eq "HASH" guard.

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { FakeResp->new(1, $config{json_array}) },
	);

	local $SIG{__WARN__} = sub {};
	my $result = eval {
		load_dynamic_vocabulary(
			cache_file     => '/tmp/_ec_array_body_$$.jsonld',
			cache_duration => $STALE_DURATION,
		)
	};

	is($@, '', 'JSON array body does not throw (regression: was a crash)');
	is(scalar keys %$result, 0, 'JSON array body returns empty hashref');

	diag "JSON array body handled: ref=${\ref($result)}" if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- @graph: null does not crash' => sub {
	# Valid JSON object where @graph is JSON null (decodes to undef).
	# ref(undef) is not "ARRAY", so the @graph check must reject it cleanly.

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { FakeResp->new(1, $config{json_null_str}) },
	);

	local $SIG{__WARN__} = sub {};
	my $result = eval {
		load_dynamic_vocabulary(
			cache_file     => '/tmp/_ec_null_graph_$$.jsonld',
			cache_duration => $STALE_DURATION,
		)
	};

	is($@, '', 'null @graph does not throw');
	is(scalar keys %$result, 0, 'null @graph returns empty hashref');
};

subtest 'load_dynamic_vocabulary -- @graph: 0 (number) does not crash' => sub {
	# @graph as an integer zero is not an array; must be rejected gracefully.

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { FakeResp->new(1, $config{json_graph_0}) },
	);

	local $SIG{__WARN__} = sub {};
	my $result = eval {
		load_dynamic_vocabulary(
			cache_file     => '/tmp/_ec_graph_zero_$$.jsonld',
			cache_duration => $STALE_DURATION,
		)
	};

	is($@, '', '@graph: 0 does not throw');
	is(scalar keys %$result, 0, '@graph: 0 returns empty hashref');
};

subtest 'load_dynamic_vocabulary -- empty @graph array returns {} cleanly' => sub {
	# An empty @graph array is technically valid JSON-LD.  The module must
	# parse it without error and return an empty hashref.

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { FakeResp->new(1, $config{json_empty_g}) },
	);

	local $SIG{__WARN__} = sub {};
	my $result = eval {
		load_dynamic_vocabulary(
			cache_file     => '/tmp/_ec_empty_graph_$$.jsonld',
			cache_duration => $STALE_DURATION,
		)
	};

	is($@, '', 'empty @graph array does not throw');
	is(scalar keys %$result, 0, 'empty @graph returns empty hashref');
	returns_ok($result, { type => 'hashref' }, 'empty @graph return type is hashref');
};

subtest 'load_dynamic_vocabulary -- is_success returns undef: treated as failure' => sub {
	# Returning undef from is_success is falsy, so the module must treat it
	# as an HTTP failure and NOT try to read the nil body.

	my $fake = FakeResp->new(undef, undef);
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $fake },
	);

	local $SIG{__WARN__} = sub {};
	my $result = eval {
		load_dynamic_vocabulary(
			cache_file     => '/tmp/_ec_undef_success_$$.jsonld',
			cache_duration => $STALE_DURATION,
		)
	};

	is($@, '', 'undef is_success does not throw');
	is(scalar keys %$result, 0, 'undef is_success causes empty hashref return');
};

# ===========================================================================
# SECTION 6: load_dynamic_vocabulary -- @graph ITEM edge cases
# ===========================================================================

subtest 'load_dynamic_vocabulary -- graph item with label "0" is skipped' => sub {
	# The string "0" is falsy in Perl.  The implementation uses
	# `my $label = _extract_label($item) or next` so "0" causes a skip.
	# The item must NOT appear in the result.

	my $json = '{"@graph":['
		. '{"@type":"rdfs:Class","rdfs:label":"0","@id":"https://schema.org/Zero"}'
		. ']}';

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { FakeResp->new(1, $json) },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => '/tmp/_ec_label_zero_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	ok(!exists $result->{'0'}, 'item with label "0" is skipped (falsy)');

	diag "Result keys: " . join(', ', keys %$result) if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- graph item with empty-string label is skipped' => sub {
	# An empty-string label is falsy; the `or next` guard must skip it.

	my $json = '{"@graph":['
		. '{"@type":"rdfs:Class","rdfs:label":"","@id":"https://schema.org/Empty"}'
		. ']}';

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { FakeResp->new(1, $json) },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => '/tmp/_ec_label_empty_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	ok(!exists $result->{''}, 'item with empty-string label is skipped');
};

subtest 'load_dynamic_vocabulary -- graph item with empty label array is skipped' => sub {
	# An empty label array has no first element; _extract_label returns undef.

	my $json = '{"@graph":['
		. '{"@type":"rdfs:Class","rdfs:label":[],"@id":"https://schema.org/EmptyArr"}'
		. ']}';

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { FakeResp->new(1, $json) },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => '/tmp/_ec_label_empty_arr_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	is(scalar keys %$result, 0, 'item with empty label array is skipped');
};

subtest 'load_dynamic_vocabulary -- graph item with no @type is skipped' => sub {
	# Items with no @type key must be silently ignored.

	my $json = '{"@graph":['
		. '{"rdfs:label":"Orphan","@id":"https://schema.org/Orphan"}'
		. ']}';

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { FakeResp->new(1, $json) },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => '/tmp/_ec_no_type_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	ok(!exists $result->{Orphan}, 'item without @type is skipped');
};

subtest 'load_dynamic_vocabulary -- graph item with very long label is stored' => sub {
	# A label of 1000 characters is unusual but must be stored without error.

	my $long_label = 'L' x 1000;
	my $json = '{"@graph":['
		. '{"@type":"rdfs:Class","rdfs:label":"' . $long_label . '",'
		. '"@id":"https://schema.org/Long"}]}';

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { FakeResp->new(1, $json) },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => '/tmp/_ec_long_label_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	ok(exists $result->{$long_label},
		'item with 1000-char label is stored correctly');

	diag "Long label key length: " . length($long_label) if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- injection characters in label are stored verbatim' => sub {
	# Labels containing HTML/script injection characters must be stored as
	# plain strings; the module must not interpret or execute them.

	my $label = '<script>alert(1)</script>';
	my $json = '{"@graph":['
		. '{"@type":"rdfs:Class","rdfs:label":"' . $label . '",'
		. '"@id":"https://schema.org/Xss"}]}';

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { FakeResp->new(1, $json) },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => '/tmp/_ec_inject_label_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	ok(exists $result->{$label},
		'injection-character label is stored as a plain string');
	ok(!blessed($result->{$label}),
		'injection-character label value is not a blessed/executable object');

	diag "Stored injection label: $label" if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- large @graph (1000 items) completes without error' => sub {
	# Performance edge case: a graph with 1000 class items must be processed
	# without exceeding memory limits or running out of stack.

	my $items = join(',', map {
		'{"@type":"rdfs:Class","rdfs:label":"Class' . $_ . '",'
		. '"@id":"https://schema.org/Class' . $_ . '"}'
	} 1 .. 1000);

	my $json = '{"@graph":[' . $items . ']}';

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { FakeResp->new(1, $json) },
	);

	local $SIG{__WARN__} = sub {};
	my $result = eval {
		load_dynamic_vocabulary(
			cache_file     => '/tmp/_ec_large_graph_$$.jsonld',
			cache_duration => $STALE_DURATION,
		)
	};

	is($@, '', 'large @graph does not throw');
	is(scalar keys %$result, 1000, 'all 1000 items are stored in the result');

	diag "1000-item graph: " . scalar(keys %$result) . " classes"
		if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 7: load_dynamic_vocabulary -- WRONG-TYPE ARGUMENTS
# ===========================================================================

subtest 'load_dynamic_vocabulary -- string for cache_duration throws' => sub {
	# cache_duration must be an integer; a non-numeric string must croak.

	throws_ok(
		sub { load_dynamic_vocabulary(cache_duration => 'not-an-int') },
		qr/$config{err_not_int}/,
		'string cache_duration throws a validation error',
	);
};

subtest 'load_dynamic_vocabulary -- arrayref for cache_file throws' => sub {
	# cache_file must be a string; an arrayref must croak.

	throws_ok(
		sub { load_dynamic_vocabulary(cache_file => []) },
		qr/$config{err_not_string}/,
		'arrayref cache_file throws a validation error',
	);
};

subtest 'load_dynamic_vocabulary -- circular reference in graph item: no crash' => sub {
	# If a graph item has a circular reference (e.g. $item->{self} = $item),
	# the module must store the item and return without crashing.  The caller
	# is responsible for circular-ref input; we only test survivability.

	my (undef, $path) = tempfile(UNLINK => 1);

	# Write minimal JSON; then after load we inject a circular ref via globals
	_write($path, $VALID_JSONLD);

	local $SIG{__WARN__} = sub {};
	my $result = eval {
		load_dynamic_vocabulary(
			cache_file     => $path,
			cache_duration => $FRESH_DURATION,
		)
	};

	is($@, '', 'load with real file does not throw');
	ok(ref($result) eq 'HASH', 'returns hashref');

	# Now artificially inject a circular ref into a stored item and confirm
	# that querying the result does not cause an infinite loop.
	if (exists $result->{Thing}) {
		$result->{Thing}{__cycle} = $result->{Thing};
		ok(exists $result->{Thing},  'circular-ref item is still accessible');
	}

	diag 'Circular-ref survivability confirmed' if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 8: State preservation edge cases
# ===========================================================================

subtest 'failed load does not clear globals populated by a prior success' => sub {
	# If call A succeeds and call B fails (bad JSON), the globals must retain
	# call A's data because the failure path never reaches the assignment.

	my (undef, $path) = tempfile(UNLINK => 1);
	_write($path, $VALID_JSONLD);

	local $SIG{__WARN__} = sub {};

	# Call A: succeeds, populates %dynamic_schema with Thing
	load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);
	ok(exists $Schema::Validator::dynamic_schema{Thing},
		'after successful load, Thing is in %dynamic_schema');

	# Call B: fails (no network, no valid cache), must not clear the globals
	my $fail = FakeResp->new(0, undef);
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $fail },
	);
	load_dynamic_vocabulary(
		cache_file     => '/no/such/path/fail_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	# Thing must still be present because the failed call returned early
	ok(exists $Schema::Validator::dynamic_schema{Thing},
		'after failed load, Thing is still in %dynamic_schema (globals not cleared)');

	diag 'State preserved after failed second call' if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- $_ not mutated by the function' => sub {
	# The for-loop inside _parse_graph uses named $item, not $_.
	# Confirm the caller s $_ is untouched.

	my (undef, $path) = tempfile(UNLINK => 1);
	_write($path, $VALID_JSONLD);

	local $SIG{__WARN__} = sub {};
	local $_ = $SENTINEL;
	load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);
	is($_, $SENTINEL, 'load_dynamic_vocabulary does not mutate $_');
};

subtest 'load_dynamic_vocabulary -- list vs scalar context: always one value' => sub {
	# The function returns one hashref.  In list context it returns a
	# one-element list; there is no second value.

	my (undef, $path) = tempfile(UNLINK => 1);
	_write($path, $VALID_JSONLD);

	local $SIG{__WARN__} = sub {};

	my @list = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	is(scalar @list, 1, 'list context: exactly one return value');
	ok(ref($list[0]) eq 'HASH', 'list context: the single value is a hashref');

	diag "List context returned " . scalar(@list) . " value(s)" if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# Final cleanup: restore all mocks/spies installed outside a guard.
# ===========================================================================
restore_all();

done_testing();
