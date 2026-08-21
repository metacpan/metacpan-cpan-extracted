#!/usr/bin/env perl

# t/domain.t — Equivalence Partitioning (EP) and Boundary Value Analysis (BVA)
# for every input parameter of Object::Configure's public and private APIs.
#
# Strategy per parameter:
#   1. One representative from each valid partition (EP valid)
#   2. One representative from each invalid partition (EP invalid) — verify rejection
#   3. Exact boundary edges (BVA): min, min-1, min+1, max, max-1, max+1
#
# Notation used in subtest names:
#   VP  = Valid Partition      IP  = Invalid Partition
#   CP  = Clamped Partition    BVA = Boundary Value Analysis

use strict;
use warnings;
use Test::Most;
use File::Temp   qw(tempdir tempfile);
use File::Spec;
use Scalar::Util qw(blessed);
use Readonly;

use lib '/home/njh/src/njh/Test-Returns/lib';
use Test::Returns;

BEGIN { use_ok('Object::Configure') }

# ---------------------------------------------------------------------------
# Constants — no magic numbers or strings in test bodies
# ---------------------------------------------------------------------------

Readonly my $DEFAULT_INTERVAL  => 10;        # mirrors $DEFAULT_INTERVAL in module
Readonly my $VALID_CLASS        => 'Domain::Test::Class';
Readonly my $EMPTY_CLASS_MSG    => qr/what class do you want to configure/i;
Readonly my $INVALID_CLASS_MSG  => qr/invalid class name/i;
Readonly my $TRAVERSAL_MSG      => qr/path traversal/i;
Readonly my $USAGE_CROAK_MSG    => qr/Usage/i;
Readonly my $VERY_LONG_LENGTH   => 130;      # used for max-boundary class names
Readonly my $DEEP_LEVELS        => 50;       # BVA for _deep_merge nesting
Readonly my $MANY_DIRS          => 5;        # BVA for config_dirs multi-element

# Inline test class for instantiate() — accepts any hashref from new()
package InstTest::Minimal {
	sub new {
		my ($class, $params) = @_;
		return bless { %$params }, $class;
	}
}

package main;

# =============================================================================
# DOMAIN 1: configure() — $class parameter
#
# Validation rule: /\A[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*\z/
# Empty/undef check fires first.
# =============================================================================

subtest 'EP valid: configure() $class — representative valid partitions' => sub {
	plan tests => 8;

	# VP1: Single letter (minimum length = 1)
	ok(ref(Object::Configure::configure('A', {})) eq 'HASH',
		'VP1: single-letter class "A" accepted');

	# VP2: Single underscore (boundary — leading underscore is the other valid first char)
	ok(ref(Object::Configure::configure('_', {})) eq 'HASH',
		'VP2: underscore-only class "_" accepted');

	# VP3: Typical two-component class
	ok(ref(Object::Configure::configure('My::Module', {})) eq 'HASH',
		'VP3: "My::Module" two-component class accepted');

	# VP4: Digits after the first character (digit ≠ first — valid)
	ok(ref(Object::Configure::configure('Foo2::Bar3', {})) eq 'HASH',
		'VP4: digits-after-first-char "Foo2::Bar3" accepted');

	# VP5: Underscore leading each component
	ok(ref(Object::Configure::configure('_Private::_Inner', {})) eq 'HASH',
		'VP5: underscore-leading components "_Private::_Inner" accepted');

	# VP6: Deep four-level hierarchy
	ok(ref(Object::Configure::configure('A::B::C::D', {})) eq 'HASH',
		'VP6: four-level "A::B::C::D" hierarchy accepted');

	# BVA min+1 = length 2
	ok(ref(Object::Configure::configure('Zz', {})) eq 'HASH',
		'BVA min+1: two-char class "Zz" accepted');

	# BVA large: very long valid class name
	my $long = 'A' . ('a' x $VERY_LONG_LENGTH) . '::' . 'B' . ('b' x $VERY_LONG_LENGTH);
	ok(ref(Object::Configure::configure($long, {})) eq 'HASH',
		'BVA large: very long valid class name accepted');
};

subtest 'EP invalid: configure() $class — undef (BVA absent)' => sub {
	plan tests => 1;
	throws_ok { Object::Configure::configure(undef, {}) }
		$EMPTY_CLASS_MSG, 'IP1: undef class → "what class" croak';
};

subtest 'EP invalid: configure() $class — empty string (BVA min-1, length 0)' => sub {
	plan tests => 1;
	throws_ok { Object::Configure::configure('', {}) }
		$EMPTY_CLASS_MSG, 'IP2 BVA min-1: empty string → "what class" croak';
};

subtest 'EP invalid: configure() $class — digit-first components' => sub {
	plan tests => 3;

	# IP3a: digit-first top-level component
	throws_ok { Object::Configure::configure('1Foo', {}) }
		$INVALID_CLASS_MSG, 'IP3a: "1Foo" (digit-first top) rejected';

	# IP3b: digit-first second component
	throws_ok { Object::Configure::configure('Foo::1Bar', {}) }
		$INVALID_CLASS_MSG, 'IP3b: "Foo::1Bar" (digit-first second) rejected';

	# IP3c: digit-first in third position
	throws_ok { Object::Configure::configure('Foo::Bar::2Baz', {}) }
		$INVALID_CLASS_MSG, 'IP3c: "Foo::Bar::2Baz" (digit-first third) rejected';
};

subtest 'EP invalid: configure() $class — injection characters' => sub {
	plan tests => 6;

	throws_ok { Object::Configure::configure("Foo\nBar", {}) }
		$INVALID_CLASS_MSG, 'IP4a: newline in class name rejected';

	throws_ok { Object::Configure::configure("Foo\rBar", {}) }
		$INVALID_CLASS_MSG, 'IP4b: carriage return in class name rejected';

	throws_ok { Object::Configure::configure('Foo;Bar', {}) }
		$INVALID_CLASS_MSG, 'IP4c: semicolon in class name rejected';

	throws_ok { Object::Configure::configure('Foo Bar', {}) }
		$INVALID_CLASS_MSG, 'IP4d: space in class name rejected';

	throws_ok { Object::Configure::configure('Foo|Bar', {}) }
		$INVALID_CLASS_MSG, 'IP4e: pipe in class name rejected';

	throws_ok { Object::Configure::configure("Foo\x00Bar", {}) }
		$INVALID_CLASS_MSG, 'IP4f: null byte in class name rejected';
};

subtest 'BVA: configure() $class — malformed :: syntax boundaries' => sub {
	plan tests => 3;

	# Trailing :: — last component is empty (length 0, below min-per-component of 1)
	throws_ok { Object::Configure::configure('Foo::', {}) }
		$INVALID_CLASS_MSG, 'BVA: trailing :: (empty last component) rejected';

	# Leading :: — first component is empty
	throws_ok { Object::Configure::configure('::Foo', {}) }
		$INVALID_CLASS_MSG, 'BVA: leading :: (empty first component) rejected';

	# Empty interior component (Foo::::Bar has an empty component between)
	throws_ok { Object::Configure::configure('Foo::::Bar', {}) }
		$INVALID_CLASS_MSG, 'BVA: empty interior :: component (Foo::::Bar) rejected';
};

# =============================================================================
# DOMAIN 2: configure() — config_file parameter
#
# S1 path-traversal guard: fires on qr{(?:\A|/)\.\.(?:/|\z)}
# Falsy config_file: if($config_file) is false → env-only branch (no croak)
# =============================================================================

subtest 'EP valid: configure() config_file — falsy values treated as absent' => sub {
	plan tests => 3;

	# VP1: absent (undef)
	ok(ref(Object::Configure::configure($VALID_CLASS, {})) eq 'HASH',
		'VP1: absent config_file → env-only branch, no croak');

	# VP2: numeric 0 (falsy — if($config_file) is false)
	ok(ref(Object::Configure::configure($VALID_CLASS, { config_file => 0 })) eq 'HASH',
		'VP2: config_file => 0 (falsy) treated as absent');

	# VP3: empty string (falsy)
	ok(ref(Object::Configure::configure($VALID_CLASS, { config_file => '' })) eq 'HASH',
		'VP3: config_file => "" (falsy) treated as absent');
};

subtest 'EP valid: configure() config_file — readable absolute path' => sub {
	plan tests => 2;
	my $temp = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($temp, 'domain-test-class.yml');
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print $fh "---\nDomain__Test__Class:\n  ep_key: ep_value\n";
	close $fh;

	my $r = Object::Configure::configure($VALID_CLASS, { config_file => $path });
	ok(ref($r) eq 'HASH', 'VP4: readable absolute config_file accepted');
	is($r->{ep_key}, 'ep_value', 'VP4: value from config file is present in result');
};

subtest 'EP invalid: configure() config_file — path traversal variants' => sub {
	plan tests => 4;

	# IP1: leading traversal (most common attack vector)
	throws_ok {
		Object::Configure::configure($VALID_CLASS, { config_file => '../etc/passwd' });
	} $TRAVERSAL_MSG, 'IP1: leading "../" traversal rejected';

	# IP2: embedded traversal in the middle
	throws_ok {
		Object::Configure::configure($VALID_CLASS, { config_file => 'foo/../bar.yml' });
	} $TRAVERSAL_MSG, 'IP2: embedded "/../" traversal rejected';

	# IP3: trailing /.. (another common form)
	throws_ok {
		Object::Configure::configure($VALID_CLASS, { config_file => 'foo/..' });
	} $TRAVERSAL_MSG, 'IP3: trailing "/.." traversal rejected';

	# IP4: absolute path with embedded traversal
	throws_ok {
		Object::Configure::configure($VALID_CLASS, { config_file => '/etc/../../etc/passwd' });
	} $TRAVERSAL_MSG, 'IP4: absolute path with traversal rejected';
};

subtest 'BVA: configure() config_file — boundary: ".." within filename (not a segment)' => sub {
	plan tests => 1;
	my $temp = tempdir(CLEANUP => 1);
	# "foo..bar.yml" has ".." as part of the filename, not as a path segment → NOT traversal
	my $path = File::Spec->catfile($temp, 'foo..bar.yml');
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print $fh "---\n";
	close $fh;

	# Must NOT be rejected — ".." here is inside a filename component, not between slashes
	my $r = Object::Configure::configure($VALID_CLASS, { config_file => $path });
	ok(ref($r) eq 'HASH', 'BVA: "foo..bar.yml" (dot-dot within filename) not rejected as traversal');
};

subtest 'BVA: configure() config_file — relative path via config_dirs' => sub {
	plan tests => 2;
	my $temp = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($temp, 'domain-test-class.yml');
	open my $fh, '>', $path or die;
	print $fh "---\nDomain__Test__Class:\n  from: dirs\n";
	close $fh;

	my $r = Object::Configure::configure($VALID_CLASS, {
		config_file => 'domain-test-class.yml',
		config_dirs => [$temp],
	});
	ok(ref($r) eq 'HASH', 'BVA: relative config_file found via config_dirs');
	is($r->{from}, 'dirs', 'BVA: config value loaded via config_dirs resolution');
};

# =============================================================================
# DOMAIN 3: configure() — logger parameter
#
# Six distinct spec types handled by _build_logger():
#   undef → default L::A      'NULL' → passthrough string
#   \@arr → L::A(array)       \%h   → L::A(hashref)
#   L::A instance → passthrough    scalar string → L::A(logger => scalar)
# =============================================================================

subtest 'EP: configure() logger — all valid partitions' => sub {
	plan tests => 7;

	# VP1: absent → default Log::Abstraction
	my $r1 = Object::Configure::configure($VALID_CLASS, {});
	ok(blessed($r1->{logger}) && $r1->{logger}->isa('Log::Abstraction'),
		'VP1: absent logger → default Log::Abstraction');

	# VP2: 'NULL' string — tested directly via _build_logger() to isolate from
	# the site-local UNIVERSAL config (which can override non-arrayref logger specs
	# during the config merge in configure()).  The _build_logger() path is the
	# normative implementation path: configure() delegates to it unconditionally.
	my $b2 = Object::Configure::_build_logger('NULL', 0);
	is($b2, 'NULL',
		'VP2: _build_logger("NULL") → passthrough string (no L::A created)');

	# VP3: arrayref → L::A with array backend (stashed before config merge; always wins)
	my @captured;
	my $r3 = Object::Configure::configure($VALID_CLASS, { logger => \@captured });
	ok(blessed($r3->{logger}) && $r3->{logger}->isa('Log::Abstraction'),
		'VP3: arrayref logger → Log::Abstraction with array backend');
	ok(defined $r3->{logger}{array},
		'VP3: array backend assigned in Log::Abstraction');

	# VP4: hashref spec → L::A constructed from options
	my $r4 = Object::Configure::configure($VALID_CLASS, { logger => { level => 'notice' } });
	ok(blessed($r4->{logger}) && $r4->{logger}->isa('Log::Abstraction'),
		'VP4: hashref logger spec → Log::Abstraction instance');

	# VP5: pre-built L::A instance — tested via _build_logger() for the same isolation
	# reason as VP2: a site-local UNIVERSAL config can overwrite the logger key during
	# the configure() merge before _build_logger() is called.
	my $existing = Log::Abstraction->new();
	my $b5 = Object::Configure::_build_logger($existing, 0);
	is($b5, $existing,
		'VP5: _build_logger(existing L::A) → passthrough (identity preserved)');

	# VP6: scalar string → L::A created with logger => scalar
	my $r6 = Object::Configure::configure($VALID_CLASS, { logger => 'my_logger_name' });
	ok(blessed($r6->{logger}) && $r6->{logger}->isa('Log::Abstraction'),
		'VP6: scalar string logger → Log::Abstraction wraps it');
};

# =============================================================================
# DOMAIN 4: configure() — $params argument type domain
# =============================================================================

subtest 'EP: configure() $params — valid partition: undef defaults to {}' => sub {
	plan tests => 1;
	my $r = Object::Configure::configure($VALID_CLASS, undef);
	ok(ref($r) eq 'HASH', 'VP1: undef $params → defaults to {} (no croak)');
};

subtest 'EP: configure() $params — valid partition: empty hashref' => sub {
	plan tests => 1;
	my $r = Object::Configure::configure($VALID_CLASS, {});
	ok(ref($r) eq 'HASH', 'VP2: empty hashref $params → works cleanly');
};

subtest 'EP invalid: configure() $params — arrayref causes type error' => sub {
	plan tests => 1;
	# An arrayref passed as $params triggers Perl's "Not a HASH reference" when
	# configure() dereferences it as %$params — documented hostile-input behavior.
	dies_ok {
		Object::Configure::configure($VALID_CLASS, [qw(key val)]);
	} 'IP1: arrayref $params → Perl type error (Not a HASH reference)';
};

# =============================================================================
# DOMAIN 5: configure() — config_dirs parameter
# =============================================================================

subtest 'EP: configure() config_dirs — valid partitions' => sub {
	plan tests => 3;

	# VP1: absent (undef) — no dir search
	my $r1 = Object::Configure::configure($VALID_CLASS, {});
	ok(ref($r1) eq 'HASH', 'VP1: absent config_dirs → works');

	# VP2: empty arrayref (BVA min: zero elements)
	my $r2 = Object::Configure::configure($VALID_CLASS, { config_dirs => [] });
	ok(ref($r2) eq 'HASH', 'VP2 BVA-min: empty config_dirs [] → works');

	# VP3: single valid dir (BVA min+1: one element)
	my $temp = tempdir(CLEANUP => 1);
	my $r3 = Object::Configure::configure($VALID_CLASS, { config_dirs => [$temp] });
	ok(ref($r3) eq 'HASH', 'VP3 BVA-min+1: single-element config_dirs → works');
};

subtest 'BVA: configure() config_dirs — many directories (max boundary)' => sub {
	plan tests => 1;
	# BVA max: 5 directories (last resort — no matching file in any dir)
	my @dirs = map { tempdir(CLEANUP => 1) } 1 .. $MANY_DIRS;
	my $r = Object::Configure::configure($VALID_CLASS, {
		config_file => 'nonexistent-file.yml',
		config_dirs => \@dirs,
	});
	ok(ref($r) eq 'HASH', "BVA max-dirs: $MANY_DIRS config_dirs entries, no match → no croak");
};

subtest 'BVA: configure() config_dirs — file path as dir entry (ignored)' => sub {
	plan tests => 1;
	my $temp = tempdir(CLEANUP => 1);
	my ($fh, $tfile) = tempfile(DIR => $temp, SUFFIX => '.yml');
	close $fh;
	# A file path where a directory is expected: silently ignored
	my $r = Object::Configure::configure($VALID_CLASS, {
		config_dirs => [$tfile],
	});
	ok(ref($r) eq 'HASH', 'BVA: file path as config_dirs entry → silently ignored');
};

# =============================================================================
# DOMAIN 6: enable_hot_reload() — interval parameter
#
# POD: "Number of seconds between configuration file checks. Lower values
#       provide faster response to changes but consume more CPU."
# Constraint: interval <= 0 is clamped to $DEFAULT_INTERVAL (10).
# Upper bound: none — any positive integer is accepted.
# =============================================================================

SKIP: {
	skip 'Signal/fork tests not applicable on Windows', 7 if $^O eq 'MSWin32';

	subtest 'EP valid: enable_hot_reload() interval — partition: absent (undef → default)' => sub {
		plan tests => 1;
		%Object::Configure::_config_watchers = ();
		my $pid = Object::Configure::enable_hot_reload();
		ok($pid && $pid > 0, 'VP1: absent interval → default used, valid PID returned');
		Object::Configure::disable_hot_reload();
	};

	subtest 'EP valid: enable_hot_reload() interval — BVA min: value 1' => sub {
		plan tests => 1;
		%Object::Configure::_config_watchers = ();
		my $pid = Object::Configure::enable_hot_reload(interval => 1);
		ok($pid && $pid > 0, 'VP2 BVA-min: interval=>1 (minimum valid) → valid PID');
		Object::Configure::disable_hot_reload();
	};

	subtest 'EP valid: enable_hot_reload() interval — typical value' => sub {
		plan tests => 1;
		%Object::Configure::_config_watchers = ();
		my $pid = Object::Configure::enable_hot_reload(interval => 30);
		ok($pid && $pid > 0, 'VP3: interval=>30 → valid PID');
		Object::Configure::disable_hot_reload();
	};

	subtest 'CP clamped: enable_hot_reload() interval — BVA min-1: value 0' => sub {
		plan tests => 2;
		%Object::Configure::_config_watchers = ();
		# 0 is clamped to DEFAULT_INTERVAL — fork must still succeed
		my $pid = Object::Configure::enable_hot_reload(interval => 0);
		ok($pid && $pid > 0, 'CP1 BVA-min-1: interval=>0 clamped, fork succeeds');
		ok(kill(0, $pid), 'CP1: watcher process is alive after zero-interval clamp');
		Object::Configure::disable_hot_reload();
	};

	subtest 'CP clamped: enable_hot_reload() interval — negative value' => sub {
		plan tests => 1;
		%Object::Configure::_config_watchers = ();
		my $pid = Object::Configure::enable_hot_reload(interval => -9999);
		ok($pid && $pid > 0, 'CP2 BVA: interval=>-9999 clamped to default, fork succeeds');
		Object::Configure::disable_hot_reload();
	};

	subtest 'BVA max: enable_hot_reload() interval — very large positive value' => sub {
		plan tests => 1;
		%Object::Configure::_config_watchers = ();
		# No upper bound: large values are accepted as-is
		my $pid = Object::Configure::enable_hot_reload(interval => 86_400);
		ok($pid && $pid > 0, 'BVA max: interval=>86400 (1 day) accepted, valid PID');
		Object::Configure::disable_hot_reload();
	};

	subtest 'EP: enable_hot_reload() — double-enable guard (already watching → no-op)' => sub {
		plan tests => 2;
		%Object::Configure::_config_watchers = ();
		my $pid1 = Object::Configure::enable_hot_reload(interval => 1);
		ok($pid1 && $pid1 > 0, 'First enable returns valid PID');
		# Second call: %_config_watchers is already populated → return; (undef)
		my $result2 = Object::Configure::enable_hot_reload(interval => 1);
		ok(!defined($result2), 'Second enable (already watching) returns undef/void');
		Object::Configure::disable_hot_reload();
	};
}

# =============================================================================
# DOMAIN 7: register_object() — $class and $obj parameters
#
# POD: "class (Required), obj (Required). Croaks with usage if either is undef."
# =============================================================================

subtest 'EP valid: register_object() — defined class + defined obj' => sub {
	plan tests => 1;
	my $obj = bless {}, 'Domain::Reg::Class';
	lives_ok {
		Object::Configure::register_object('Domain::Reg::Class', $obj);
	} 'VP1: defined class + blessed obj → no croak';
	delete $Object::Configure::_object_registry{'Domain::Reg::Class'};
};

subtest 'EP invalid: register_object() — undef class' => sub {
	plan tests => 1;
	my $obj = bless {}, 'Domain::Reg::Class';
	throws_ok {
		Object::Configure::register_object(undef, $obj);
	} $USAGE_CROAK_MSG, 'IP1: undef class → usage croak';
};

subtest 'EP invalid: register_object() — undef obj' => sub {
	plan tests => 1;
	throws_ok {
		Object::Configure::register_object('Domain::Reg::Class', undef);
	} $USAGE_CROAK_MSG, 'IP2: undef obj → usage croak';
};

subtest 'EP invalid: register_object() — both args undef' => sub {
	plan tests => 1;
	throws_ok {
		Object::Configure::register_object(undef, undef);
	} $USAGE_CROAK_MSG, 'IP3: both undef → usage croak';
};

subtest 'BVA: register_object() — unblessed hashref rejected (blessed guard enforced)' => sub {
	plan tests => 1;
	# Security fix S2: register_object() now enforces blessed() at registration.
	# An unblessed ref must croak immediately, not be silently stored.
	my $unblessed = { key => 'val' };
	throws_ok {
		Object::Configure::register_object('Domain::Unreg::Class', $unblessed);
	} qr/register_object: \$obj must be a blessed reference/,
		'BVA: unblessed hashref causes immediate croak at registration';
};

# =============================================================================
# DOMAIN 8: _deep_merge() — $base × $overlay type domains
#
# Rule (line 1637-1638): returns $overlay unless both args are HASH refs.
# Recursive on nested hashrefs; overlay wins on key collision.
# =============================================================================

subtest 'EP: _deep_merge() — full type matrix for base × overlay' => sub {
	plan tests => 9;

	# VP1: (hashref, hashref) — non-overlapping keys → union
	my $r1 = Object::Configure::_deep_merge({ a => 1 }, { b => 2 });
	is_deeply($r1, { a => 1, b => 2 }, 'VP1: (hash,hash) non-overlap → union');

	# VP2: (hashref, hashref) — collision → overlay wins
	my $r2 = Object::Configure::_deep_merge({ a => 1 }, { a => 99 });
	is($r2->{a}, 99, 'VP2: (hash,hash) collision → overlay value wins');

	# VP3: (hashref, undef) — base is hash but overlay is not → return overlay (undef)
	my $r3 = Object::Configure::_deep_merge({ a => 1 }, undef);
	ok(!defined($r3), 'VP3: (hash, undef) → undef (overlay precedence)');

	# VP4: (undef, hashref) — base is not hash → return overlay
	my $r4 = Object::Configure::_deep_merge(undef, { x => 1 });
	is_deeply($r4, { x => 1 }, 'VP4: (undef, hash) → overlay hashref');

	# VP5: (undef, undef) — neither is hash → return overlay (undef)
	my $r5 = Object::Configure::_deep_merge(undef, undef);
	ok(!defined($r5), 'VP5: (undef, undef) → undef');

	# VP6: (hashref, scalar) — overlay is scalar → scalar wins
	my $r6 = Object::Configure::_deep_merge({ a => 1 }, 'replaced');
	is($r6, 'replaced', 'VP6: (hash, scalar) → scalar overlay wins');

	# VP7: (hashref, arrayref) — overlay is arrayref → arrayref wins
	my $r7 = Object::Configure::_deep_merge({ a => 1 }, [1, 2, 3]);
	is_deeply($r7, [1, 2, 3], 'VP7: (hash, arrayref) → arrayref overlay wins');

	# VP8: nested (hash, hash) — recursive: base child key preserved when overlay lacks it
	my $r8 = Object::Configure::_deep_merge(
		{ a => { b => 1, c => 2 } },
		{ a => { b => 99 } },
	);
	is($r8->{a}{b}, 99, 'VP8: deep merge — overlapping nested key wins');
	is($r8->{a}{c}, 2,  'VP8: deep merge — non-overlapping nested key preserved');
};

subtest 'BVA: _deep_merge() — 50-level deep nesting (stack overflow boundary)' => sub {
	plan tests => 2;

	# Build two DEEP_LEVELS-deep hashrefs with distinct leaf values
	my ($base, $overlay) = ({}, {});
	my ($b_cur, $o_cur) = ($base, $overlay);
	for my $i (1 .. $DEEP_LEVELS) {
		if($i < $DEEP_LEVELS) {
			$b_cur->{nest} = {};
			$o_cur->{nest} = {};
			$b_cur = $b_cur->{nest};
			$o_cur = $o_cur->{nest};
		} else {
			$b_cur->{val} = 'base_leaf';
			$o_cur->{val} = 'overlay_leaf';
		}
	}

	my $merged;
	lives_ok {
		$merged = Object::Configure::_deep_merge($base, $overlay);
	} "BVA: $DEEP_LEVELS-level deep merge completes without stack overflow";

	# Traverse to the leaf to verify overlay won
	my $cur = $merged;
	$cur = $cur->{nest} for 1 .. ($DEEP_LEVELS - 1);
	is($cur->{val}, 'overlay_leaf',
		"BVA: overlay value wins at depth $DEEP_LEVELS");
};

# =============================================================================
# DOMAIN 9: _get_inheritance_chain() — class name input
#
# Entry constraint: class is a valid Perl package name (already validated by configure).
# Output invariant: first element is always 'UNIVERSAL'; last is the class itself.
# =============================================================================

subtest 'EP: _get_inheritance_chain() — class with no explicit parents' => sub {
	plan tests => 3;

	delete $Object::Configure::_chain_cache{'Chain::Solo'};
	my @chain = Object::Configure::_get_inheritance_chain('Chain::Solo');

	is($chain[0],  'UNIVERSAL',   'VP1: first element always UNIVERSAL');
	is($chain[-1], 'Chain::Solo', 'VP1: last element is the class itself');
	ok(scalar(@chain) >= 2,       'VP1: chain has at least 2 elements');
};

subtest 'EP: _get_inheritance_chain() — class with explicit parent via @ISA' => sub {
	plan tests => 3;

	delete $Object::Configure::_chain_cache{'Chain::Child2'};
	delete $Object::Configure::_chain_cache{'Chain::Parent2'};
	{ no strict 'refs'; @{'Chain::Child2::ISA'} = ('Chain::Parent2'); }

	my @chain = Object::Configure::_get_inheritance_chain('Chain::Child2');
	my %set   = map { $_ => 1 } @chain;

	ok($set{'UNIVERSAL'},       'VP2: UNIVERSAL present in child chain');
	ok($set{'Chain::Parent2'},  'VP2: parent present in child chain');
	ok($set{'Chain::Child2'},   'VP2: class itself present in child chain');
};

subtest 'BVA: _get_inheritance_chain() — UNIVERSAL appears exactly once' => sub {
	plan tests => 1;
	delete $Object::Configure::_chain_cache{'BVA::UniOnce'};
	my @chain = Object::Configure::_get_inheritance_chain('BVA::UniOnce');
	my @unis  = grep { $_ eq 'UNIVERSAL' } @chain;
	is(scalar(@unis), 1, 'BVA: UNIVERSAL appears exactly once (not duplicated)');
};

# =============================================================================
# DOMAIN 10: instantiate() — class key domain
#
# Required input: 'class' key must be a valid, loadable class with a new() method.
# =============================================================================

subtest 'EP invalid: instantiate() — missing class key' => sub {
	plan tests => 1;
	# Params::Get returns hashref; missing 'class' → undef → configure(undef,...) → croak
	throws_ok {
		Object::Configure::instantiate(not_class => 'Foo');
	} qr/class/i, 'IP1: missing class key → propagates to croak';
};

subtest 'EP invalid: instantiate() — class key is undef' => sub {
	plan tests => 1;
	throws_ok {
		Object::Configure::instantiate(class => undef);
	} qr/class/i, 'IP2: class => undef → croak (empty class check in configure)';
};

subtest 'EP valid: instantiate() — loadable class with new()' => sub {
	plan tests => 2;

	# Use the inline InstTest::Minimal class which accepts any hashref from new()
	my $obj = Object::Configure::instantiate(class => 'InstTest::Minimal');
	ok(defined($obj), 'VP1: instantiate("InstTest::Minimal") returns defined object');
	ok(blessed($obj) && $obj->isa('InstTest::Minimal'),
		'VP1: returned object isa InstTest::Minimal');
};

# =============================================================================
# DOMAIN 11: Combinatorial BVA — extreme combinations
# =============================================================================

subtest 'Combinatorial BVA: max-length class + many config_dirs, no match' => sub {
	plan tests => 1;
	my @dirs = map { tempdir(CLEANUP => 1) } 1 .. $MANY_DIRS;
	my $long = 'X' . ('x' x 50) . '::' . 'Y' . ('y' x 50);
	my $r = Object::Configure::configure($long, {
		config_file => 'no-such-file.yml',
		config_dirs => \@dirs,
	});
	ok(ref($r) eq 'HASH',
		"Combinatorial: long class + $MANY_DIRS config_dirs with no match → no croak");
};

subtest 'Combinatorial BVA: $params with 0 and 1 key (border of empty)' => sub {
	plan tests => 2;

	# Zero-key params (BVA min)
	my $r0 = Object::Configure::configure($VALID_CLASS, {});
	ok(ref($r0) eq 'HASH', 'Combinatorial BVA-min: zero-key params works');

	# One-key params (BVA min+1)
	my $r1 = Object::Configure::configure($VALID_CLASS, { timeout => 30 });
	ok($r1->{timeout} == 30, 'Combinatorial BVA-min+1: single-key params passes through');
};

done_testing();
