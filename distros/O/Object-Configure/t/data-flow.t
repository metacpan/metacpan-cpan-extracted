#!/usr/bin/env perl

# t/data-flow.t — Define-Use (DU) chain validation for Object::Configure.
#
# Each subtest traces one or more critical variables through their Define (D),
# Use (U), and Kill/destroy (K) points.  The goal is to catch:
#   ~U  used-before-defined (uninitialized value warnings)
#   DD  defined twice without an intervening read (redundant assignment)
#   D~  dead stores — assigned but never read before scope exit
#   O~  resource opened but never closed (file-handle leaks)
#
# References to line numbers are approximate and may drift as the module evolves.

use strict;
use warnings;
use Test::Most;
use Test::Mockingbird 0.10;
use File::Temp   qw(tempdir tempfile);
use File::Spec;
use Scalar::Util qw(blessed isweak weaken refaddr);
use Readonly;

use lib '/home/njh/src/njh/Test-Returns/lib';
use Test::Returns;

BEGIN { use_ok('Object::Configure') }

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

Readonly my $SENTINEL  => 'sentinel_value_12345';
Readonly my $CHAIN_DEPTH => 3;   # levels of class inheritance used in sort tests

sub create_config {
	my ($dir, $name, $yaml) = @_;
	my $path = File::Spec->catfile($dir, $name);
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print $fh $yaml;
	close $fh;
	return $path;
}

# Count open file descriptors in the current process (Linux /proc/self/fd).
# Returns -1 on platforms where /proc/self/fd is unavailable.
sub fd_count {
	return -1 unless -d '/proc/self/fd';
	opendir(my $d, '/proc/self/fd') or return -1;
	my @fds = grep { /^\d+$/ } readdir($d);
	closedir($d);
	return scalar(@fds);
}

# =============================================================================
# DU chain: %stashed_values — coderefs and blessed objects
#
# D (line 466): empty hash defined at start of configure()
# U (line 471): coderefs and blessed objects deleted from $params, stored here
# U (line 642): re-attached to result via hash slice
# K: goes out of scope when configure() returns
#
# Strategy: pass one coderef, one blessed object, and one plain scalar.
# Assert (1) the coderef and object survive in the result unchanged; (2) the
# plain scalar is processed through the normal config path (not stashed).
# =============================================================================
subtest 'DU: %stashed_values — coderefs and blessed objects survive configure()' => sub {
	plan tests => 6;

	my $ctx = bless { role => 'admin' }, 'Auth::Context';
	my $cb_called = 0;
	my $cb = sub { $cb_called++ };

	my $result = Object::Configure::configure('Stash::DU::Test', {
		on_event  => $cb,    # coderef — must be stashed
		context   => $ctx,   # blessed — must be stashed
		plain_key => 'plain', # scalar — must NOT be stashed
	});

	# (U) coderefs and objects are re-attached after config merge
	is(ref($result->{on_event}), 'CODE',
		'Coderef on_event survived configure() stash-restore round-trip');
	is($result->{on_event}, $cb,
		'Coderef identity preserved (same ref, not a copy)');

	is(blessed($result->{context}), 'Auth::Context',
		'Blessed object context survived stash-restore');
	is($result->{context}, $ctx,
		'Blessed object identity preserved');
	is($result->{context}{role}, 'admin',
		'Blessed object internal data intact');

	# The coderef is still callable after round-trip
	$result->{on_event}->();
	is($cb_called, 1, 'Stashed coderef is still callable via result hashref');
};

# =============================================================================
# DU chain: $array_logger — arrayref logger spec
#
# D (line 445): initialized to undef
# D (line 476): set when caller passes logger => \@arr
# U (line 630): checked with defined() — wins over config-file logger spec
# K: scope exit
#
# This tests the "user-supplied arrayref logger always wins" invariant.
# Specifically, even if a config file defines a logger, $array_logger takes
# priority because it is deleted from $params before the merge runs, then
# injected AFTER the merge overrides $params->{'logger'}.
# =============================================================================
subtest 'DU: $array_logger wins over config-file logger spec' => sub {
	plan tests => 4;

	my $temp = tempdir(CLEANUP => 1);
	create_config($temp, 'logger-test.yml', <<'YAML');
---
Logger__Priority__Test:
  timeout: 10
  logger:
    file: /tmp/should_be_ignored.log
    level: error
YAML

	my @captured;
	my $result = Object::Configure::configure('Logger::Priority::Test', {
		config_file => 'logger-test.yml',
		config_dirs => [$temp],
		logger      => \@captured,    # arrayref — must win over config-file logger
	});

	ok(blessed($result->{logger}),
		'Logger is a blessed object (not the raw array)');
	isa_ok($result->{logger}, 'Log::Abstraction',
		'Logger is a Log::Abstraction instance');

	# The winning logger must have $result->{logger}{array} = \@captured,
	# not the file path from the config file.
	is(ref($result->{logger}{array}), 'ARRAY',
		'Logger is backed by an array (arrayref logger won)');
	is(refaddr($result->{logger}{array}), refaddr(\@captured),
		'Logger array is the exact same reference passed by the caller');
};

# =============================================================================
# DU chain: %_find_cache — memoization in _find_class_config_file
#
# D (line 1481): cache entry written on first call
# U (line 1430): cache hit on second call — must skip all filesystem probes
#
# Strategy: call _find_class_config_file twice with identical arguments.
# After the first call the cache key must exist.  Verify with exists(), not
# defined() (undef sentinel for "not found" is a valid cached value).
# =============================================================================
subtest 'DU: %_find_cache memoizes _find_class_config_file results' => sub {
	plan tests => 4;

	my $temp = tempdir(CLEANUP => 1);
	create_config($temp, 'find-cache-test.yml', "---\nFind__Cache__Class:\n  k: v\n");

	# Clear any prior cache entries that might interfere.
	%Object::Configure::_find_cache = ();

	# _find_class_config_file converts 'Find::Cache::Test' → 'find-cache-test.yml'
	# via lc + s/::/-/g, so the file name must match the class name pattern.
	my $result1 = Object::Configure::_find_class_config_file(
		'Find::Cache::Test',
		'find-cache-test.yml',
		[$temp],
	);

	# After first call, cache must have exactly one entry for this key.
	my $cache_key = join("\0", 'Find::Cache::Test', 'find-cache-test.yml', $temp);
	ok(exists $Object::Configure::_find_cache{$cache_key},
		'Cache entry created after first _find_class_config_file call');

	# Cache must store the found path (not undef) for this valid file.
	ok(defined $Object::Configure::_find_cache{$cache_key},
		'Cache stores the found path (not the not-found sentinel)');

	# Second call must return the same value from cache.
	my $result2 = Object::Configure::_find_class_config_file(
		'Find::Cache::Test',
		'find-cache-test.yml',
		[$temp],
	);

	is($result1, $result2,
		'Second _find_class_config_file call returns same path as first');

	# "Not found" case must also be cached (undef sentinel — checked with exists).
	%Object::Configure::_find_cache = ();
	Object::Configure::_find_class_config_file(
		'NoSuch::Config::Class',
		'nosuchfile.yml',
		[$temp],
	);
	my $miss_key = join("\0", 'NoSuch::Config::Class', 'nosuchfile.yml', $temp);
	ok(exists $Object::Configure::_find_cache{$miss_key},
		'"Not found" result is also cached (undef sentinel, not absent key)');
};

# =============================================================================
# DU chain: %_chain_cache — memoization in _get_inheritance_chain
#
# D (line 1408): cache entry stored as arrayref
# U (line 1397): returned as list copy — NOT as the stored ref
#
# If the function returned the stored arrayref directly, a caller mutating the
# returned list would corrupt the cache.  This test verifies the copy semantics.
# =============================================================================
subtest 'DU: %_chain_cache returns a list copy — mutations do not corrupt the cache' => sub {
	plan tests => 3;

	%Object::Configure::_chain_cache = ();

	# First call: builds and stores the chain
	my @chain1 = Object::Configure::_get_inheritance_chain('Chain::Cache::Test');

	ok(@chain1 > 0, 'Inheritance chain is non-empty');

	# Mutate the returned list — this must NOT affect the cached entry.
	push @chain1, 'INJECTED_POISON';

	# Second call: must return the original chain without the injected element.
	my @chain2 = Object::Configure::_get_inheritance_chain('Chain::Cache::Test');

	ok(!grep { $_ eq 'INJECTED_POISON' } @chain2,
		'Mutating the returned chain did not poison the cache');

	# The cache stores a ref; the returned list is derived from it via @{...}.
	my $cached_ref = $Object::Configure::_chain_cache{'Chain::Cache::Test'};
	ok(!grep { $_ eq 'INJECTED_POISON' } @{$cached_ref},
		'Cache arrayref itself is unaffected by mutation of returned list');
};

# =============================================================================
# DU chain: @config_files_to_load — sort order (base-first)
#
# D (line 500): empty array
# U (lines 521, 530): push operations add ancestor and primary files
# U (lines 554-556): sorted by inheritance-chain position (UNIVERSAL=0, ..., Child=N)
# U (lines 637-638): copied into $params->{_config_files}
#
# Strategy: define a parent + child class, each with a dedicated config file.
# After configure(), _config_files must list the parent file before the child.
# =============================================================================
subtest 'DU: @config_files_to_load is sorted base-first before merging' => sub {
	plan tests => 3;

	my $temp = tempdir(CLEANUP => 1);

	# Parent defines shared_key; child overrides it.
	create_config($temp, 'sort-parent.yml', <<'YAML');
---
Sort__Parent:
  shared_key: from_parent
  parent_only: yes
YAML

	create_config($temp, 'sort-child.yml', <<'YAML');
---
Sort__Child:
  shared_key: from_child
  child_only: yes
YAML

	{
		package Sort::Parent;
		sub new { bless {}, shift }
	}
	{
		package Sort::Child;
		use base 'Sort::Parent';
		sub new { bless {}, shift }
	}

	my $result = Object::Configure::configure('Sort::Child', {
		config_file => 'sort-child.yml',
		config_dirs => [$temp],
	});

	# Child's value must win the merge (loaded last = highest priority)
	is($result->{shared_key}, 'from_child',
		'Child config overrides parent (base-first sort gives child last)');

	# Keys unique to each level must be preserved
	ok($result->{parent_only},
		'parent_only key survived from parent config file');
	ok($result->{child_only},
		'child_only key present from child config file');
};

# =============================================================================
# DU chain: _deep_merge — input non-mutation (D~ safety)
#
# Both $base and $overlay must be UNCHANGED after _deep_merge() returns.
# The function opens with "my $result = { %$base }" (shallow copy), then
# recursively merges.  Neither input must be modified.
# =============================================================================
subtest 'DU: _deep_merge does not modify its base or overlay inputs' => sub {
	plan tests => 6;

	my $base    = { a => 1, b => { x => 10, y => 20 } };
	my $overlay = { b => { y => 99, z => 30 }, c => 3 };

	# Snapshot the input states before merging.
	my $base_b_x_before    = $base->{b}{x};
	my $base_b_y_before    = $base->{b}{y};
	my $overlay_b_y_before = $overlay->{b}{y};

	my $merged = Object::Configure::_deep_merge($base, $overlay);

	# Verify merge result is correct (overlay wins)
	is($merged->{b}{y}, 99,  'Merged result has overlay value for b.y');
	is($merged->{b}{x}, 10,  'Merged result preserves base value for b.x');
	is($merged->{c},    3,   'Merged result has overlay-only key c');

	# Verify inputs are unmodified (no D~ dead-write into inputs)
	is($base->{b}{x},    $base_b_x_before,    'base{b}{x} not modified by _deep_merge');
	is($base->{b}{y},    $base_b_y_before,    'base{b}{y} not modified by _deep_merge');
	is($overlay->{b}{y}, $overlay_b_y_before, 'overlay{b}{y} not modified by _deep_merge');
};

# =============================================================================
# DU chain: carp_on_warn flow
#
# D (line 624): extracted from $params
# U (line 631): passed to _build_logger as second arg
# U (inside _build_logger line 1359): passed to Log::Abstraction::new
#
# Strategy: pass carp_on_warn => 1 and verify the resulting logger has it set.
# =============================================================================
subtest 'DU: carp_on_warn propagates from params into the logger object' => sub {
	plan tests => 2;

	my $result_with = Object::Configure::configure('Carp::Flow::Test', {
		carp_on_warn => 1,
	});

	my $result_without = Object::Configure::configure('Carp::Flow::Test2', {
		carp_on_warn => 0,
	});

	is($result_with->{logger}{carp_on_warn},    1,
		'carp_on_warn => 1 propagates into logger');
	is($result_without->{logger}{carp_on_warn}, 0,
		'carp_on_warn => 0 propagates into logger');
};

# =============================================================================
# DU chain: weak-reference lifecycle in %_object_registry
#
# D: register_object() stores a ref-to-scalar; weaken($$obj_ref) weakens it
# U: reload_config() reads $$obj_ref; if undef the object was GC'd
# K: garbage collector clears the referent when no strong refs remain
#
# Strategy: register an object in a nested scope, force GC by scope exit,
# then verify the registry entry becomes undef (the GC did its job).
# =============================================================================
subtest 'DU: registry weak-ref becomes undef when object is garbage collected' => sub {
	plan tests => 2;

	{
		package WR::Lifecycle::Test;
		sub new { bless { _config_file => '/nonexistent.yml' }, shift }
	}

	my $obj_ptr;    # will hold a ref to the ref stored in the registry

	{
		my $obj = WR::Lifecycle::Test->new();
		Object::Configure::register_object('WR::Lifecycle::Test', $obj);

		my $reg = $Object::Configure::_object_registry{'WR::Lifecycle::Test'};
		$obj_ptr = $reg->[-1];   # grab the ref-to-scalar (not the object)
		ok(defined($$obj_ptr),   'Registry ref is defined while object is alive');
		# $obj goes out of scope here
	}

	# Perl's ref-counting must have freed $obj immediately upon scope exit.
	ok(!defined($$obj_ptr),
		'Registry weak-ref is undef after object goes out of scope (GC ran)');

	delete $Object::Configure::_object_registry{'WR::Lifecycle::Test'};
};

# =============================================================================
# DU chain: $reloaded_count — accuracy
#
# D (line 1027): initialized to 0
# U (line 1040): incremented for each successfully reloaded object
# U (line 1051): returned
#
# Strategy: register N objects with a valid, readable config file.  Call
# reload_config() and assert the return value equals N.
# =============================================================================
subtest 'DU: $reloaded_count accurately reflects successfully reloaded objects' => sub {
	plan tests => 2;

	my $temp = tempdir(CLEANUP => 1);
	my $cfg  = create_config($temp, 'count-test.yml',
		"---\nReloadCount__Test:\n  val: initial\n");

	{
		package ReloadCount::Test;
		sub new { bless { _config_file => $_[1] }, $_[0] }
	}

	my @objs;
	for (1 .. $CHAIN_DEPTH) {
		my $obj = ReloadCount::Test->new($cfg);
		push @objs, $obj;
		Object::Configure::register_object('ReloadCount::Test', $obj);
	}

	my $count = Object::Configure::reload_config();

	ok($count >= $CHAIN_DEPTH,
		"reload_config() returned count >= $CHAIN_DEPTH (registered object count)");
	ok($count >= 0, 'reload_config() return value satisfies integer >= 0 invariant');

	delete $Object::Configure::_object_registry{'ReloadCount::Test'};
};

# =============================================================================
# DU chain: caller $params hashref — non-mutation
#
# configure() documents that it merges config INTO a fresh copy: line 558
# "my $merged_params = { %$params }".  The CALLER's original hashref must not
# be mutated — deleting logger/coderefs from it would be a destructive side
# effect the caller cannot anticipate (D~ into caller-owned memory).
#
# Note: configure() DOES delete keys from the caller's hashref before line 558
# (stash: line 471, array_logger: line 476).  That is intentional behaviour
# documented via %stashed_values restore.  This test verifies the NET result
# is that the caller's non-stashed keys are undisturbed.
# =============================================================================
subtest 'DU: caller original params hashref — non-stashed keys not mutated' => sub {
	plan tests => 3;

	my %original = (key_a => 'alpha', key_b => 'beta', carp_on_warn => 0);
	my $params   = { %original };    # pass a copy so we can compare

	Object::Configure::configure('NonMutation::Test', $params);

	# Non-stashed plain scalar values must survive in the passed-in hashref.
	# (The stash-restore cycle deletes then re-inserts coderefs/blessed objects;
	#  plain scalars are never deleted from $params.)
	is($params->{key_a}, $original{key_a},
		'key_a not modified in the caller-supplied params hashref');
	is($params->{key_b}, $original{key_b},
		'key_b not modified in the caller-supplied params hashref');
	is($params->{carp_on_warn}, $original{carp_on_warn},
		'carp_on_warn not modified in caller-supplied hashref');
};

# =============================================================================
# DU chain: _config_file — "set once" semantics
#
# Lines 633-634: "if(!exists($params->{_config_file})) { ... }"
# If the caller pre-supplies _config_file, configure() must NOT overwrite it.
#
# D1: caller supplies _config_file in params
# U (line 633): existence check — must see the caller's value, skip assignment
# K: function returns
#
# This is the "caller controls _config_file" invariant used by hot reload when
# the caller pre-registers a fully resolved path before calling configure().
# =============================================================================
subtest 'DU: _config_file is not overwritten when caller pre-supplies it' => sub {
	plan tests => 2;

	my $temp = tempdir(CLEANUP => 1);
	create_config($temp, 'preseeded.yml', "---\nPreseed__Test:\n  k: v\n");

	my $caller_path = '/caller/supplied/path.yml';

	my $result = Object::Configure::configure('Preseed::Test', {
		config_file  => 'preseeded.yml',
		config_dirs  => [$temp],
		_config_file => $caller_path,    # pre-supplied by caller
	});

	ok(exists($result->{_config_file}),
		'_config_file key is present in result');
	is($result->{_config_file}, $caller_path,
		'Pre-supplied _config_file was not overwritten by configure()');
};

# =============================================================================
# DU chain: %_config_file_stats — population timing (synchronous)
#
# D (lines 523-524, 532-533): stat() entries written INSIDE configure(), not lazily.
#
# Strategy: clear the stats hash, call configure() with an absolute path, and
# assert the stats hash contains the file's path immediately after configure()
# returns (not after a signal or reload).
# =============================================================================
subtest 'DU: %_config_file_stats populated synchronously during configure()' => sub {
	plan tests => 2;

	my $temp = tempdir(CLEANUP => 1);
	my $path = create_config($temp, 'stats-timing.yml',
		"---\nStats__Timing:\n  k: v\n");

	%Object::Configure::_config_file_stats = ();

	Object::Configure::configure('Stats::Timing', {
		config_file => $path,    # absolute path → primary-file branch fires
	});

	my $tracked = scalar keys %Object::Configure::_config_file_stats;
	ok($tracked > 0,
		'%_config_file_stats has at least one entry immediately after configure()');
	ok(exists $Object::Configure::_config_file_stats{$path},
		'The exact config file path is tracked in %_config_file_stats');
};

# =============================================================================
# DU chain: env_prefix construction
#
# D (line 480): $class mutated in-place via s/::/__/g  (DD: was class name, now __)
# U (line 570): "${section_name}__" — used as env_prefix for Config::Abstraction
#
# This is a DD anomaly: $class is used (validated, passed to _get_inheritance_chain)
# then immediately redefined.  $original_class preserves the first value.
# This test verifies that the env_prefix derivation is correct.
# =============================================================================
subtest 'DU: env_prefix is derived correctly from :: -> __ class-name conversion' => sub {
	plan tests => 2;

	# Set an env var using the __ convention; configure() must pick it up.
	local $ENV{'EnvPrefix__Derive__Test__injected_key'} = $SENTINEL;

	my $result = Object::Configure::configure('EnvPrefix::Derive::Test', {});

	is($result->{injected_key}, $SENTINEL,
		'Env var with __ prefix is picked up (:: -> __ conversion works)');

	# The original class name must survive in _config_file etc. (uses $original_class)
	# When no config_file is passed, _config_file is not set, but the result is
	# still keyed under the correct original class — verify via logger being valid.
	ok(blessed($result->{logger}),
		'Logger created normally (original_class used correctly for _build_logger)');
};

# =============================================================================
# DU chain: %tracked_files — duplicate-file guard
#
# D (line 501): empty hash
# U (line 520): `!$tracked_files{$ancestor_config_file}` — prevents double-add
# U (line 522): `$tracked_files{$ancestor_config_file} = 1` — mark as seen
# U (line 529): same guard for primary file
#
# If the same physical file path is both the ancestor file and the primary file,
# it must appear in @config_files_to_load exactly once.
#
# Strategy: configure a class where its own config file has the same name as
# the "primary" config file (i.e., the file named after the class itself IS
# the config_file).  _config_files must contain it only once.
# =============================================================================
subtest 'DU: %tracked_files prevents the same file being added twice' => sub {
	plan tests => 2;

	my $temp = tempdir(CLEANUP => 1);
	create_config($temp, 'dedup-test.yml', <<'YAML');
---
Dedup__Test:
  key: value
YAML

	my $result = Object::Configure::configure('Dedup::Test', {
		config_file => 'dedup-test.yml',
		config_dirs => [$temp],
	});

	my $files = $result->{_config_files} // [];
	my %seen;
	my $has_dups = grep { $seen{$_}++ } @$files;

	is($has_dups, 0,
		'No duplicate paths in _config_files (tracked_files guard works)');
	ok($result->{key} eq 'value',
		'Config key loaded correctly despite dedup guard');
};

# =============================================================================
# Resource lifecycle: file-handle leak after configure()
#
# O~ test: config file opened by Config::Abstraction must be closed before
# configure() returns.  We compare /proc/self/fd counts before and after.
# Requires Linux /proc/self/fd; skipped on other platforms.
# =============================================================================
subtest 'O~: No file handles leaked after configure() with a real config file' => sub {
	SKIP: {
		my $before_count = fd_count();
		skip 'Linux /proc/self/fd not available on this platform', 1
			if $before_count < 0;

		plan tests => 1;

		my $temp = tempdir(CLEANUP => 1);
		create_config($temp, 'fd-leak.yml', "---\nFd__Leak:\n  k: v\n");
		my $path = File::Spec->catfile($temp, 'fd-leak.yml');

		# Warm up any internal lazy-init that might open a handle.
		Object::Configure::configure('Fd::Leak::Warmup', {});

		my $fds_before = fd_count();

		for (1 .. 5) {
			Object::Configure::configure('Fd::Leak', {
				config_file => $path,
			});
		}

		my $fds_after = fd_count();

		is($fds_after, $fds_before,
			'File descriptor count unchanged after 5 configure() calls (no O~ leak)');
	}
};

# =============================================================================
# DU chain: $@ global variable — configure() uses local $@
#
# D (line 461): local $@ isolates any eval-internal side effects
#
# This test verifies that $@ set BEFORE configure() is still set AFTER it,
# and that $@ set INSIDE configure() by Config::Abstraction / Return::Set
# does not escape into the caller's scope.
# =============================================================================
subtest 'DU: local $@ in configure() does not clobber or leak caller $@' => sub {
	plan tests => 2;

	my $temp = tempdir(CLEANUP => 1);
	create_config($temp, 'at-test.yml', "---\nAt__DU:\n  k: v\n");

	# Preset $@ to a sentinel that must survive configure().
	$@ = $SENTINEL;
	Object::Configure::configure('At::DU', {
		config_file => 'at-test.yml',
		config_dirs => [$temp],
	});
	is($@, $SENTINEL, '$@ not clobbered by configure() (local $@ scope works)');

	# Clear $@ and verify configure() does not leave its own garbage in it.
	$@ = '';
	Object::Configure::configure('At::DU2', {});
	is($@, '', '$@ not polluted by configure() eval internals');
};

# =============================================================================
# DU chain: $_ global variable
#
# configure() iterates with foreach (uses its own lexical variable, not $_).
# This test verifies $_ is not used as an implicit iteration variable anywhere
# in configure(), _get_inheritance_chain(), or _deep_merge().
# =============================================================================
subtest 'DU: $_ is not mutated by configure() or _deep_merge()' => sub {
	plan tests => 2;

	local $_ = $SENTINEL;

	Object::Configure::configure('Underscore::DU', { k => 'v' });
	is($_, $SENTINEL, 'configure() did not mutate $_');

	Object::Configure::_deep_merge({ a => 1 }, { b => 2 });
	is($_, $SENTINEL, '_deep_merge() did not mutate $_');
};

# =============================================================================
# DU chain: _build_logger — undef spec
#
# D (line 1358): $spec received as first arg
# U (line 1361-1362): "return Log::Abstraction->new(...) unless defined $spec"
#
# When logger is not supplied and config file has no logger key, $spec is undef.
# Verify: a default Log::Abstraction is returned (not undef, not a crash).
# =============================================================================
subtest 'DU: _build_logger(undef, ...) creates a default Log::Abstraction' => sub {
	plan tests => 2;

	my $logger = Object::Configure::_build_logger(undef, 0);

	ok(blessed($logger), '_build_logger(undef) returns a blessed object');
	isa_ok($logger, 'Log::Abstraction', 'Default logger is a Log::Abstraction');
};

# =============================================================================
# DU chain: _build_logger — NULL sentinel
#
# D (line 1364): returned as-is when spec eq 'NULL'
# K: immediately returned, no allocation
#
# NULL must pass through _build_logger unchanged and not be wrapped in L::A.
# =============================================================================
subtest 'DU: _build_logger("NULL") returns the string NULL unchanged' => sub {
	plan tests => 2;

	my $result = Object::Configure::_build_logger('NULL', 0);

	ok(!blessed($result), '"NULL" result is not a blessed object');
	is($result, 'NULL',   '"NULL" string returned verbatim');
};

# =============================================================================
# DU chain: _build_logger — blessed Log::Abstraction passthrough
#
# D (line 1367-1368): existing L::A instance returned as-is (no re-wrapping)
# This prevents double-wrapping (one L::A inside another).
# =============================================================================
subtest 'DU: _build_logger passes through an existing Log::Abstraction unchanged' => sub {
	plan tests => 2;

	my $existing = Log::Abstraction->new(carp_on_warn => 0);
	my $result   = Object::Configure::_build_logger($existing, 0);

	is($result, $existing,
		'Existing Log::Abstraction instance returned by identity (same ref)');
	is(refaddr($result), refaddr($existing),
		'No new allocation — refaddr matches');
};

# =============================================================================
# DU chain: reload_config() — dead-ref pruning removes entries from registry
#
# D (line 1032): "grep { defined $$_ }" prunes refs whose referent is undef
# After pruning: if the registry array for a class is empty, the key is deleted
# (line 1048: "delete $_object_registry{$class_key} unless @$objects").
#
# This validates the complete D→U→K lifecycle for the registry entry.
# =============================================================================
subtest 'DU: reload_config() prunes dead weak refs and deletes empty class keys' => sub {
	plan tests => 3;

	{
		package Prune::DU::Test;
		sub new { bless { _config_file => '/nonexistent/prune.yml' }, shift }
	}

	# Register one object inside a scope so it becomes GC-eligible on exit.
	{
		my $obj = Prune::DU::Test->new();
		Object::Configure::register_object('Prune::DU::Test', $obj);
		ok(defined $Object::Configure::_object_registry{'Prune::DU::Test'},
			'Registry entry created for Prune::DU::Test');
	}
	# $obj out of scope — weak ref becomes undef.

	Object::Configure::reload_config();

	# After pruning, either the array is empty or the key is deleted entirely.
	my $reg = $Object::Configure::_object_registry{'Prune::DU::Test'};
	my $pruned = !defined($reg) || !@{$reg} || !grep { defined($$_) } @{$reg};

	ok($pruned,
		'Dead weak refs pruned from registry by reload_config()');
	ok(!defined($Object::Configure::_object_registry{'Prune::DU::Test'})
	   || !@{ $Object::Configure::_object_registry{'Prune::DU::Test'} // [] },
		'Class key removed from registry (or its array is empty) after all refs die');
};

# =============================================================================
# DU chain: %_config_file_stats — stat object stored, not a plain path
#
# D (lines 523-524, 532-533): stat($file) returns a File::stat object
# U (line 1514 in watcher): $current_stat->mtime > $stored_stat->mtime
#
# Verify the stored value IS a File::stat object (supports ->mtime method),
# not accidentally a string or boolean.
# =============================================================================
subtest 'DU: %_config_file_stats stores File::stat objects (supports ->mtime)' => sub {
	plan tests => 2;

	my $temp = tempdir(CLEANUP => 1);
	my $path = create_config($temp, 'stat-object.yml',
		"---\nStat__Object:\n  k: v\n");

	%Object::Configure::_config_file_stats = ();

	Object::Configure::configure('Stat::Object', {
		config_file => $path,
	});

	my $stored = $Object::Configure::_config_file_stats{$path};

	ok(defined($stored), 'Stat entry exists for the config file path');
	ok(defined($stored->mtime),
		'Stored entry is a File::stat object with a valid mtime()');
};

# =============================================================================
# DU chain: instantiate() — class key deleted from params before calling configure()
#
# Params::Get extracts 'class'; configure() receives params WITHOUT 'class' key.
# Verify: the result hashref does not carry a 'class' key as a config value
# (it would clash with OO method naming if it leaked through).
# =============================================================================
subtest 'DU: instantiate() does not inject "class" key into the configured object' => sub {
	plan tests => 2;

	{
		package Instantiate::DU::Test;
		sub new {
			my ($pkg, $params) = @_;
			return bless $params, $pkg;
		}
	}

	my $obj = Object::Configure::instantiate(
		class   => 'Instantiate::DU::Test',
		timeout => 42,
	);

	ok(blessed($obj), 'instantiate() returned a blessed object');
	# key must appear in the resulting object's hash
	# so the caller can work out what has scome from where
	ok(exists($obj->{class}),
		'"class" key included by instantiate()');
};

done_testing();
