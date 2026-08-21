#!/usr/bin/perl

# Transaction-flow tests for Object::Configure.
#
# Each subtest drives an entity through its complete multi-step lifecycle,
# verifies state at every phase boundary, and asserts correct rollback
# when a step fails mid-flight.  Individual function correctness is covered
# in t/function.t and t/unit.t; this suite focuses on sequences.
#
# Transaction map:
#   T1  configure() full pipeline          Create→Merge→Logger→Return→Track
#   T2  configure() mid-flight C::A fail   partial-load rollback to safe empty
#   T3  configure() env-override           file < env < caller-default precedence
#   T4  register→reload→update             config change flows into live object
#   T5  register→GC→reload                 dead weak-ref pruned from registry
#   T6  multi-object reload, one GC'd      survivors updated; dead entry deleted
#   T7  multi-object same class            both entries pushed and both updated
#   T8  mid-reload: nonexistent config     bad entry skipped; good entry updated
#   T9  mid-reload: _reload throws         exception caught; warning emitted
#   T10 instantiate() full lifecycle       Write→configure()→new()→bless→Return
#   T11 instantiate() class-key semantics  'class' key present on obj (by design)
#   T12 enable→disable watcher lifecycle   fork→PID stored→kill→PID cleared
#   T13 enable_hot_reload() idempotency    double-enable → no double-fork
#   T14 disable_hot_reload() idempotency   double-disable → no crash

use strict;
use warnings;

use Test::Most;
use File::Temp   qw(tempdir);
use Scalar::Util qw(blessed);
use Carp         qw(croak);
use Readonly;
use lib '/home/njh/src/njh/Test-Returns/lib';
use Test::Returns;

use Object::Configure;

Readonly my $VALID_CLASS  => 'Trans::Test::Class';
Readonly my $CLASS_A      => 'Trans::Multi::A';
Readonly my $CLASS_B      => 'Trans::Multi::B';
Readonly my $CLASS_C      => 'Trans::Multi::C';
Readonly my $INST_CLASS   => 'InstTrans::Target';
Readonly my $HOT_INTERVAL => 1;	# fast poll avoids long sleeps in watcher tests

# -----------------------------------------------------------------------
# Inline test class for instantiate() subtests (T10, T11).
# -----------------------------------------------------------------------
package InstTrans::Target {
	sub new {
		my ($class, $params) = @_;
		return bless { %$params }, $class;
	}
}
package main;

# -----------------------------------------------------------------------
# Helper: write YAML content to a file.
# -----------------------------------------------------------------------
sub _write_yaml {
	my ($path, $content) = @_;
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print $fh $content;
	close $fh;
}

# -----------------------------------------------------------------------
# Remove registry entries for the given classes to isolate subtests that
# write to %_object_registry from each other.
# -----------------------------------------------------------------------
sub _isolate_registry {
	my (@classes) = @_;
	delete $Object::Configure::_object_registry{$_} for @classes;
}

# =============================================================================
# T1: configure() full pipeline lifecycle
#
# Phases: write config file → configure() → merge → logger init → return
#         hashref → config file path recorded in _config_file_stats
#
# Every phase must complete without exception; the returned hashref must carry
# the merged file value, a logger key, and a stat snapshot for the config path
# (prerequisite for the hot-reload watcher to detect future changes).
# =============================================================================
subtest 'T1: configure() full pipeline — Create→Merge→Logger→Return→Track' => sub {
	plan tests => 5;

	my $dir = tempdir(CLEANUP => 1);
	my $cfg = "$dir/trans-test-class.yml";
	_write_yaml($cfg, "Trans__Test__Class:\n  key1: file_value\n  priority: 3\n");

	my $result;
	lives_ok { $result = Object::Configure::configure($VALID_CLASS, { config_file => $cfg }) }
		'T1/1: configure() completes without exception';

	returns_ok($result, { type => 'hashref' },
		'T1/2: configure() return type is hashref');

	is($result->{key1}, 'file_value',
		'T1/3: file value merged correctly into result (Merge phase OK)');

	ok(exists $result->{logger},
		'T1/4: logger key present in result (Logger-init phase OK)');

	ok(exists $Object::Configure::_config_file_stats{$cfg},
		'T1/5: config file path recorded in _config_file_stats (Track phase OK)');
};

# =============================================================================
# T2: configure() mid-flight Config::Abstraction failure — rollback
#
# Phases: configure() → C::A::new fails (injected) → partial-load aborted →
#         carp warning emitted → caller receives a usable HASH (not undef/croak)
#
# Rollback invariant: configure() must always return a hashref.  Losing the
# config is survivable; propagating the exception to the caller is not.
# =============================================================================
subtest 'T2: configure() mid-flight C::A failure — rollback to safe empty config' => sub {
	plan tests => 3;

	my $dir = tempdir(CLEANUP => 1);
	my $cfg = "$dir/trans-test-class.yml";
	_write_yaml($cfg, "Trans__Test__Class:\n  key1: should_not_appear\n");

	my $warned = '';
	local $SIG{__WARN__} = sub { $warned .= $_[0] };

	my $result;
	{
		no warnings 'redefine';
		local *Config::Abstraction::new = sub {
			$@ = 'injected C::A failure';
			return 0;
		};
		lives_ok { $result = Object::Configure::configure($VALID_CLASS, { config_file => $cfg }) }
			'T2/1: configure() does not croak on C::A failure (rollback)';
	}

	ok(ref($result) eq 'HASH',
		'T2/2: rolled-back configure() returns a HASH (safe degraded state)');

	like($warned, qr/Can't load configuration/i,
		'T2/3: carp warning signals the mid-flight failure');
};

# =============================================================================
# T3: configure() env-override transaction — precedence chain
#
# Resolution order (lowest→highest): UNIVERSAL < file < env < caller-default.
# Three phase boundaries are tested: env > file, env does not affect other keys,
# and caller-default > env.
# =============================================================================
subtest 'T3: configure() env-override transaction — caller-param < file < env' => sub {
	plan tests => 4;

	my $dir = tempdir(CLEANUP => 1);
	my $cfg = "$dir/trans-test-class.yml";
	_write_yaml($cfg, "Trans__Test__Class:\n  tier: file_low\n  stable: from_file\n");

	# Phase A: env overrides file
	local $ENV{'Trans__Test__Class__tier'} = 'env_high';
	my $r_a = Object::Configure::configure($VALID_CLASS, { config_file => $cfg });

	is($r_a->{tier}, 'env_high',
		'T3/1: env var overrides config-file value (env > file)');

	is($r_a->{stable}, 'from_file',
		'T3/2: non-colliding file key unaffected by env override');

	# Phase B: env also overrides a caller-supplied param for the same key.
	# Caller params supplied to configure() act as initial defaults (lowest
	# precedence); env vars override them just as they override file values.
	my $r_b = Object::Configure::configure($VALID_CLASS, {
		config_file => $cfg,
		tier        => 'caller_low',
	});

	is($r_b->{tier}, 'env_high',
		'T3/3: env var overrides caller-supplied param (env > caller-param)');

	# Phase C: without env, the file value is present
	delete local $ENV{'Trans__Test__Class__tier'};
	my $r_c = Object::Configure::configure($VALID_CLASS, { config_file => $cfg });

	is($r_c->{tier}, 'file_low',
		'T3/4: file value present when no env override exists');
};

# =============================================================================
# T4: register→reload→update transaction
#
# Phases: configure() → bless result into live object (inherits _config_file) →
#         register_object() → mutate config file on disk → reload_config() →
#         object carries updated value from the new file content
#
# This is the canonical hot-reload data-flow path exercised synchronously
# (reload_config() called directly, no SIGUSR1 involved).
# =============================================================================
subtest 'T4: register→reload→update — file change flows into a live registered object' => sub {
	plan tests => 5;

	_isolate_registry($VALID_CLASS);

	my $dir = tempdir(CLEANUP => 1);
	my $cfg = "$dir/trans-test-class.yml";
	_write_yaml($cfg, "Trans__Test__Class:\n  tier: initial\n");

	# configure() sets _config_file in the returned hashref (module line 644-645)
	my $hash = Object::Configure::configure($VALID_CLASS, { config_file => $cfg });
	is($hash->{tier}, 'initial', 'T4/1: initial tier loaded from config file');

	my $obj = bless { %$hash }, $VALID_CLASS;
	lives_ok { Object::Configure::register_object($VALID_CLASS, $obj) }
		'T4/2: register_object() accepts blessed object without exception';

	ok(exists $Object::Configure::_object_registry{$VALID_CLASS},
		'T4/3: class key present in registry immediately after register_object()');

	# Mutate the config file to a new value
	_write_yaml($cfg, "Trans__Test__Class:\n  tier: updated\n");

	lives_ok { Object::Configure::reload_config() }
		'T4/4: reload_config() completes without exception';

	is($obj->{tier}, 'updated',
		'T4/5: live object tier reflects new file value after reload_config()');

	_isolate_registry($VALID_CLASS);
};

# =============================================================================
# T5: register→GC→reload prunes dead registry entry
#
# Phases: register object in inner scope → object GC'd (weak ref cleared) →
#         reload_config() greps for live refs → dead-ref entry deleted →
#         class key removed from %_object_registry
#
# Invariant: the registry must never accumulate stale entries; each SIGUSR1
# delivery iterates the whole registry, so unbounded growth degrades throughput.
# =============================================================================
subtest 'T5: register→GC→reload prunes dead weak-ref registry entry' => sub {
	plan tests => 3;

	_isolate_registry('Trans::GC::Class');

	my $dir = tempdir(CLEANUP => 1);
	my $cfg = "$dir/trans-gc-class.yml";
	_write_yaml($cfg, "Trans__GC__Class:\n  x: 1\n");

	{
		my $obj = bless { _config_file => $cfg }, 'Trans::GC::Class';
		Object::Configure::register_object('Trans::GC::Class', $obj);

		ok(exists $Object::Configure::_object_registry{'Trans::GC::Class'},
			'T5/1: registry entry exists immediately after register_object()');
		# $obj goes out of scope → weak ref cleared by garbage collector
	}

	# The arrayref still exists, but its sole element is a dead weak ref.
	# reload_config() must detect it and delete the class key.
	my $count = Object::Configure::reload_config();

	ok(!exists $Object::Configure::_object_registry{'Trans::GC::Class'},
		'T5/2: class key deleted from registry after reload_config() prunes dead ref');

	is($count, 0, 'T5/3: reload count is 0 when only GC\'d objects were registered');
};

# =============================================================================
# T6: multi-object reload — one GC'd, others updated
#
# Phases: register obj_a (alive) + obj_b (will GC) + obj_c (alive) →
#         mutate configs for a and c → let b go out of scope → reload_config() →
#         obj_a updated, obj_c updated, obj_b entry deleted, count == 2
# =============================================================================
subtest 'T6: multi-object reload — GC\'d entry deleted, survivors updated' => sub {
	plan tests => 5;

	_isolate_registry($CLASS_A, $CLASS_B, $CLASS_C);

	my $dir   = tempdir(CLEANUP => 1);
	my $cfg_a = "$dir/trans-multi-a.yml";
	my $cfg_b = "$dir/trans-multi-b.yml";
	my $cfg_c = "$dir/trans-multi-c.yml";

	_write_yaml($cfg_a, "Trans__Multi__A:\n  val: a_init\n");
	_write_yaml($cfg_b, "Trans__Multi__B:\n  val: b_init\n");
	_write_yaml($cfg_c, "Trans__Multi__C:\n  val: c_init\n");

	my $obj_a = bless { _config_file => $cfg_a, val => 'a_init' }, $CLASS_A;
	my $obj_c = bless { _config_file => $cfg_c, val => 'c_init' }, $CLASS_C;

	Object::Configure::register_object($CLASS_A, $obj_a);

	{
		my $obj_b = bless { _config_file => $cfg_b, val => 'b_init' }, $CLASS_B;
		Object::Configure::register_object($CLASS_B, $obj_b);
		# $obj_b goes out of scope → weak ref cleared
	}

	Object::Configure::register_object($CLASS_C, $obj_c);

	_write_yaml($cfg_a, "Trans__Multi__A:\n  val: a_updated\n");
	_write_yaml($cfg_c, "Trans__Multi__C:\n  val: c_updated\n");

	my $count = Object::Configure::reload_config();

	is($obj_a->{val}, 'a_updated', 'T6/1: obj_a updated by reload');
	is($obj_c->{val}, 'c_updated', 'T6/2: obj_c updated by reload');

	ok(!exists $Object::Configure::_object_registry{$CLASS_B},
		'T6/3: GC\'d class_b entry deleted from registry by reload_config()');

	ok(exists $Object::Configure::_object_registry{$CLASS_A},
		'T6/4: surviving class_a entry retained in registry after reload');

	is($count, 2,
		'T6/5: reload count equals number of live objects successfully reloaded');

	_isolate_registry($CLASS_A, $CLASS_C);
};

# =============================================================================
# T7: multi-object same-class — push semantics; both entries updated
#
# register_object() pushes to a per-class array; it does NOT replace the
# previous entry.  Both objects should survive in the registry and both should
# receive the updated config value on reload.
# =============================================================================
subtest 'T7: multi-object same class — push semantics; both entries updated on reload' => sub {
	plan tests => 4;

	_isolate_registry('Trans::Same');

	my $dir = tempdir(CLEANUP => 1);
	my $cfg = "$dir/trans-same.yml";
	_write_yaml($cfg, "Trans__Same:\n  ver: 1\n");

	my $obj1 = bless { _config_file => $cfg, ver => 1, id => 'obj1' }, 'Trans::Same';
	my $obj2 = bless { _config_file => $cfg, ver => 1, id => 'obj2' }, 'Trans::Same';

	Object::Configure::register_object('Trans::Same', $obj1);
	lives_ok { Object::Configure::register_object('Trans::Same', $obj2) }
		'T7/1: second register_object() for same class does not croak';

	is(scalar @{ $Object::Configure::_object_registry{'Trans::Same'} }, 2,
		'T7/2: registry holds two separate entries for the same class (push semantics)');

	_write_yaml($cfg, "Trans__Same:\n  ver: 2\n");
	Object::Configure::reload_config();

	is($obj1->{ver}, 2, 'T7/3: first registered object receives the config update');
	is($obj2->{ver}, 2, 'T7/4: second registered object also receives the config update');

	_isolate_registry('Trans::Same');
};

# =============================================================================
# T8: mid-reload resilience — nonexistent config file skipped; good one updated
#
# Register good_obj (real config file) + bad_obj (nonexistent config file).
# When bad_obj's _reload_object_config runs, it finds no readable file and
# returns early.  The good_obj must still be updated and the call must not croak.
#
# Invariant: a bad entry must not abort reload for subsequent good entries.
# =============================================================================
subtest 'T8: mid-reload resilience — bad config skipped, good config updated' => sub {
	plan tests => 3;

	_isolate_registry('Trans::Bad', 'Trans::Good');

	my $dir      = tempdir(CLEANUP => 1);
	my $good_cfg = "$dir/trans-good.yml";
	_write_yaml($good_cfg, "Trans__Good:\n  level: 1\n");

	my $good = bless { _config_file => $good_cfg,        level => 1 }, 'Trans::Good';
	my $bad  = bless { _config_file => "$dir/ghost.yml"           }, 'Trans::Bad';

	Object::Configure::register_object('Trans::Good', $good);
	Object::Configure::register_object('Trans::Bad',  $bad);

	_write_yaml($good_cfg, "Trans__Good:\n  level: 2\n");

	lives_ok { Object::Configure::reload_config() }
		'T8/1: reload_config() does not croak when one entry has a nonexistent config file';

	is($good->{level}, 2,
		'T8/2: good object updated despite bad sibling in registry');

	ok(exists $Object::Configure::_object_registry{'Trans::Good'},
		'T8/3: good object\'s registry entry survives the partial-failure reload');

	_isolate_registry('Trans::Bad', 'Trans::Good');
};

# =============================================================================
# T9: mid-reload exception — _reload_object_config throws; reload_config catches
#
# reload_config() wraps each _reload_object_config call in eval{}.  A thrown
# exception must be caught, surfaced as a carp warning, and must NOT propagate
# to the caller (signal-handler safety: an uncaught exception in a SIGUSR1
# handler terminates the process).
# =============================================================================
subtest 'T9: mid-reload exception — caught by eval, surfaced as carp warning' => sub {
	plan tests => 3;

	_isolate_registry('Trans::Exc');

	my $dir = tempdir(CLEANUP => 1);
	my $cfg = "$dir/trans-exc.yml";
	_write_yaml($cfg, "Trans__Exc:\n  x: 1\n");

	my $obj = bless { _config_file => $cfg }, 'Trans::Exc';
	Object::Configure::register_object('Trans::Exc', $obj);

	my $warned = '';
	local $SIG{__WARN__} = sub { $warned .= $_[0] };

	my $count;
	{
		no warnings 'redefine';
		local *Object::Configure::_reload_object_config = sub { die "injected error\n" };
		lives_ok { $count = Object::Configure::reload_config() }
			'T9/1: reload_config() does not propagate _reload_object_config exception';
	}

	like($warned, qr/injected error/,
		'T9/2: exception text surfaced as carp warning by reload_config()');

	is($count, 0,
		'T9/3: reload count is 0 when all _reload_object_config calls threw');

	_isolate_registry('Trans::Exc');
};

# =============================================================================
# T10: instantiate() full lifecycle transaction
#
# Phases: write config file → instantiate() → configure() called internally →
#         $class->new($params) called → blessed object returned with the correct
#         class name and the config file values accessible as attributes
# =============================================================================
subtest 'T10: instantiate() lifecycle — Write→configure()→new()→bless→Return' => sub {
	plan tests => 4;

	my $dir = tempdir(CLEANUP => 1);
	my $cfg = "$dir/insttrans-target.yml";
	_write_yaml($cfg, "InstTrans__Target:\n  name: from_config\n  code: 42\n");

	my $obj;
	lives_ok { $obj = Object::Configure::instantiate(class => $INST_CLASS, config_file => $cfg) }
		'T10/1: instantiate() completes without exception';

	ok(blessed($obj),
		'T10/2: instantiate() returns a blessed reference');

	is(blessed($obj), $INST_CLASS,
		'T10/3: object is blessed into the requested class');

	is($obj->{name}, 'from_config',
		'T10/4: config file value present on the instantiated object');
};

# =============================================================================
# T11: instantiate() 'class' key debugging semantics
#
# The 'class' parameter is intentionally left in $params so it propagates
# through configure() and into $class->new().  This is documented in the
# module source (lines 744-745): the key appears on the returned object as a
# debugging aid so callers can introspect which class was instantiated.
# =============================================================================
subtest 'T11: instantiate() class-key semantics — key preserved on object (by design)' => sub {
	plan tests => 2;

	my $dir = tempdir(CLEANUP => 1);
	my $cfg = "$dir/insttrans-target.yml";
	_write_yaml($cfg, "InstTrans__Target:\n  real_key: yes\n");

	my $obj = Object::Configure::instantiate(class => $INST_CLASS, config_file => $cfg);

	ok(exists $obj->{class},
		'T11/1: "class" key present on returned object (debugging aid, intentional)');

	is($obj->{class}, $INST_CLASS,
		'T11/2: "class" key value matches the requested class name');
};

# =============================================================================
# T12–T14: hot-reload watcher lifecycle (Unix only — SIGUSR1 not on MSWin32)
# =============================================================================
SKIP: {
	skip 'Hot reload not supported on MSWin32 (no SIGUSR1)', 10
		if $^O eq 'MSWin32';

	# Guard: clean up any leftover watcher from a previous run in this process.
	Object::Configure::disable_hot_reload() if %Object::Configure::_config_watchers;

	# =========================================================================
	# T12: enable_hot_reload() → disable_hot_reload() watcher lifecycle
	#
	# Phases: no watcher → enable (fork) → PID > 1 stored in %_config_watchers →
	#         disable (SIGTERM + waitpid) → %_config_watchers cleared
	# =========================================================================
	subtest 'T12: watcher lifecycle — enable→fork→PID stored→disable→cleared' => sub {
		plan tests => 5;

		ok(!%Object::Configure::_config_watchers,
			'T12/1: no watcher running before enable_hot_reload()');

		lives_ok { Object::Configure::enable_hot_reload(interval => $HOT_INTERVAL, callback => sub {}) }
			'T12/2: enable_hot_reload() completes without exception';

		ok(%Object::Configure::_config_watchers,
			'T12/3: _config_watchers populated after enable_hot_reload()');

		my $pid = $Object::Configure::_config_watchers{pid};
		ok(defined $pid && $pid > 1,
			'T12/4: stored watcher PID is a valid positive integer > 1');

		Object::Configure::disable_hot_reload();
		ok(!%Object::Configure::_config_watchers,
			'T12/5: _config_watchers cleared after disable_hot_reload()');
	};

	# =========================================================================
	# T13: enable_hot_reload() idempotency — double-enable must not double-fork
	#
	# The guard at the top of enable_hot_reload() returns immediately if
	# %_config_watchers is already populated.  The stored PID must not change.
	# =========================================================================
	subtest 'T13: enable_hot_reload() idempotency — double-enable is a no-op' => sub {
		plan tests => 3;

		lives_ok { Object::Configure::enable_hot_reload(interval => $HOT_INTERVAL, callback => sub {}) }
			'T13/1: first enable_hot_reload() succeeds';

		my $pid1 = $Object::Configure::_config_watchers{pid};

		lives_ok { Object::Configure::enable_hot_reload(interval => $HOT_INTERVAL, callback => sub {}) }
			'T13/2: second enable_hot_reload() does not croak';

		my $pid2 = $Object::Configure::_config_watchers{pid};

		is($pid1, $pid2,
			'T13/3: watcher PID unchanged after double-enable (no new fork created)');

		Object::Configure::disable_hot_reload();
	};

	# =========================================================================
	# T14: disable_hot_reload() idempotency — double-disable must not crash
	#
	# The guard at the top of disable_hot_reload() returns immediately when
	# %_config_watchers is empty.  No SIGTERM is sent to a nonexistent PID.
	# =========================================================================
	subtest 'T14: disable_hot_reload() idempotency — double-disable is safe' => sub {
		plan tests => 2;

		Object::Configure::enable_hot_reload(interval => $HOT_INTERVAL, callback => sub {});
		Object::Configure::disable_hot_reload();

		lives_ok { Object::Configure::disable_hot_reload() }
			'T14/1: second disable_hot_reload() when already stopped does not croak';

		ok(!%Object::Configure::_config_watchers,
			'T14/2: _config_watchers remains empty after double-disable');
	};
}

done_testing();
