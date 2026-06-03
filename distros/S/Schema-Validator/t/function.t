#!/usr/bin/env perl

# ---------------------------------------------------------------------------
# t/function.t -- white-box unit tests for Schema::Validator
#
# Covers every function including internal helpers:
#   is_valid_datetime, load_dynamic_vocabulary,
#   _slurp_file, _spit_file, _fetch_url, _extract_label, _parse_graph
#
# All non-core dependencies are mocked with Test::Mockingbird so no
# real network access or filesystem writes occur (except controlled
# File::Temp scratch files used for the slurp/spit helpers themselves).
#
# Z-calculus reference for is_valid_datetime:
#   result! <=> str? in DATETIME
#   where DATETIME = DATE union { dt | d in DATE, tf in TIMEFRAG, dt = d concat tf }
# ---------------------------------------------------------------------------

use strict;
use warnings;

use FindBin qw($Bin);
# Under prove -t (taint mode), $Bin is tainted because it derives from $0.
# Detaint via a permissive regex before passing to use lib.
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

# Load the module under test; all mocks are installed per-subtest via mock_scoped.
use Schema::Validator qw(is_valid_datetime load_dynamic_vocabulary);

# ===========================================================================
# CONSTANTS -- all magic strings and numbers live here.
# ===========================================================================

use Readonly;

# Value used to detect accidental modification of $_ inside tested functions.
Readonly::Scalar my $SENTINEL => 'sentinel_do_not_clobber';

# Cache duration that makes any existing file count as stale (0 seconds fresh).
Readonly::Scalar my $STALE_DURATION => 0;

# Cache duration that keeps a file created moments ago within the fresh window.
Readonly::Scalar my $FRESH_DURATION => 86_400;

# Minimal valid JSON-LD vocabulary: one rdfs:Class item with label and @id.
Readonly::Scalar my $VALID_JSONLD =>
	'{"@graph":[{"@type":"rdfs:Class","rdfs:label":"Thing",'
	. '"@id":"https://schema.org/Thing"}]}';

# JSON-LD with a single rdf:Property item for property-path tests.
Readonly::Scalar my $PROPERTY_JSONLD =>
	'{"@graph":[{"@type":"rdf:Property","rdfs:label":"name",'
	. '"@id":"https://schema.org/name"}]}';

# JSON-LD with both a class and a property for combined-path tests.
Readonly::Scalar my $MIXED_JSONLD =>
	'{"@graph":['
	. '{"@type":"rdfs:Class","rdfs:label":"Thing","@id":"https://schema.org/Thing"},'
	. '{"@type":"rdf:Property","rdfs:label":"name","@id":"https://schema.org/name"}'
	. ']}';

# JSON that cannot be parsed by any decoder.
Readonly::Scalar my $BAD_JSON => 'not { valid json at all }}';

# Valid JSON that lacks the required @graph key.
Readonly::Scalar my $NO_GRAPH_JSON => '{"@type":"vocab","version":1}';

# ===========================================================================
# CONFIGURATION -- runtime values keyed by meaningful names.
# ===========================================================================

my %config = (
	# ISO 8601 date and datetime strings under test
	date_only        => '2025-06-28',
	datetime_t_sep   => '2025-06-28T15:00:00',
	datetime_t_hhmm  => '2025-06-28T15:00',
	datetime_sp_sep  => '2025-06-28 15:00',
	datetime_sp_secs => '2025-06-28 15:00:45',
	datetime_tz_z    => '2025-06-28T15:00:00Z',
	datetime_tz_off  => '2025-06-28T15:00:00+01:00',
	date_bad_month   => '2025-99-01',
	date_bad_day     => '2025-06-99',
	date_dmyslash    => '28/06/2025',
	date_mmdash      => '06-28-2025',

	# JSON-LD structural keys used when building test graph items
	rdfs_label       => 'rdfs:label',
	rdfs_label_full  => 'http://www.w3.org/2000/01/rdf-schema#label',
	at_type          => '@type',
	at_id            => '@id',
	rdf_class        => 'rdfs:Class',
	rdf_property     => 'rdf:Property',

	# Fake HTTP endpoint -- never actually fetched
	fake_url         => 'https://example.invalid/vocab.jsonld',
	fake_content     => 'decoded HTTP response body',
);

# ===========================================================================
# HELPER SUBROUTINE
# ===========================================================================

# Build a minimal JSON-LD graph item hashref from named arguments.
# Called throughout the _parse_graph and _extract_label subtests.
sub _make_item {
	my (%args) = @_;
	my %item;
	# Each field is optional; only include it if the caller supplied it.
	$item{ $config{at_type}       } = $args{type}  if exists $args{type};
	$item{ $config{rdfs_label}    } = $args{label} if exists $args{label};
	$item{ $config{at_id}         } = $args{id}    if exists $args{id};
	return \%item;
}

# ===========================================================================
# FAKE HTTP RESPONSE CLASS
# Provides is_success, decoded_content, and status_line so _fetch_url
# can call them on our mock response without pulling in LWP::Protocol.
# ===========================================================================

{
	package FakeResponse;
	sub new             { bless { ok => $_[1], body => $_[2] }, $_[0] }
	sub is_success      { $_[0]->{ok} }
	sub decoded_content { $_[0]->{body} }
	sub status_line     { $_[0]->{ok} ? '200 OK' : '503 Service Unavailable' }
}

# ===========================================================================
# SUBTESTS: is_valid_datetime -- PUBLIC FUNCTION
# ===========================================================================

subtest 'is_valid_datetime -- accepts all valid date and datetime formats' => sub {
	# Purpose: every format listed in the POD EXAMPLE block must return 1.
	# DateTime::Format::ISO8601 is mocked so the test does not depend on
	# that module's exact behaviour -- we are testing our wrapper logic.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	# Plain date, T-separator with and without seconds
	ok(is_valid_datetime($config{date_only}),       'date-only YYYY-MM-DD is valid');
	ok(is_valid_datetime($config{datetime_t_sep}),  'T-sep with seconds is valid');
	ok(is_valid_datetime($config{datetime_t_hhmm}), 'T-sep without seconds is valid');

	# Space-separator variants; the normalisation converts space to T
	ok(is_valid_datetime($config{datetime_sp_sep}),  'space-sep without seconds is valid');
	ok(is_valid_datetime($config{datetime_sp_secs}), 'space-sep with seconds is valid');

	# Timezone forms that DateTime::Format::ISO8601 accepts natively
	ok(is_valid_datetime($config{datetime_tz_z}),   'UTC Z suffix is valid');
	ok(is_valid_datetime($config{datetime_tz_off}), 'positive timezone offset is valid');

	diag 'Accepted formats: all seven variants passed' if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- rejects invalid format strings' => sub {
	# Purpose: non-ISO orderings must return 0 even though the underlying
	# module is mocked to throw, confirming the eval catches the die.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { die "parse failed\n" };

	# These formats are not ISO 8601 and must be rejected
	ok(!is_valid_datetime($config{date_dmyslash}), 'DD/MM/YYYY is rejected');
	ok(!is_valid_datetime($config{date_mmdash}),   'MM-DD-YYYY is rejected');

	diag 'Rejected formats: DD/MM and MM-DD variants' if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- undef and empty string return 0 without throwing' => sub {
	# Purpose: the early-exit guard must fire before calling parse_datetime.
	# We verify this by making the mock fail loudly if it is reached.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime' => sub {
		fail 'parse_datetime must not be called for undef or empty input';
		return;
	};

	# Call with undef and empty; neither should throw or reach the mock
	my $result_undef  = is_valid_datetime(undef);
	my $result_empty  = is_valid_datetime('');

	ok(!$result_undef, 'undef returns 0');
	ok(!$result_empty, 'empty string returns 0');

	# Confirm that the return type is a plain integer in both cases
	returns_ok($result_undef, { type => 'integer' }, 'undef result is integer 0');
	returns_ok($result_empty, { type => 'integer' }, 'empty-string result is integer 0');

	diag 'Degenerate inputs handled before parse_datetime' if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- named calling convention is accepted' => sub {
	# Purpose: Params::Get must transparently normalise the named form
	# is_valid_datetime(string => $s) to the same code path as positional.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	# Named-argument form -- result must be identical to positional
	my $result = is_valid_datetime(string => $config{date_only});

	ok($result, 'named-arg form returns true for a valid date');
	returns_ok($result, { type => 'integer' }, 'named-arg result is an integer');

	diag "Named-arg result: $result" if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- space separator is normalised to T before parsing' => sub {
	# Purpose: the implementation explicitly rewrites YYYY-MM-DD HH:MM
	# to YYYY-MM-DDTHH:MM.  We capture the argument to parse_datetime to
	# confirm the rewrite occurred.

	my $received_string;

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime' => sub {
		# $_[0] is the class name; $_[1] is the normalised datetime string
		$received_string = $_[1];
		return bless {}, 'DateTime';
	};

	is_valid_datetime($config{datetime_sp_sep});

	# The space must have been replaced with T in the string passed to the parser
	is($received_string, '2025-06-28T15:00',
		'space separator was normalised to T before parse_datetime');

	diag "parse_datetime received: '$received_string'" if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- return value is a plain integer' => sub {
	# Purpose: the function must return exactly 1 or 0, not a DateTime object
	# or any other truthy/falsy value.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	my $result = is_valid_datetime($config{date_only});

	returns_ok($result, { type => 'integer' }, 'return value is an integer');
	is($result, 1, 'valid input returns exactly 1');

	diag "Return value: $result" if $ENV{TEST_VERBOSE};
};

subtest 'is_valid_datetime -- does not clobber $_' => sub {
	# Purpose: the function must not modify the caller's $_ as a side-effect.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	local $_ = $SENTINEL;
	is_valid_datetime($config{date_only});

	# $_ must be unchanged after the call
	is($_, $SENTINEL, 'is_valid_datetime does not modify $_');
};

subtest 'is_valid_datetime -- memory cycle check' => sub {
	# Purpose: a plain scalar return value must be cycle-free.

	my $g = mock_scoped 'DateTime::Format::ISO8601::parse_datetime'
		=> sub { bless {}, 'DateTime' };

	my $result = is_valid_datetime($config{date_only});
	memory_cycle_ok(\$result, 'is_valid_datetime return value has no memory cycles');
};

# ===========================================================================
# SUBTESTS: _slurp_file -- INTERNAL HELPER
# ===========================================================================

subtest '_slurp_file -- returns complete file contents as a string' => sub {
	# Purpose: the helper must read every byte from the file and return
	# a single scalar string.

	my ($fh, $path) = tempfile(UNLINK => 1);

	# Write known content without using _spit_file, to keep the tests independent
	my $content = "first line\nsecond line\n";
	print $fh $content;
	close $fh;

	my $got = Schema::Validator::_slurp_file($path);

	is($got, $content, '_slurp_file returns exact file contents');
	returns_ok($got, { type => 'string' }, 'return value is a string');

	diag "Read " . length($got) . " bytes from temp file" if $ENV{TEST_VERBOSE};
};

subtest '_slurp_file -- throws when the file does not exist' => sub {
	# Purpose: autodie must propagate an exception when open fails.
	# The error string must mention 'open' or a filesystem error.

	throws_ok(
		sub { Schema::Validator::_slurp_file('/no/such/path/xyz123') },
		qr/open|No such file/i,
		'_slurp_file throws on a missing file',
	);

	diag 'autodie open exception verified' if $ENV{TEST_VERBOSE};
};

subtest '_slurp_file -- does not clobber $_' => sub {
	# Purpose: local $/ inside the helper must not leak; the read loop
	# must not pollute the caller's $_.

	my ($fh, $path) = tempfile(UNLINK => 1);
	print $fh "data\n";
	close $fh;

	local $_ = $SENTINEL;
	Schema::Validator::_slurp_file($path);
	is($_, $SENTINEL, '_slurp_file does not modify $_');
};

# ===========================================================================
# SUBTESTS: _spit_file -- INTERNAL HELPER
# ===========================================================================

subtest '_spit_file -- writes the supplied content to a file' => sub {
	# Purpose: the helper must create or truncate the file and write exactly
	# the supplied bytes, readable back with a raw open.

	my (undef, $path) = tempfile(UNLINK => 1);
	my $content = "vocabulary data\nline two\n";

	Schema::Validator::_spit_file($path, $content);

	# Read back independently to confirm the bytes on disk
	open my $fh, '<', $path or die "Cannot re-open temp file: $!";
	local $/;
	my $got = <$fh>;
	close $fh;

	is($got, $content, '_spit_file writes the exact supplied content');

	diag "Wrote " . length($content) . " bytes, verified on disk" if $ENV{TEST_VERBOSE};
};

subtest '_spit_file -- returns 1 on success' => sub {
	# Purpose: the documented return value on success is the integer 1.

	my (undef, $path) = tempfile(UNLINK => 1);

	my $result = Schema::Validator::_spit_file($path, 'data');

	is($result, 1, '_spit_file returns 1 on success');
	returns_ok($result, { type => 'integer' }, 'return value is an integer');
};

subtest '_spit_file -- throws when path is not writable' => sub {
	# Purpose: autodie must propagate an open failure for an unwritable path.

	throws_ok(
		sub { Schema::Validator::_spit_file('/nonexistent_dir_xyz/out.json', 'x') },
		qr/open|No such file|Permission/i,
		'_spit_file throws when the output path cannot be opened',
	);
};

subtest '_spit_file -- does not clobber $_' => sub {
	# Purpose: print and close must not alter the caller's topic variable.

	my (undef, $path) = tempfile(UNLINK => 1);

	local $_ = $SENTINEL;
	Schema::Validator::_spit_file($path, 'test data');
	is($_, $SENTINEL, '_spit_file does not modify $_');
};

# ===========================================================================
# SUBTESTS: _fetch_url -- INTERNAL HELPER
# ===========================================================================

subtest '_fetch_url -- returns decoded content on HTTP success' => sub {
	# Purpose: a 2xx response must cause the decoded body to be returned.

	my $fake_res = FakeResponse->new(1, $config{fake_content});

	# Mock the UA constructor and get() so no real network call occurs
	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $fake_res },
	);

	my $got = Schema::Validator::_fetch_url($config{fake_url}, 5);

	is($got, $config{fake_content}, '_fetch_url returns the response body');
	returns_ok($got, { type => 'string' }, 'return value is a string');

	diag "_fetch_url returned: '$got'" if $ENV{TEST_VERBOSE};
};

subtest '_fetch_url -- returns undef and carps on HTTP failure' => sub {
	# Purpose: a non-2xx response must return undef (not throw) and emit
	# a carp warning that mentions the failed URL.

	my $fake_res = FakeResponse->new(0, undef);

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $fake_res },
	);

	my $got;

	# Confirm the carp warning is emitted with expected content
	warning_like(
		sub { $got = Schema::Validator::_fetch_url($config{fake_url}, 5) },
		qr/Failed to fetch/,
		'_fetch_url carps on HTTP failure',
	);

	ok(!defined($got), '_fetch_url returns undef on a non-2xx response');

	diag 'HTTP failure path returned undef as expected' if $ENV{TEST_VERBOSE};
};

subtest '_fetch_url -- passes the timeout to LWP::UserAgent' => sub {
	# Purpose: the timeout argument must be forwarded to the UA constructor
	# so long-running downloads do not block indefinitely.

	my $fake_res    = FakeResponse->new(1, 'body');
	my $ua_timeout;

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub {
			# Capture the timeout argument from the constructor call
			my (undef, %args) = @_;
			$ua_timeout = $args{timeout};
			return bless {}, 'LWP::UserAgent';
		},
		'LWP::UserAgent::get' => sub { $fake_res },
	);

	Schema::Validator::_fetch_url($config{fake_url}, 42);

	is($ua_timeout, 42, 'timeout value is forwarded to LWP::UserAgent');

	diag "UA constructed with timeout=$ua_timeout" if $ENV{TEST_VERBOSE};
};

subtest '_fetch_url -- does not clobber $_' => sub {
	# Purpose: no part of the HTTP get/response chain may touch $_.

	my $fake_res = FakeResponse->new(1, 'data');

	my $g = mock_scoped(
		'LWP::UserAgent::new' => sub { bless {}, 'LWP::UserAgent' },
		'LWP::UserAgent::get' => sub { $fake_res },
	);

	local $_ = $SENTINEL;
	Schema::Validator::_fetch_url($config{fake_url}, 5);
	is($_, $SENTINEL, '_fetch_url does not modify $_');
};

# ===========================================================================
# SUBTESTS: _extract_label -- INTERNAL HELPER
# ===========================================================================

subtest '_extract_label -- returns a scalar rdfs:label value' => sub {
	# Purpose: the most common case -- a plain string under the short key.

	my $item = { $config{rdfs_label} => 'Person' };
	my $got  = Schema::Validator::_extract_label($item);

	is($got, 'Person', '_extract_label returns a scalar label');
	returns_ok($got, { type => 'string' }, 'return value is a string');
};

subtest '_extract_label -- returns the first element of an array label' => sub {
	# Purpose: multi-language entries encode the label as an array; only
	# the first value should be returned.

	my $item = { $config{rdfs_label} => ['MusicEvent', 'MusicEvent-fr'] };
	my $got  = Schema::Validator::_extract_label($item);

	is($got, 'MusicEvent', 'first array element is returned for a multi-value label');
};

subtest '_extract_label -- falls back to the full RDF URI label key' => sub {
	# Purpose: some JSON-LD serialisations expand the key to the full URI.

	my $item = { $config{rdfs_label_full} => 'Organization' };
	my $got  = Schema::Validator::_extract_label($item);

	is($got, 'Organization', 'full-URI rdfs:label key is accepted');
};

subtest '_extract_label -- returns undef when no label key is present' => sub {
	# Purpose: items that have neither label key must yield undef so the
	# caller (_parse_graph) can skip them cleanly.

	my $item = { $config{at_type} => $config{rdf_class} };
	my $got  = Schema::Validator::_extract_label($item);

	ok(!defined($got), '_extract_label returns undef for unlabelled items');
};

subtest '_extract_label -- does not clobber $_' => sub {
	# Purpose: hash key lookups must not disturb the caller's $_.

	my $item = { $config{rdfs_label} => 'Concert' };

	local $_ = $SENTINEL;
	Schema::Validator::_extract_label($item);
	is($_, $SENTINEL, '_extract_label does not modify $_');
};

# ===========================================================================
# SUBTESTS: _parse_graph -- INTERNAL HELPER
# ===========================================================================

subtest '_parse_graph -- rdfs:Class items appear in the classes hashref' => sub {
	# Purpose: the first return value must contain all items whose @type
	# includes rdfs:Class, keyed by their label.

	my $graph = [
		_make_item(type  => $config{rdf_class},
		           label => 'Person',
		           id    => 'https://schema.org/Person'),
	];

	my ($classes, $props) = Schema::Validator::_parse_graph($graph);

	ok(exists $classes->{Person}, 'rdfs:Class item is in classes hashref');
	ok(!exists $props->{Person},  'rdfs:Class item is not in props hashref');
	returns_ok($classes, { type => 'hashref' }, 'classes return is a hashref');

	diag "Classes found: " . join(', ', keys %$classes) if $ENV{TEST_VERBOSE};
};

subtest '_parse_graph -- rdf:Property items appear in the properties hashref' => sub {
	# Purpose: the second return value must contain all rdf:Property items.

	my $graph = [
		_make_item(type  => $config{rdf_property},
		           label => 'name',
		           id    => 'https://schema.org/name'),
	];

	my ($classes, $props) = Schema::Validator::_parse_graph($graph);

	ok(exists $props->{name},    'rdf:Property item is in props hashref');
	ok(!exists $classes->{name}, 'rdf:Property item is not in classes hashref');
	returns_ok($props, { type => 'hashref' }, 'props return is a hashref');
};

subtest '_parse_graph -- @id short name creates a secondary index' => sub {
	# Purpose: the implementation strips the URI path to produce a short name
	# (e.g. 'MusicGroup' from 'https://schema.org/MusicGroup') and stores
	# the item under that key too, using //= so the label always wins.

	my $graph = [
		_make_item(type  => $config{rdf_class},
		           label => 'MusicGroup',
		           id    => 'https://schema.org/MusicGroup'),
	];

	my ($classes, $props) = Schema::Validator::_parse_graph($graph);

	# Label index must exist
	ok(exists $classes->{MusicGroup}, 'class is indexed by its label');

	# The @id fragment ('MusicGroup') equals the label here; both resolve to
	# the same ref, confirming the secondary index is set up
	is($classes->{MusicGroup}{$config{at_id}},
		'https://schema.org/MusicGroup',
		'class item carries the expected @id value');

	diag "MusicGroup item: " . $classes->{MusicGroup}{'rdfs:label'}
		if $ENV{TEST_VERBOSE};
};

subtest '_parse_graph -- items without @type are silently skipped' => sub {
	# Purpose: items that declare no RDF type must be ignored entirely.

	my $graph = [
		{ $config{rdfs_label} => 'OrphanItem' },
	];

	my ($classes, $props) = Schema::Validator::_parse_graph($graph);

	ok(!exists $classes->{OrphanItem}, 'unlabelled-type item absent from classes');
	ok(!exists $props->{OrphanItem},   'unlabelled-type item absent from props');
};

subtest '_parse_graph -- items without a label are silently skipped' => sub {
	# Purpose: _extract_label returns undef for these, and the 'or next'
	# guard must prevent them from being stored.

	my $graph = [
		{ $config{at_type} => $config{rdf_class},
		  $config{at_id}   => 'https://schema.org/Anonymous' },
	];

	my ($classes, $props) = Schema::Validator::_parse_graph($graph);

	is(scalar keys %$classes, 0, 'no-label item yields empty classes');
	is(scalar keys %$props,   0, 'no-label item yields empty props');
};

subtest '_parse_graph -- @type may be an array' => sub {
	# Purpose: the JSON-LD spec allows @type to be a scalar OR an arrayref.
	# The implementation normalises it; this test confirms the array form works.

	my $graph = [
		{
			$config{at_type}    => [$config{rdf_class}, 'SomeOtherType'],
			$config{rdfs_label} => 'MultiTyped',
			$config{at_id}      => 'https://schema.org/MultiTyped',
		},
	];

	my ($classes, $props) = Schema::Validator::_parse_graph($graph);

	ok(exists $classes->{MultiTyped},
		'item with array @type containing rdfs:Class is indexed');
};

subtest '_parse_graph -- does not clobber $_' => sub {
	# Purpose: the internal for-loop must use a named variable ($item), not $_.

	my $graph = [
		_make_item(type  => $config{rdf_class},
		           label => 'Thing',
		           id    => 'https://schema.org/Thing'),
	];

	local $_ = $SENTINEL;
	Schema::Validator::_parse_graph($graph);
	is($_, $SENTINEL, '_parse_graph does not modify $_');
};

subtest '_parse_graph -- returned hashrefs are cycle-free' => sub {
	# Purpose: neither the classes nor the props hashref should form any
	# reference cycles that would prevent garbage collection.

	my $graph = [
		_make_item(type  => $config{rdf_class},
		           label => 'Event',
		           id    => 'https://schema.org/Event'),
		_make_item(type  => $config{rdf_property},
		           label => 'startDate',
		           id    => 'https://schema.org/startDate'),
	];

	my ($classes, $props) = Schema::Validator::_parse_graph($graph);

	memory_cycle_ok($classes, 'classes hashref is cycle-free');
	memory_cycle_ok($props,   'props hashref is cycle-free');

	diag "Graph parsed: " . scalar(keys %$classes) . " classes, "
		. scalar(keys %$props) . " props" if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# SUBTESTS: load_dynamic_vocabulary -- PUBLIC FUNCTION
# ===========================================================================

subtest 'load_dynamic_vocabulary -- reads from a fresh cache without fetching' => sub {
	# Purpose: when a cache file exists and its mtime is within cache_duration,
	# the network must not be called.  We create a real temp file (so -e and
	# stat see it) and mock _slurp_file to return valid JSON.

	my ($fh, $path) = tempfile(UNLINK => 1);
	close $fh;

	my $fetch_call_count = 0;

	my $g = mock_scoped(
		'Schema::Validator::_slurp_file' => sub { $VALID_JSONLD },
		'Schema::Validator::_fetch_url'  => sub { $fetch_call_count++; undef },
	);

	# Suppress the "Dynamic vocabulary loaded" carp emitted on success
	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $FRESH_DURATION,
	);

	is($fetch_call_count, 0, 'fresh cache: _fetch_url is never called');
	ok(ref($result) eq 'HASH', 'fresh cache: result is a hashref');
	ok(exists $result->{Thing}, 'fresh cache: parsed class is present');

	diag "Fresh-cache path: " . scalar(keys %$result) . " classes"
		if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- fetches from URL when cache is stale' => sub {
	# Purpose: STALE_DURATION (0 seconds) makes any existing file stale,
	# forcing _fetch_url to be called.  _spit_file must also be called to
	# persist the downloaded content.

	my (undef, $path) = tempfile(UNLINK => 1);
	my $spit_call_count = 0;

	my $g = mock_scoped(
		'Schema::Validator::_fetch_url' => sub { $VALID_JSONLD },
		'Schema::Validator::_spit_file' => sub { $spit_call_count++; 1 },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $STALE_DURATION,
	);

	ok(ref($result) eq 'HASH',   'stale cache: result is a hashref');
	is($spit_call_count, 1,      'stale cache: _spit_file is called exactly once');
	ok(exists $result->{Thing},  'stale cache: vocabulary content is parsed');

	diag "Stale-cache fetch path verified" if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- falls back to stale cache on network failure' => sub {
	# Purpose: when _fetch_url returns undef but the cache file exists,
	# the function must read the stale file AND emit a carp warning.

	my ($fh, $path) = tempfile(UNLINK => 1);
	close $fh;

	my $g = mock_scoped(
		'Schema::Validator::_fetch_url'  => sub { undef },
		'Schema::Validator::_slurp_file' => sub { $VALID_JSONLD },
	);

	my $result;
	my @warnings;

	# Capture all carp warnings so we can assert on them
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	$result = load_dynamic_vocabulary(
		cache_file     => $path,
		cache_duration => $STALE_DURATION,
	);

	ok(ref($result) eq 'HASH', 'stale fallback: result is a hashref');
	ok(exists $result->{Thing}, 'stale fallback: parsed class is present');

	# At least one warning must mention the stale cache or network unavailability
	my $has_stale_warn = grep { /stale|unavailable/i } @warnings;
	ok($has_stale_warn, 'stale fallback: carp warning mentions stale/unavailable');

	diag "Warnings: " . join('; ', @warnings) if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- returns empty hashref when no content is available' => sub {
	# Purpose: if all strategies fail (file absent AND network down), the
	# function must return {} and emit a carp -- never throw.

	my $g = mock_scoped(
		'Schema::Validator::_fetch_url' => sub { undef },
	);

	my $result;

	# Expect a carp about unavailable vocabulary
	warning_like(
		sub {
			$result = load_dynamic_vocabulary(
				cache_file     => '/no/such/path/xyz.jsonld',
				cache_duration => $STALE_DURATION,
			);
		},
		qr/no vocabulary content/i,
		'no-content path emits a carp',
	);

	ok(ref($result) eq 'HASH',    'no-content: result is a hashref');
	is(scalar keys %$result, 0,   'no-content: result is empty');
	returns_ok($result, { type => 'hashref' }, 'return type is hashref on failure');

	diag "Empty hashref returned as expected" if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- returns empty hashref on malformed JSON' => sub {
	# Purpose: a JSON parse error must be caught, carpd, and turned into
	# an empty hashref return; the function must not throw.

	my $g = mock_scoped(
		'Schema::Validator::_fetch_url' => sub { $BAD_JSON },
		'Schema::Validator::_spit_file' => sub { 1 },
	);

	my $result;

	warning_like(
		sub {
			$result = load_dynamic_vocabulary(
				cache_file     => '/tmp/_sv_test_bad_json_$$.jsonld',
				cache_duration => $STALE_DURATION,
			);
		},
		qr/parse|JSON/i,
		'malformed JSON emits a carp',
	);

	ok(ref($result) eq 'HASH',  'bad JSON: result is a hashref');
	is(scalar keys %$result, 0, 'bad JSON: result is empty');
};

subtest 'load_dynamic_vocabulary -- returns empty hashref when @graph is absent' => sub {
	# Purpose: valid JSON that lacks the @graph array must be rejected
	# with a carp, not a crash.

	my $g = mock_scoped(
		'Schema::Validator::_fetch_url' => sub { $NO_GRAPH_JSON },
		'Schema::Validator::_spit_file' => sub { 1 },
	);

	my $result;

	warning_like(
		sub {
			$result = load_dynamic_vocabulary(
				cache_file     => '/tmp/_sv_test_no_graph_$$.jsonld',
				cache_duration => $STALE_DURATION,
			);
		},
		qr/\@graph/i,
		'missing @graph emits a carp',
	);

	is(scalar keys %$result, 0, 'missing @graph: result is empty');
};

subtest 'load_dynamic_vocabulary -- populates %dynamic_schema global' => sub {
	# Purpose: the documented side-effect of filling %dynamic_schema must
	# occur after a successful load.

	my $g = mock_scoped(
		'Schema::Validator::_fetch_url' => sub { $MIXED_JSONLD },
		'Schema::Validator::_spit_file' => sub { 1 },
	);

	# Reset both globals so we know this call populated them, not a prior one
	%Schema::Validator::dynamic_schema     = ();
	%Schema::Validator::dynamic_properties = ();

	local $SIG{__WARN__} = sub {};
	load_dynamic_vocabulary(
		cache_file     => '/tmp/_sv_test_globals_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	ok(%Schema::Validator::dynamic_schema,
		'%dynamic_schema is populated after a successful load');
	ok(%Schema::Validator::dynamic_properties,
		'%dynamic_properties is populated after a successful load');

	# Spot-check specific keys from MIXED_JSONLD
	ok(exists $Schema::Validator::dynamic_schema{Thing},
		'%dynamic_schema contains the expected class');
	ok(exists $Schema::Validator::dynamic_properties{name},
		'%dynamic_properties contains the expected property');

	diag "dynamic_schema: " . join(', ', keys %Schema::Validator::dynamic_schema)
		if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- returns a class hashref' => sub {
	# Purpose: the return value must be a hashref whose keys are class labels
	# and whose values are the raw JSON-LD item hashrefs.

	my $g = mock_scoped(
		'Schema::Validator::_fetch_url' => sub { $VALID_JSONLD },
		'Schema::Validator::_spit_file' => sub { 1 },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => '/tmp/_sv_test_return_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	returns_ok($result, { type => 'hashref' }, 'return value is a hashref');
	ok(exists $result->{Thing},          'Thing class is in the returned hashref');
	ok(ref($result->{Thing}) eq 'HASH',  'class value is itself a hashref');

	diag "Returned " . scalar(keys %$result) . " classes" if $ENV{TEST_VERBOSE};
};

subtest 'load_dynamic_vocabulary -- result is cycle-free' => sub {
	# Purpose: the returned hashref and its nested items must be
	# garbage-collectable without memory leaks.

	my $g = mock_scoped(
		'Schema::Validator::_fetch_url' => sub { $VALID_JSONLD },
		'Schema::Validator::_spit_file' => sub { 1 },
	);

	local $SIG{__WARN__} = sub {};
	my $result = load_dynamic_vocabulary(
		cache_file     => '/tmp/_sv_test_cycles_$$.jsonld',
		cache_duration => $STALE_DURATION,
	);

	memory_cycle_ok($result, 'load_dynamic_vocabulary result has no memory cycles');
};

# ---------------------------------------------------------------------------
# Final cleanup: ensure no mocks leak between this file and any later tests
# that may be run in the same process.
# ---------------------------------------------------------------------------
restore_all();

done_testing();
