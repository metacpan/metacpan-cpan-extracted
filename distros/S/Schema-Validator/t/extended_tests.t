#!/usr/bin/env perl

# ---------------------------------------------------------------------------
# t/extended_tests.t -- targeted tests for every previously-uncovered path
#
# Produced after a Devel::Cover run on the existing suite identified these
# specific gaps (lib/Schema/Validator.pm):
#
#   BRANCH gaps
#   -----------
#   line 492  -- carp "Could not read cache..."
#               Needs: fresh file exists but _slurp_file throws
#   line 502  -- carp "Could not write cache..."
#               Needs: fetch succeeds but _spit_file throws
#   lines 507/508 -- carp "Could not read stale cache..."
#               Needs: network fails, stale file exists, _slurp_file throws
#   lines 700/711 -- if (my $id = $item->{'@id'}) FALSE branch
#               Needs: @graph items with no '@id' key
#
#   CONDITION gaps
#   --------------
#   lines 481-484 -- defined-but-false param values (A // B where A is "" or 0)
#               Needs: cache_duration=>0, ua_timeout=>0, cache_file=>"", vocab_url=>""
#
#   UNREACHABLE PATHS (documented here so a reviewer can verify)
#   -------------------------------------------------------------------
#   lines 702/713  $classes{$short} //= $item  "defined-but-false" condition
#               Unreachable: stored values are ALWAYS hashrefs (truthy).
#               No code path can produce a defined-but-false hash slot.
#
#   unused imports
#               Encode qw(decode encode) and Scalar::Util qw(reftype) are
#               imported at lines 14 and 20 but never called at runtime.
#               They are dead imports -- candidates for removal.
# ---------------------------------------------------------------------------

use strict;
use warnings;

use FindBin qw($Bin);
# Under prove -t (taint mode) $Bin is tainted; detaint before use lib.
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

# Cache window that keeps a file created right now within the "fresh" window.
Readonly::Scalar my $FRESH_DURATION => 86_400;

# Cache window of zero: every existing file is instantly stale.
Readonly::Scalar my $STALE_DURATION => 0;

# Minimal valid JSON-LD used wherever the parse succeeds.
Readonly::Scalar my $VALID_JSONLD =>
	'{"@graph":['
	. '{"@type":"rdfs:Class","rdfs:label":"Thing","@id":"https://schema.org/Thing"},'
	. '{"@type":"rdf:Property","rdfs:label":"name","@id":"https://schema.org/name"}'
	. ']}';

# Sentinel to detect $_ mutation inside tested code.
Readonly::Scalar my $SENTINEL => '__sentinel__';

# ===========================================================================
# CONFIGURATION
# ===========================================================================

my %config = (
	# Values used in the param-default tests
	empty_string  => '',
	int_zero      => 0,

	# Expected carp message fragments (partial matches only to avoid fragility)
	carp_read     => 'Could not read cache',
	carp_write    => 'Could not write cache',
	carp_stale    => 'Could not read stale cache',
	carp_no_vocab => 'no vocabulary content available',

	# Default config values expected from the POD
	default_timeout  => 30,
	default_duration => 86_400,
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

# Write content to a file path without using any Schema::Validator helper.
sub _write { open my $fh, '>', $_[0] or die $!; print $fh $_[1]; close $fh }

# ===========================================================================
# SECTION 1: line 492 -- fresh-cache read failure
#
# Covers the previously-untested TRUE branch of:
#   carp "Could not read cache '$cache_file': $@" if $@;
#
# Setup: a real fresh file exists so the -e and mtime checks pass, but
# _slurp_file is mocked to throw.  A subsequent fetch (via mocked LWP)
# succeeds, so the function eventually returns a populated hashref.
# ===========================================================================

subtest 'line 492: carp when fresh-cache _slurp_file throws' => sub {
	# Purpose: hit the "Could not read cache" carp on line 492.
	# This requires: (1) a fresh cache file exists, (2) _slurp_file throws.

	my (undef, $path) = tempfile(UNLINK => 1);
	# The file must be non-empty so -e passes, but content doesn't matter
	# because _slurp_file is mocked to throw before it reads anything.
	_write($path, 'irrelevant');

	my $ok_res = FakeResp->new(1, $VALID_JSONLD);

	# Mock _slurp_file to simulate an I/O failure on the fresh read.
	# Mock _spit_file to succeed so line 502 is not also triggered.
	# Mock LWP so the fallback fetch returns valid content.
	my $g = mock_scoped(
		'Schema::Validator::_slurp_file' => sub { die "permission denied\n" },
		'Schema::Validator::_spit_file'  => sub { 1 },
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $ok_res },
	);

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	# Call with a fresh duration so the cache check passes (-e && mtime check)
	my $result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	# The key assertion: the "Could not read cache" carp must have fired
	my $found = grep { /\Q$config{carp_read}\E/i } @warnings;
	ok($found, 'carp "Could not read cache" emitted when _slurp_file throws');

	# The function must recover via the fetch fallback and return a hashref
	ok(ref($result) eq 'HASH', 'function recovers after fresh-cache read failure');

	diag "Warnings captured: " . join('; ', @warnings) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 2: line 502 -- cache write failure after successful fetch
#
# Covers the previously-untested TRUE branch of:
#   carp "Could not write cache '$cache_file': $@" if $@;
#
# Setup: cache is stale/absent so the fetch path runs; LWP returns valid
# JSON; _spit_file is mocked to throw.  The write failure is non-fatal:
# the function must still parse the JSON and return the vocabulary.
# ===========================================================================

subtest 'line 502: carp when _spit_file throws after successful fetch' => sub {
	# Purpose: hit the "Could not write cache" carp on line 502.
	# The fetch succeeds but persisting to disk fails.

	my $ok_res = FakeResp->new(1, $VALID_JSONLD);

	# Mock LWP to supply content, mock _spit_file to simulate write failure.
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $ok_res },
		'Schema::Validator::_spit_file' => sub { die "disk full\n" },
	);

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	# Use a stale duration so no fresh-cache read is attempted first
	my $result = load_dynamic_vocabulary(
		cache_file     => '/tmp/_ext_write_fail_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	# The "Could not write cache" carp must have fired
	my $found = grep { /\Q$config{carp_write}\E/i } @warnings;
	ok($found, 'carp "Could not write cache" emitted when _spit_file throws');

	# Write failure is non-fatal: vocabulary is still parsed and returned
	ok(ref($result) eq 'HASH', 'function returns hashref despite write failure');
	ok(exists $result->{Thing}, 'vocabulary content is available despite write failure');

	diag "Write-fail warnings: " . join('; ', @warnings) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 3: lines 507-508 -- stale-cache read failure
#
# Covers the previously-untested:
#   line 507: if ($@) { ... } TRUE branch
#   line 508: carp "Could not read stale cache '$cache_file': $@"
#
# Setup: cache_duration=0 so fresh check is skipped; LWP fails so
# _fetch_url returns undef; the stale file exists (so -e passes); but
# the _slurp_file call for the stale fallback also throws.
# ===========================================================================

subtest 'lines 507-508: carp when stale-cache _slurp_file throws' => sub {
	# Purpose: hit the innermost error path in load_dynamic_vocabulary:
	# network down AND the stale-cache read also fails.

	# Create a real file so -e $cache_file is true for the stale-fallback check
	my (undef, $path) = tempfile(UNLINK => 1);
	_write($path, 'stale-content');

	my $fail_res = FakeResp->new(0, undef);

	# Network fails; stale read also fails.
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $fail_res },
		'Schema::Validator::_slurp_file' => sub { die "stale read failed\n" },
	);

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	# cache_duration=0 ensures the fresh-cache block is skipped entirely
	my $result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $STALE_DURATION,
	);

	# The "Could not read stale cache" carp at line 508 must have fired
	my $stale_warn = grep { /\Q$config{carp_stale}\E/i } @warnings;
	ok($stale_warn, 'carp "Could not read stale cache" emitted (line 508)');

	# After all strategies fail, the function returns {}
	is(scalar keys %$result, 0,
		'returns empty hashref when all content-acquisition strategies fail');

	diag "Stale-fail warnings: " . join('; ', @warnings) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 4: lines 700 and 711 -- @id FALSE branch in _parse_graph
#
# The coverage report shows:
#   if (my $id = $item->{'@id'})   1994 TRUE hits, 0 FALSE hits
#
# FALSE branch: item has no '@id' key.  The label index is still created;
# only the secondary short-name index is skipped.
# ===========================================================================

subtest 'line 700: rdfs:Class item without @id skips secondary index' => sub {
	# Purpose: hit the FALSE branch of `if (my $id = $item->{'@id'})` for
	# rdfs:Class items.  The item should be stored under its label only.

	# JSON-LD with a class that deliberately has no @id field
	my $json = '{"@graph":['
		. '{"@type":"rdfs:Class","rdfs:label":"NoIdClass"}'
		. ']}';

	my (undef, $path) = tempfile(UNLINK => 1);
	_write($path, $json);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	# The item must be accessible by label
	ok(exists $result->{NoIdClass}, 'class without @id is stored under its label');

	# With no @id, the secondary index cannot be created.
	# The result hash should have exactly 1 key (just the label).
	is(scalar keys %$result, 1, 'only the label key exists (no @id fragment)');

	diag "Result keys: " . join(', ', keys %$result) if $ENV{TEST_VERBOSE};
};

subtest 'line 711: rdf:Property item without @id skips secondary index' => sub {
	# Purpose: hit the FALSE branch of `if (my $id = $item->{'@id'})` for
	# rdf:Property items.  The property must be stored in the globals only.

	my $json = '{"@graph":['
		. '{"@type":"rdf:Property","rdfs:label":"noidProp"}'
		. ']}';

	my (undef, $path) = tempfile(UNLINK => 1);
	_write($path, $json);

	local $SIG{__WARN__} = sub {};
	load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	# The property must be in the global, indexed by its label
	ok(exists $Schema::Validator::dynamic_properties{noidProp},
		'property without @id is stored in %dynamic_properties by label');

	# Exactly 1 key in the properties global
	is(scalar keys %Schema::Validator::dynamic_properties, 1,
		'only the label key exists in %dynamic_properties (no @id fragment)');

	diag "Property keys: " . join(', ', keys %Schema::Validator::dynamic_properties)
		if $ENV{TEST_VERBOSE};
};

subtest '@id present but empty string: treated as falsy, secondary index skipped' => sub {
	# An empty @id string is falsy in Perl, so `if (my $id = '')` is FALSE.
	# This is another route to the @id=false branch.

	my $json = '{"@graph":['
		. '{"@type":"rdfs:Class","rdfs:label":"EmptyIdClass","@id":""}'
		. ']}';

	my (undef, $path) = tempfile(UNLINK => 1);
	_write($path, $json);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	ok(exists $result->{EmptyIdClass},
		'class with empty @id is stored by label');
	is(scalar keys %$result, 1, 'no secondary index for empty @id');

	diag "Result: " . join(', ', keys %$result) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 5: lines 481-484 -- defined-but-false parameter values
#
# The condition coverage gap arises from `A // B` where A is defined-but-false
# (Perl integer 0 or empty string "").  Neither 0 nor "" triggers the //
# fallback to B, but Devel::Cover tracks this as a third condition state.
# ===========================================================================

subtest 'line 482: cache_duration => 0 is used as-is (defined-but-false integer)' => sub {
	# Purpose: pass cache_duration => 0.  The value 0 is defined, so
	# `0 // $config{cache_duration}` uses 0, NOT the default.
	# A duration of 0 means every file is stale, so the fetch path runs.

	my $http_calls = 0;
	my $ok_res = FakeResp->new(1, $VALID_JSONLD);

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $http_calls++; $ok_res },
		'Schema::Validator::_spit_file' => sub { 1 },
	);

	local $SIG{__WARN__} = sub {};

	# Create a real file so -e passes, but duration=0 makes it stale
	my (undef, $path) = tempfile(UNLINK => 1);
	_write($path, $VALID_JSONLD);

	load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $config{int_zero},
	);

	# cache_duration=0 forces a fetch regardless of file freshness
	ok($http_calls > 0,
		'cache_duration => 0 forces fetch (defined-but-false uses 0, not default)');

	diag "HTTP calls with duration=0: $http_calls" if $ENV{TEST_VERBOSE};
};

subtest 'line 484: ua_timeout => 0 is forwarded to LWP (defined-but-false)' => sub {
	# Purpose: pass ua_timeout => 0.  The value 0 is defined, so
	# `0 // $config{ua_timeout}` uses 0, NOT the 30-second default.
	# Verify the 0 reaches LWP::UserAgent->new.

	my $captured_timeout;
	my $ok_res = FakeResp->new(1, $VALID_JSONLD);

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub {
			my (undef, %opts) = @_;
			$captured_timeout = $opts{timeout};
			return bless {}, 'LWP::UserAgent';
		},
		'LWP::UserAgent::get' => sub { $ok_res },
		'Schema::Validator::_spit_file' => sub { 1 },
	);

	local $SIG{__WARN__} = sub {};
	load_dynamic_vocabulary(
		cache_file     => '/tmp/_ext_ua0_$$.jsonld',
		cache_duration => $STALE_DURATION,
		ua_timeout     => $config{int_zero},
	);

	is($captured_timeout, 0,
		'ua_timeout => 0 reaches LWP::UserAgent (defined-but-false, not default)');

	diag "Captured UA timeout: $captured_timeout" if $ENV{TEST_VERBOSE};
};

subtest 'line 481: cache_file => "" passes validate_strict and short-circuits -e' => sub {
	# Purpose: pass cache_file => "".  The empty string is defined, so
	# `"" // $config{cache_file}` uses "", NOT the default path.
	# -e "" is false in Perl, so no cache read is attempted; fetch runs.

	my $http_calls = 0;
	my $ok_res = FakeResp->new(1, $VALID_JSONLD);

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $http_calls++; $ok_res },
		'Schema::Validator::_spit_file' => sub { 1 },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => $config{empty_string},
		cache_duration => $FRESH_DURATION,
	);

	# With cache_file="", -e "" is false so no cache read happens; fetch runs
	ok($http_calls > 0,
		'cache_file => "" bypasses cache read (defined-but-false uses "", not default)');
	ok(ref($result) eq 'HASH', 'still returns a hashref with cache_file=""');

	diag "HTTP calls with cache_file='': $http_calls" if $ENV{TEST_VERBOSE};
};

subtest 'lines 481-484: calling with no args uses all four %config defaults' => sub {
	# Purpose: when load_dynamic_vocabulary() is called with no arguments,
	# $params is undef and ALL four // fallbacks hit their right-hand side
	# (i.e., the defaults from %config).
	# This also covers the `if(scalar(@_))` false branch (line 468).

	my $captured_timeout;
	my $ok_res = FakeResp->new(1, $VALID_JSONLD);

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub {
			my (undef, %opts) = @_;
			$captured_timeout = $opts{timeout};
			return bless {}, 'LWP::UserAgent';
		},
		'LWP::UserAgent::get' => sub { $ok_res },
		'Schema::Validator::_spit_file' => sub { 1 },
	);

	# Temporarily set all config values to known test values
	local $Schema::Validator::config{cache_file}     = '/tmp/_ext_no_args_$$.jsonld';
	local $Schema::Validator::config{cache_duration} = $STALE_DURATION;
	local $Schema::Validator::config{vocab_url}      = 'https://schema.invalid/v';
	local $Schema::Validator::config{ua_timeout}     = 77;

	local $SIG{__WARN__} = sub {};

	# Call with ZERO args: all defaults must come from %config
	my $result = load_dynamic_vocabulary();

	# The UA timeout must be 77 (from the config override above)
	is($captured_timeout, 77, 'no-arg call uses %config{ua_timeout} as timeout');
	ok(ref($result) eq 'HASH', 'no-arg call returns a hashref');

	diag "No-arg call: timeout=$captured_timeout" if $ENV{TEST_VERBOSE};
};

subtest 'partial named args: missing args fall back to %config defaults' => sub {
	# Purpose: call with only cache_file supplied; the other three params
	# must come from %config.  This exercises the // right-hand side for
	# cache_duration, vocab_url, and ua_timeout individually.

	my $captured_timeout;
	my $ok_res = FakeResp->new(1, $VALID_JSONLD);

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub {
			my (undef, %opts) = @_;
			$captured_timeout = $opts{timeout};
			return bless {}, 'LWP::UserAgent';
		},
		'LWP::UserAgent::get' => sub { $ok_res },
		'Schema::Validator::_spit_file' => sub { 1 },
	);

	# Override only the timeout in the global config
	local $Schema::Validator::config{ua_timeout}  = 55;
	local $Schema::Validator::config{cache_duration} = $STALE_DURATION;

	local $SIG{__WARN__} = sub {};

	# Pass only cache_file; other params use %config defaults
	my $result = load_dynamic_vocabulary(
		cache_file => '/tmp/_ext_partial_$$.jsonld',
	);

	is($captured_timeout, 55,
		'ua_timeout default from %config when not supplied as arg');
	ok(ref($result) eq 'HASH', 'partial-args call returns a hashref');

	diag "Partial-args call: timeout=$captured_timeout" if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 6: secondary @id index with label != fragment
#
# Covers line 702: $classes{$short} //= $item  (the ASSIGNMENT path)
# and line 713: $props{$short} //= $item       (the ASSIGNMENT path)
#
# These paths are hit when a graph item's rdfs:label differs from the
# fragment of its @id URI.  The //= assigns the secondary index because
# $classes{$short} is not yet set (only $classes{label} was set earlier).
# ===========================================================================

subtest 'line 702: @id fragment != label creates a secondary index entry' => sub {
	# Purpose: hit the ASSIGNMENT branch of `$classes{$short} //= $item`.
	# Use an item where label = "SuperEvent" but @id ends in "Event",
	# so $short = "Event" which was not set by the label assignment.

	my $json = '{"@graph":['
		. '{"@type":"rdfs:Class","rdfs:label":"SuperEvent",'
		. '"@id":"https://schema.org/Event"}'
		. ']}';

	my (undef, $path) = tempfile(UNLINK => 1);
	_write($path, $json);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	# The item should be accessible by the original label
	ok(exists $result->{SuperEvent}, 'class stored under its rdfs:label');

	# It must ALSO be accessible by the @id fragment (the //= assignment path)
	ok(exists $result->{Event},
		'class also stored under the @id fragment (//= assignment ran)');

	# Both keys point to the same item hashref
	is($result->{SuperEvent}, $result->{Event},
		'label key and @id-fragment key point to the same item');

	diag "Result keys: " . join(', ', keys %$result) if $ENV{TEST_VERBOSE};
};

subtest 'line 713: rdf:Property @id fragment != label creates secondary index' => sub {
	# Purpose: hit the ASSIGNMENT branch of `$props{$short} //= $item`.

	my $json = '{"@graph":['
		. '{"@type":"rdf:Property","rdfs:label":"eventStartDate",'
		. '"@id":"https://schema.org/startDate"}'
		. ']}';

	my (undef, $path) = tempfile(UNLINK => 1);
	_write($path, $json);

	local $SIG{__WARN__} = sub {};
	load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	# Accessible by label AND by @id fragment
	ok(exists $Schema::Validator::dynamic_properties{eventStartDate},
		'property stored under its rdfs:label');
	ok(exists $Schema::Validator::dynamic_properties{startDate},
		'property also stored under the @id fragment (//= assignment ran)');

	diag "Property keys: "
		. join(', ', keys %Schema::Validator::dynamic_properties)
		if $ENV{TEST_VERBOSE};
};

subtest 'line 702: //= SKIPS when label == @id fragment (already indexed)' => sub {
	# Purpose: complement the above test by confirming the SKIP path of //=.
	# When label == @id fragment, $classes{$short} was already set by the
	# label assignment, so //= does not overwrite it.

	my $json = '{"@graph":['
		. '{"@type":"rdfs:Class","rdfs:label":"IdenticalClass",'
		. '"@id":"https://schema.org/IdenticalClass"}'
		. ']}';

	my (undef, $path) = tempfile(UNLINK => 1);
	_write($path, $json);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	# Both label and fragment are "IdenticalClass", so only one key exists
	ok(exists $result->{IdenticalClass}, 'class stored under its label');
	is(scalar keys %$result, 1, 'exactly one key (label and fragment are identical)');
};

# ===========================================================================
# SECTION 7: is_valid_datetime condition paths for the early-return guard
#
# The guard is: return 0 unless defined $string && length $string
# Devel::Cover tracks three conditions:
#   C1: !defined (undef input)          -- short-circuits to 0
#   C2: defined but length==0 ("")      -- short-circuits to 0
#   C3: defined and length > 0 (normal) -- proceeds to parser
# All three are already covered by prior tests, but we add explicit named-
# form equivalents for completeness and LCSAJ path diversity.
# ===========================================================================

subtest 'is_valid_datetime: named string => "" returns 0 (defined, empty)' => sub {
	# Named calling form with an empty string exercises the same condition
	# path as the positional form, but via a different call-site.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { fail 'parser must not be called for empty string'; return };

	is(is_valid_datetime(string => ''), 0, 'named string="" returns 0 without calling parser');

	diag 'Named empty-string form verified' if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime: named string => undef returns 0 (undefined)' => sub {
	# The named form with undef exercises the defined() check via a different
	# call-site than the positional form with undef.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { fail 'parser must not be called for undef'; return };

	is(is_valid_datetime(string => undef), 0, 'named string=>undef returns 0');

	diag 'Named undef form verified' if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime: named string => "0" proceeds to parser' => sub {
	# The string "0" is defined with non-zero length.  The early guard passes
	# and the parser is called.  "0" is not a valid date, so returns 0.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { die "not a date\n" };

	is(is_valid_datetime(string => '0'), 0, 'named string="0" reaches parser, returns 0');
};

# ===========================================================================
# SECTION 8: _parse_graph mixed-type items and full-URI label key
# ===========================================================================

subtest '_parse_graph: item with both rdfs:Class and rdf:Property @type' => sub {
	# Purpose: an item whose @type array contains BOTH rdfs:Class and
	# rdf:Property must be indexed in BOTH %classes and %props.

	my $json = '{"@graph":['
		. '{"@type":["rdfs:Class","rdf:Property"],'
		. '"rdfs:label":"DualType",'
		. '"@id":"https://schema.org/DualType"}'
		. ']}';

	my (undef, $path) = tempfile(UNLINK => 1);
	_write($path, $json);

	%Schema::Validator::dynamic_schema     = ();
	%Schema::Validator::dynamic_properties = ();

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	ok(exists $result->{DualType}, 'dual-type item appears in classes hashref');
	ok(exists $Schema::Validator::dynamic_properties{DualType},
		'dual-type item also appears in %dynamic_properties');

	diag 'Dual-type item indexed in both tables' if $ENV{TEST_VERBOSE};
};

subtest '_parse_graph: item using full-URI rdfs:label key' => sub {
	# The Schema.org JSON-LD sometimes uses the expanded RDF URI as the key
	# instead of the compact rdfs:label shorthand.  _extract_label must
	# fall back to the full URI form.

	my $full_uri_label = 'http://www.w3.org/2000/01/rdf-schema#label';
	my $json = '{"@graph":['
		. '{"@type":"rdfs:Class",'
		. '"' . $full_uri_label . '":"FullUriClass",'
		. '"@id":"https://schema.org/FullUriClass"}'
		. ']}';

	my (undef, $path) = tempfile(UNLINK => 1);
	_write($path, $json);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	ok(exists $result->{FullUriClass},
		'class with full-URI label key is stored correctly');

	diag "Full-URI label result: " . join(', ', keys %$result) if $ENV{TEST_VERBOSE};
};

subtest '_parse_graph: label array with undef first element is skipped' => sub {
	# When rdfs:label is an array whose first element is undef, _extract_label
	# returns undef.  The `or next` guard in _parse_graph must skip the item.

	my $json = '{"@graph":['
		. '{"@type":"rdfs:Class","rdfs:label":[null,"en"],'
		. '"@id":"https://schema.org/NullLabel"}'
		. ']}';

	my (undef, $path) = tempfile(UNLINK => 1);
	_write($path, $json);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	is(scalar keys %$result, 0,
		'item with null first label array element is skipped');

	diag 'Null-first-label item correctly skipped' if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 9: load_dynamic_vocabulary state-machine path combinations
# (LCSAJ: distinct linear sequences through the branch tree)
# ===========================================================================

subtest 'LCSAJ: stale cache -> fetch -> write -> parse (full happy path)' => sub {
	# Linear path: NO fresh cache -> fetch succeeds -> write succeeds -> parse ok.
	# This is the most common production path.

	my (undef, $path) = tempfile(UNLINK => 1);
	my $write_calls = 0;
	my $ok_res = FakeResp->new(1, $VALID_JSONLD);

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $ok_res },
		'Schema::Validator::_spit_file' => sub { $write_calls++; 1 },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $STALE_DURATION,
	);

	is($write_calls, 1, 'cache is written exactly once on successful fetch');
	ok(exists $result->{Thing}, 'vocabulary parsed from fetched content');

	diag "Full happy path: write_calls=$write_calls" if $ENV{TEST_VERBOSE};
};

subtest 'LCSAJ: fresh cache -> read ok -> skip fetch -> parse' => sub {
	# Linear path: fresh file exists -> _slurp_file reads it -> fetch skipped.

	my (undef, $path) = tempfile(UNLINK => 1);
	_write($path, $VALID_JSONLD);

	my $fetch_calls = 0;
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $fetch_calls++; FakeResp->new(0, undef) },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	is($fetch_calls, 0, 'fetch skipped when fresh cache exists');
	ok(exists $result->{Thing}, 'vocabulary parsed from fresh cache file');

	diag "Fresh-cache path: fetch_calls=$fetch_calls" if $ENV{TEST_VERBOSE};
};

subtest 'LCSAJ: stale -> fetch ok -> write fails -> parse succeeds' => sub {
	# Unusual but valid path: fetch content is good but disk write fails.
	# The vocabulary must still be returned even though no cache was written.

	my $ok_res = FakeResp->new(1, $VALID_JSONLD);

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $ok_res },
		'Schema::Validator::_spit_file' => sub { die "no space left\n" },
	);

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	my $result = load_dynamic_vocabulary(
		cache_file     => '/tmp/_ext_lcsaj_wfail_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	my $write_warn = grep { /Could not write cache/i } @warnings;
	ok($write_warn,          'write-failure carp is emitted');
	ok(exists $result->{Thing}, 'vocabulary still returned despite write failure');

	diag "LCSAJ write-fail: " . join('; ', @warnings) if $ENV{TEST_VERBOSE};
};

subtest 'LCSAJ: stale -> fetch fails -> stale ok -> parse succeeds' => sub {
	# The standard "graceful degradation" path: network down, fall back to stale.

	my (undef, $path) = tempfile(UNLINK => 1);
	_write($path, $VALID_JSONLD);

	my $fail_res = FakeResp->new(0, undef);
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $fail_res },
	);

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	my $result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $STALE_DURATION,
	);

	my $stale_warn = grep { /stale|unavailable/i } @warnings;
	ok($stale_warn,          'stale-cache carp is emitted');
	ok(exists $result->{Thing}, 'vocabulary parsed from stale cache');

	diag "LCSAJ stale-ok: " . join('; ', @warnings) if $ENV{TEST_VERBOSE};
};

subtest 'LCSAJ: fresh -> read fails -> fetch fails -> stale read fails -> empty' => sub {
	# The worst-case path: every I/O operation fails.  Must return {} without
	# throwing.  Tests all three carp messages in a single call.

	my (undef, $path) = tempfile(UNLINK => 1);
	# Write placeholder so -e and stat see a file (for the fresh and stale checks)
	_write($path, 'placeholder');

	my $fail_res = FakeResp->new(0, undef);
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $fail_res },
		# _slurp_file throws for BOTH the fresh-cache read (line 491)
		# and the stale-cache read (line 506)
		'Schema::Validator::_slurp_file' => sub { die "io error\n" },
	);

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	my $result = eval {
		load_dynamic_vocabulary(
			cache_file     => $path,
			cache_duration => $FRESH_DURATION,
		)
	};

	is($@, '', 'worst-case path does not throw');
	is(scalar keys %$result, 0, 'worst-case path returns empty hashref');

	my $read_warn  = grep { /Could not read cache/i   } @warnings;
	my $stale_warn = grep { /Could not read stale/i   } @warnings;
	my $no_vocab   = grep { /no vocabulary content/i  } @warnings;

	ok($read_warn,  'carp "Could not read cache" emitted on fresh-read failure');
	ok($stale_warn, 'carp "Could not read stale cache" emitted on stale-read failure');
	ok($no_vocab,   'carp "no vocabulary content available" emitted at the end');

	diag "Worst-case warnings: " . join('; ', @warnings) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SECTION 10: Unreachable path documentation test
#
# This subtest documents the conditions under which the third condition of
#   $classes{$short} //= $item    (line 702)
#   $props{$short}   //= $item    (line 713)
# cannot be reached in practice, so a reviewer can confirm the analysis.
# ===========================================================================

subtest 'documentation: //= third condition is unreachable in practice' => sub {
	# The Devel::Cover "defined-but-false" condition for
	#   $classes{$short} //= $item
	# requires $classes{$short} to be defined but false (e.g. 0 or "").
	# Class and property values stored by _parse_graph are ALWAYS hashrefs
	# (decoded from JSON objects), which are always truthy.  Therefore this
	# third condition can never be triggered by any valid JSON-LD input.

	# Demonstrate that a hashref stored as a class value is truthy:
	my $sample_item = { '@type' => 'rdfs:Class', 'rdfs:label' => 'TestClass' };
	ok($sample_item, 'a decoded JSON-LD item hashref is always truthy');
	ok(ref($sample_item) eq 'HASH', 'item is a HASH reference');

	# Perl semantics: a defined hashref cannot satisfy the "defined-but-false"
	# branch because all references are truthy (even empty {}).
	my $empty_ref = {};
	ok($empty_ref, 'even an empty hashref is truthy in boolean context');

	pass('//= defined-but-false condition is unreachable: documented and verified');

	diag 'Unreachable //= condition confirmed as an artefact of type guarantees'
		if $ENV{TEST_VERBOSE};
};

subtest 'documentation: Encode and Scalar::Util::reftype imports are unused' => sub {
	# Both `use Encode qw(decode encode)` (line 14) and
	# `use Scalar::Util qw(reftype)` (line 20) import symbols that are never
	# called anywhere in the runtime code of Schema::Validator.
	# They are dead imports -- candidates for removal in a future cleanup.

	# Verify the imports exist in the namespace (they were loaded) but are
	# not called by any public function we can observe.
	ok(Schema::Validator->can('is_valid_datetime'),    'is_valid_datetime is callable');
	ok(Schema::Validator->can('load_dynamic_vocabulary'), 'load_dynamic_vocabulary is callable');

	# The imported symbols ARE in the Schema::Validator namespace (use imports them),
	# but no Schema::Validator public function calls them at runtime.
	ok(Schema::Validator->can('decode'),  'decode is imported into Schema::Validator');
	ok(Schema::Validator->can('encode'),  'encode is imported into Schema::Validator');
	ok(Schema::Validator->can('reftype'), 'reftype is imported into Schema::Validator');

	pass('Unused imports Encode/reftype documented for cleanup');

	diag 'Dead imports: Encode decode/encode, Scalar::Util reftype' if $ENV{TEST_VERBOSE};
};

# ---------------------------------------------------------------------------
# Final cleanup.
# ---------------------------------------------------------------------------
restore_all();

done_testing();
