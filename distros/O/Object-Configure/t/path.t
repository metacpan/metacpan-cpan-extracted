#!/usr/bin/env perl

# t/path.t — Control Flow Graph (CFG) path coverage for Object::Configure.
#
# For every public and private function, each uniquely identifiable execution
# path (guard exits, loop bodies, conditional branches) gets its own subtest.
# Tests are organised by function, then by path ID (PA, PB, ... for guards;
# numeric suffix for branch arms).
#
# Naming convention:  PATH <function>/<path-id>: <description>

use strict;
use warnings;
use Test::Most;
use Test::Mockingbird 0.10;
use File::Temp   qw(tempdir tempfile);
use File::Spec;
use Scalar::Util qw(blessed isweak weaken);
use Readonly;
use POSIX        qw(WNOHANG);

use lib '/home/njh/src/njh/Test-Returns/lib';
use Test::Returns;

BEGIN { use_ok('Object::Configure') }

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------
Readonly my $VALID_CLASS    => 'Path::Test::Class';
Readonly my $EMPTY_MSG      => qr/what class do you want to configure/i;
Readonly my $INVALID_MSG    => qr/invalid class name/i;
Readonly my $TRAVERSAL_MSG  => qr/path traversal/i;
Readonly my $USAGE_MSG      => qr/Usage/i;
Readonly my $WARNING_MSG    => qr/Can't load configuration/i;

# Locale-safe EACCES string
use Errno qw(EACCES);
my $EACCES_STR; { local $! = EACCES; $EACCES_STR = "$!"; }

sub make_config {
	my ($dir, $name, $yaml) = @_;
	my $p = File::Spec->catfile($dir, $name);
	open my $fh, '>', $p or die "Cannot write $p: $!";
	print $fh $yaml;
	close $fh;
	return $p;
}

# =============================================================================
# FUNCTION: configure()
# =============================================================================

# -----------------------------------------------------------------------------
# PATH configure/PA — guard: undef or empty class → croak "what class"
# -----------------------------------------------------------------------------
subtest 'PATH configure/PA: undef class → early croak' => sub {
	plan tests => 2;
	throws_ok { Object::Configure::configure(undef, {}) }
		$EMPTY_MSG, 'PA-1: undef class rejected before any other work';
	throws_ok { Object::Configure::configure('', {}) }
		$EMPTY_MSG, 'PA-2: empty string class rejected';
};

# -----------------------------------------------------------------------------
# PATH configure/PB — guard: invalid package name → croak "invalid class name"
# -----------------------------------------------------------------------------
subtest 'PATH configure/PB: invalid class name → croak' => sub {
	plan tests => 3;
	throws_ok { Object::Configure::configure('1Bad',     {}) } $INVALID_MSG, 'PB-1: digit-first';
	throws_ok { Object::Configure::configure("Foo\nBar", {}) } $INVALID_MSG, 'PB-2: newline';
	throws_ok { Object::Configure::configure('Foo::',    {}) } $INVALID_MSG, 'PB-3: trailing ::';
};

# -----------------------------------------------------------------------------
# PATH configure/PC — guard: config_file with traversal → croak
# -----------------------------------------------------------------------------
subtest 'PATH configure/PC: config_file traversal → croak' => sub {
	plan tests => 2;
	throws_ok {
		Object::Configure::configure($VALID_CLASS, { config_file => '../etc/passwd' });
	} $TRAVERSAL_MSG, 'PC-1: leading ../';
	throws_ok {
		Object::Configure::configure($VALID_CLASS, { config_file => 'foo/../bar' });
	} $TRAVERSAL_MSG, 'PC-2: embedded /..';
};

# -----------------------------------------------------------------------------
# PATH configure/PD — guard: config_file truthy + no config_dirs + not readable
#                     → croak with OS error (locale-safe)
# -----------------------------------------------------------------------------
subtest 'PATH configure/PD: unreadable config_file without dirs → croak' => sub {
	plan tests => 1;
	my $temp = tempdir(CLEANUP => 1);
	my $fake = File::Spec->catfile($temp, 'no-such-file.yml');
	# File does not exist; -r returns false; no config_dirs → croak
	throws_ok {
		Object::Configure::configure($VALID_CLASS, { config_file => $fake });
	} qr/no-such-file/, 'PD: missing file without dirs → croak with filename in message';
};

# -----------------------------------------------------------------------------
# PATH configure/PE — no config_file: env-only branch (Config::Abstraction via env)
# -----------------------------------------------------------------------------
subtest 'PATH configure/PE: no config_file → env-only branch executes' => sub {
	plan tests => 2;

	# Set an env var that configure() would pick up via the env_prefix branch.
	# Env prefix for class Path::Test::Class → Path__Test__Class__
	local $ENV{'Path__Test__Class__pe_key'} = 'pe_value';

	my $r = Object::Configure::configure($VALID_CLASS, {});
	ok(ref($r) eq 'HASH', 'PE: env-only branch returns hashref');
	is($r->{pe_key}, 'pe_value', 'PE: env var propagated into result via env-only branch');
};

# -----------------------------------------------------------------------------
# PATH configure/PF — config_file readable directly → primary file loaded
#                     (file merge branch, no fallback scan needed)
# -----------------------------------------------------------------------------
subtest 'PATH configure/PF: config_file readable → primary-file merge branch' => sub {
	plan tests => 3;
	my $temp = tempdir(CLEANUP => 1);
	my $path = make_config($temp, 'path-test-class.yml',
		"---\nPath__Test__Class:\n  pf_key: pf_value\n");

	my $r = Object::Configure::configure($VALID_CLASS, { config_file => $path });
	ok(ref($r) eq 'HASH',         'PF: file-merge branch returns hashref');
	is($r->{pf_key}, 'pf_value',  'PF: value loaded from primary config file');
	is($r->{_config_file}, $path, 'PF: _config_file set to the supplied path');
};

# -----------------------------------------------------------------------------
# PATH configure/PG — config_file given but not directly readable;
#                     fallback scan through config_dirs finds it
# -----------------------------------------------------------------------------
subtest 'PATH configure/PG: config_file in config_dirs → fallback dir scan' => sub {
	plan tests => 2;
	my $temp = tempdir(CLEANUP => 1);
	make_config($temp, 'path-test-class.yml',
		"---\nPath__Test__Class:\n  pg_key: pg_value\n");

	# Pass a bare filename (not absolute) so the initial -r fails, then dirs are scanned
	my $r = Object::Configure::configure($VALID_CLASS, {
		config_file => 'path-test-class.yml',
		config_dirs => [$temp],
	});
	ok(ref($r) eq 'HASH',        'PG: fallback dir scan succeeds, returns hashref');
	is($r->{pg_key}, 'pg_value', 'PG: value from file found via dir scan');
};

# -----------------------------------------------------------------------------
# PATH configure/PH — config_file given, not readable, config_dirs supplied
#                     but no match found → @config_files_to_load stays empty
#                     → env-only elsif branch runs (or neither branch)
# -----------------------------------------------------------------------------
subtest 'PATH configure/PH: config_file missing in all dirs → empty load list' => sub {
	plan tests => 1;
	my $temp = tempdir(CLEANUP => 1);
	# Dir exists but the file 'ghost.yml' is not there
	my $r = Object::Configure::configure($VALID_CLASS, {
		config_file => 'ghost.yml',
		config_dirs => [$temp],
	});
	ok(ref($r) eq 'HASH', 'PH: empty load list path completes without croak');
};

# -----------------------------------------------------------------------------
# PATH configure/PI — ancestor config files discovered (inheritance chain path)
# -----------------------------------------------------------------------------
subtest 'PATH configure/PI: ancestor file found → inheritance merge' => sub {
	plan tests => 3;
	my $temp = tempdir(CLEANUP => 1);

	# Parent class config
	make_config($temp, 'path-base-class.yml',
		"---\nPath__Base__Class:\n  base_key: from_base\n  shared: base\n");

	# Child class config
	my $child_cfg = make_config($temp, 'path-child-class.yml',
		"---\nPath__Child__Class:\n  child_key: from_child\n  shared: child\n");

	# Establish inheritance
	{ no strict 'refs'; @{'Path::Child::Class::ISA'} = ('Path::Base::Class'); }

	my $r = Object::Configure::configure('Path::Child::Class', {
		config_file => $child_cfg,
		config_dirs => [$temp],
	});

	is($r->{child_key}, 'from_child', 'PI: child-class key present');
	is($r->{base_key},  'from_base',  'PI: ancestor key inherited');
	is($r->{shared},    'child',      'PI: child overrides ancestor on collision');
};

# -----------------------------------------------------------------------------
# PATH configure/PJ — Config::Abstraction::new returns falsy in file merge loop
#                     AND $@ is set → carp warning emitted
# -----------------------------------------------------------------------------
subtest 'PATH configure/PJ: Config::Abstraction fails in merge loop → carp' => sub {
	plan tests => 2;
	my $temp = tempdir(CLEANUP => 1);
	my $path = make_config($temp, 'path-test-class.yml', "---\n");

	# Override C::A::new directly via the symbol table so no intermediate eval can
	# clear $@ before configure() inspects it.  Test::Mockingbird wraps mocks in
	# eval, which resets $@; direct glob manipulation does not.
	my $warned = '';
	local $SIG{__WARN__} = sub { $warned .= $_[0] };

	{
		no warnings 'redefine';
		local *Config::Abstraction::new = sub {
			$@ = 'injected C::A failure';
			return 0;
		};
		Object::Configure::configure($VALID_CLASS, { config_file => $path });
	}

	like($warned, $WARNING_MSG,           'PJ: carp warning emitted when C::A returns false');
	like($warned, qr/injected C::A failure/, 'PJ: warning includes $@ detail');
};

# -----------------------------------------------------------------------------
# PATH configure/PK — arrayref logger stash: $array_logger wins post-merge
# -----------------------------------------------------------------------------
subtest 'PATH configure/PK: arrayref logger stashed before merge → survives' => sub {
	plan tests => 3;
	my @log;
	my $r = Object::Configure::configure($VALID_CLASS, { logger => \@log });

	ok(blessed($r->{logger}) && $r->{logger}->isa('Log::Abstraction'),
		'PK: logger is a Log::Abstraction instance (arrayref spec wrapped)');
	# The array ref should be the same object (identity preserved via stash)
	is(ref($r->{logger}{array}), 'ARRAY', 'PK: Log::Abstraction backed by an array');
	$r->{logger}->warn('pk_test');
	ok(@log > 0, 'PK: log entry captured into caller array after stash-restore');
};

# -----------------------------------------------------------------------------
# PATH configure/PL — coderef stash: blessed/CODE values stashed, not merged
# -----------------------------------------------------------------------------
subtest 'PATH configure/PL: coderef and blessed obj stashed, not corrupted' => sub {
	plan tests => 3;
	my $cb_fired = 0;
	my $cb = sub { $cb_fired++ };
	my $ctx = bless { role => 'tester' }, 'Path::Context';

	my $r = Object::Configure::configure($VALID_CLASS, {
		on_event => $cb,
		context  => $ctx,
	});

	is(ref($r->{on_event}), 'CODE', 'PL: coderef re-attached after stash');
	$r->{on_event}->();
	is($cb_fired, 1, 'PL: stashed coderef is callable');
	is($r->{context}, $ctx, 'PL: blessed object identity preserved through stash');
};

# -----------------------------------------------------------------------------
# PATH configure/PM — _config_file already set in params → not overwritten
# -----------------------------------------------------------------------------
subtest 'PATH configure/PM: pre-existing _config_file key not overwritten' => sub {
	plan tests => 1;
	my $temp = tempdir(CLEANUP => 1);
	my $path = make_config($temp, 'path-test-class.yml', "---\n");

	my $r = Object::Configure::configure($VALID_CLASS, {
		config_file  => $path,
		_config_file => '/pre/existing/path.yml',   # must NOT be overwritten
	});

	is($r->{_config_file}, '/pre/existing/path.yml',
		'PM: _config_file pre-existing value preserved (exists guard fires)');
};

# -----------------------------------------------------------------------------
# PATH configure/PN — _config_files already set in params → not overwritten
# -----------------------------------------------------------------------------
subtest 'PATH configure/PN: pre-existing _config_files key not overwritten' => sub {
	plan tests => 1;
	my $temp = tempdir(CLEANUP => 1);
	my $path = make_config($temp, 'path-test-class.yml', "---\n");
	my @sentinel = ('/sentinel/files.yml');

	my $r = Object::Configure::configure($VALID_CLASS, {
		config_file   => $path,
		_config_files => \@sentinel,
	});

	is_deeply($r->{_config_files}, \@sentinel,
		'PN: _config_files pre-existing value preserved (exists guard fires)');
};

# -----------------------------------------------------------------------------
# PATH configure/PO — config_path set in env-only result + -f file → stat stored
# -----------------------------------------------------------------------------
subtest 'PATH configure/PO: config_path in result + file exists → stat tracked' => sub {
	plan tests => 2;
	my $temp = tempdir(CLEANUP => 1);

	# Create a real file to serve as config_path
	my $cfg_path = make_config($temp, 'po-config.yml', "---\n");

	# Set env var so the env-only branch picks up config_path
	# Env prefix for class Path::Test::Class: Path__Test__Class__
	local $ENV{'Path__Test__Class__config_path'} = $cfg_path;

	my %stats_before = %Object::Configure::_config_file_stats;
	Object::Configure::configure($VALID_CLASS, {});
	my %stats_after  = %Object::Configure::_config_file_stats;

	my $new_key = (grep { !exists $stats_before{$_} } keys %stats_after)[0];
	ok(defined $new_key, 'PO: new entry added to %_config_file_stats');
	is($new_key, $cfg_path, 'PO: the entry key matches the config_path file');
};

# =============================================================================
# FUNCTION: _build_logger()
# =============================================================================

# Six distinct paths through _build_logger.
subtest 'PATH _build_logger: all 6 spec-type paths' => sub {
	plan tests => 6;

	# Path 1: undef → default Log::Abstraction
	my $r1 = Object::Configure::_build_logger(undef, 0);
	ok(blessed($r1) && $r1->isa('Log::Abstraction'),
		'_build_logger path 1: undef spec → default Log::Abstraction');

	# Path 2: 'NULL' string → passthrough
	my $r2 = Object::Configure::_build_logger('NULL', 0);
	is($r2, 'NULL', '_build_logger path 2: "NULL" string passes through');

	# Path 3: existing Log::Abstraction → identity passthrough
	my $existing = Log::Abstraction->new();
	my $r3 = Object::Configure::_build_logger($existing, 0);
	is($r3, $existing, '_build_logger path 3: existing L::A passes through unchanged');

	# Path 4: arrayref → L::A with array backend
	my @arr;
	my $r4 = Object::Configure::_build_logger(\@arr, 0);
	ok(blessed($r4) && $r4->isa('Log::Abstraction'),
		'_build_logger path 4: arrayref → L::A with array backend');

	# Path 5: hashref → L::A from hash options
	my $r5 = Object::Configure::_build_logger({ level => 'notice' }, 0);
	ok(blessed($r5) && $r5->isa('Log::Abstraction'),
		'_build_logger path 5: hashref spec → L::A from options');

	# Path 6: scalar string → L::A with logger => scalar
	my $r6 = Object::Configure::_build_logger('my_logger', 0);
	ok(blessed($r6) && $r6->isa('Log::Abstraction'),
		'_build_logger path 6: scalar string → L::A wrapping it');
};

# =============================================================================
# FUNCTION: _get_inheritance_chain()
# =============================================================================

subtest 'PATH _get_inheritance_chain/cache-miss: UNIVERSAL absent → appended' => sub {
	plan tests => 3;
	delete $Object::Configure::_chain_cache{'GIC::Fresh'};
	my @chain = Object::Configure::_get_inheritance_chain('GIC::Fresh');
	is($chain[0],  'UNIVERSAL', 'cache-miss: UNIVERSAL prepended (base-first)');
	is($chain[-1], 'GIC::Fresh', 'cache-miss: class is last element');
	my @u = grep { $_ eq 'UNIVERSAL' } @chain;
	is(scalar @u, 1, 'cache-miss: UNIVERSAL appears exactly once');
};

subtest 'PATH _get_inheritance_chain/cache-hit: returns list copy from cache' => sub {
	plan tests => 3;
	delete $Object::Configure::_chain_cache{'GIC::Cached'};
	# Warm the cache
	my @first  = Object::Configure::_get_inheritance_chain('GIC::Cached');
	my @second = Object::Configure::_get_inheritance_chain('GIC::Cached');

	is_deeply(\@first, \@second, 'cache-hit: same chain returned');

	# Mutating the returned list must NOT corrupt the cache
	push @second, 'Injected';
	my @third = Object::Configure::_get_inheritance_chain('GIC::Cached');
	is(scalar(@third), scalar(@first),
		'cache-hit: mutation of returned list does not corrupt cached copy');
	ok(! grep { $_ eq 'Injected' } @third,
		'cache-hit: injected element absent from subsequent call');
};

subtest 'PATH _get_inheritance_chain/UNIVERSAL in MRO: not duplicated' => sub {
	plan tests => 1;
	# Force UNIVERSAL into @ISA to simulate a class that explicitly lists it
	delete $Object::Configure::_chain_cache{'GIC::ExplicitUniversal'};
	{ no strict 'refs'; @{'GIC::ExplicitUniversal::ISA'} = ('UNIVERSAL'); }
	my @chain = Object::Configure::_get_inheritance_chain('GIC::ExplicitUniversal');
	my @u = grep { $_ eq 'UNIVERSAL' } @chain;
	is(scalar @u, 1, 'UNIVERSAL-in-MRO: not duplicated even when already present');
};

# =============================================================================
# FUNCTION: _find_class_config_file()
# =============================================================================

subtest 'PATH _find_class_config_file/cache-hit: second call skips all I/O' => sub {
	plan tests => 3;
	my $temp = tempdir(CLEANUP => 1);
	make_config($temp, 'fcc-test.yml', "---\n");

	%Object::Configure::_find_cache = ();
	my $r1 = Object::Configure::_find_class_config_file('Fcc::Test', 'fcc-test.yml', [$temp]);
	ok(defined $r1, 'fcc cache-miss: file found on first call');

	my $r2 = Object::Configure::_find_class_config_file('Fcc::Test', 'fcc-test.yml', [$temp]);
	is($r1, $r2, 'fcc cache-hit: second call returns identical path');

	# Verify cache has exactly one entry for this key
	my $cache_key = join("\0", 'Fcc::Test', 'fcc-test.yml', $temp);
	ok(exists $Object::Configure::_find_cache{$cache_key},
		'fcc: cache entry keyed correctly');
};

subtest 'PATH _find_class_config_file/found-in-basedir: primary dir search' => sub {
	plan tests => 2;
	my $temp = tempdir(CLEANUP => 1);
	my $path = make_config($temp, 'fcc-basedir.yml', "---\n");
	# Base dir is derived from the $base_config_file argument's directory.
	%Object::Configure::_find_cache = ();
	my $found = Object::Configure::_find_class_config_file(
		'Fcc::Basedir', $path, undef
	);
	# 'Fcc::Basedir' → 'fcc-basedir.yml' — should find the same file in base_dir
	ok(defined $found, 'found-in-basedir: file found in primary dir');
	like($found, qr/fcc-basedir/, 'found-in-basedir: found path contains expected filename');
};

subtest 'PATH _find_class_config_file/found-in-configdirs: fallback dir scan' => sub {
	plan tests => 2;
	my $primary_dir = tempdir(CLEANUP => 1);
	my $search_dir  = tempdir(CLEANUP => 1);
	make_config($search_dir, 'fcc-indir.yml', "---\n");

	# Primary dir does NOT have fcc-indir.yml — only search_dir does
	my $base_file = File::Spec->catfile($primary_dir, 'dummy.yml');
	%Object::Configure::_find_cache = ();
	my $found = Object::Configure::_find_class_config_file(
		'Fcc::Indir', $base_file, [$search_dir]
	);
	ok(defined $found, 'found-in-configdirs: file found via config_dirs scan');
	like($found, qr/fcc-indir/, 'found-in-configdirs: correct file found');
};

subtest 'PATH _find_class_config_file/not-found: undef cached as sentinel' => sub {
	plan tests => 2;
	my $temp = tempdir(CLEANUP => 1);
	%Object::Configure::_find_cache = ();
	my $r = Object::Configure::_find_class_config_file(
		'Fcc::NoSuch', 'nosuch.yml', [$temp]
	);
	ok(!defined $r, 'not-found: returns undef');
	my $key = join("\0", 'Fcc::NoSuch', 'nosuch.yml', $temp);
	ok(exists $Object::Configure::_find_cache{$key},
		'not-found: undef sentinel cached (use exists, not defined)');
};

# =============================================================================
# FUNCTION: _deep_merge()
# =============================================================================

subtest 'PATH _deep_merge: all 5 branch paths' => sub {
	plan tests => 6;

	# Path 1: base not HASH → return overlay immediately (first guard)
	is(Object::Configure::_deep_merge('scalar', { x => 1 })->{x}, 1,
		'dm-P1: base=scalar → overlay hashref returned');

	# Path 2: base HASH, overlay not HASH → return overlay immediately (second guard)
	is(Object::Configure::_deep_merge({ a => 1 }, 'replaced'), 'replaced',
		'dm-P2: overlay=scalar → scalar returned (overlay wins)');

	# Path 3: both HASH, disjoint keys → union (no recursion)
	my $r3 = Object::Configure::_deep_merge({ a => 1 }, { b => 2 });
	is_deeply($r3, { a => 1, b => 2 }, 'dm-P3: both HASH disjoint → union');

	# Path 4: both HASH, overlapping key: both subhashes → recursive merge
	my $r4 = Object::Configure::_deep_merge(
		{ x => { a => 1, b => 2 } },
		{ x => { b => 99, c => 3 } },
	);
	is($r4->{x}{a}, 1,  'dm-P4: recursive: base sub-key preserved');
	is($r4->{x}{b}, 99, 'dm-P4: recursive: overlay sub-key wins');
	is($r4->{x}{c}, 3,  'dm-P4: recursive: new overlay sub-key added');
};

subtest 'PATH _deep_merge: overlapping key — overlay not sub-hash (direct assign)' => sub {
	plan tests => 1;
	# Path 5: base has hashref for key, overlay has non-hash → overlay replaces entirely
	my $r = Object::Configure::_deep_merge(
		{ key => { nested => 1 } },
		{ key => 'flat_override' },
	);
	is($r->{key}, 'flat_override',
		'dm-P5: overlay non-hash replaces base hashref entirely (no merge)');
};

# =============================================================================
# FUNCTION: register_object()
# =============================================================================

subtest 'PATH register_object/PA: undef args → croak' => sub {
	plan tests => 3;
	my $obj = bless {}, 'Reg::Test';
	throws_ok { Object::Configure::register_object(undef, $obj) }  $USAGE_MSG, 'reg PA-1: undef class';
	throws_ok { Object::Configure::register_object('Reg::Test', undef) } $USAGE_MSG, 'reg PA-2: undef obj';
	throws_ok { Object::Configure::register_object(undef, undef) }  $USAGE_MSG, 'reg PA-3: both undef';
};

subtest 'PATH register_object/P1: first call installs SIGUSR1 handler' => sub {
	plan tests => 2;
	SKIP: {
		skip 'Signal tests not applicable on Windows', 2 if $^O eq 'MSWin32';

		# Reset handler state so this call is the "first" install
		Object::Configure::restore_signal_handlers();
		$Object::Configure::_original_usr1_handler = undef;
		delete $Object::Configure::_object_registry{'Reg::First'};

		my $obj = bless {}, 'Reg::First';
		Object::Configure::register_object('Reg::First', $obj);

		ok(defined $Object::Configure::_original_usr1_handler,
			'P1: $_original_usr1_handler set on first call');
		ok(ref($SIG{USR1}) eq 'CODE',
			'P1: $SIG{USR1} is now a coderef installed by register_object');

		# Cleanup
		delete $Object::Configure::_object_registry{'Reg::First'};
		Object::Configure::restore_signal_handlers();
	}
};

subtest 'PATH register_object/P2: subsequent call skips handler install' => sub {
	plan tests => 2;
	SKIP: {
		skip 'Signal tests not applicable on Windows', 2 if $^O eq 'MSWin32';

		Object::Configure::restore_signal_handlers();
		$Object::Configure::_original_usr1_handler = undef;

		my $obj1 = bless {}, 'Reg::Sub';
		Object::Configure::register_object('Reg::Sub', $obj1);
		my $h1 = $SIG{USR1};   # capture handler after first install

		my $obj2 = bless {}, 'Reg::Sub';
		Object::Configure::register_object('Reg::Sub', $obj2);
		my $h2 = $SIG{USR1};   # handler after second call

		is($h1, $h2, 'P2: handler not reinstalled on subsequent call (same ref)');
		my @reg = @{ $Object::Configure::_object_registry{'Reg::Sub'} };
		is(scalar(@reg), 2, 'P2: both objects pushed to registry');

		delete $Object::Configure::_object_registry{'Reg::Sub'};
		Object::Configure::restore_signal_handlers();
	}
};

subtest 'PATH register_object/P3: signal handler chains to prior CODE handler' => sub {
	plan tests => 2;
	SKIP: {
		skip 'Signal tests not applicable on Windows', 2 if $^O eq 'MSWin32';

		Object::Configure::restore_signal_handlers();
		$Object::Configure::_original_usr1_handler = undef;

		# Install a prior CODE handler before register_object
		my $prior_fired = 0;
		$SIG{USR1} = sub { $prior_fired++ };

		my $obj = bless { _config_files => [] }, 'Reg::Chain';
		Object::Configure::register_object('Reg::Chain', $obj);

		# Fire the installed handler to verify chaining
		$SIG{USR1}->();

		ok($prior_fired, 'P3: prior CODE handler chained and called by USR1 handler');
		ok(ref($Object::Configure::_original_usr1_handler) eq 'CODE',
			'P3: saved original handler is the CODE ref we installed');

		delete $Object::Configure::_object_registry{'Reg::Chain'};
		Object::Configure::restore_signal_handlers();
	}
};

subtest 'PATH register_object/P4: IGNORE handler — no chain call, no carp' => sub {
	plan tests => 1;
	SKIP: {
		skip 'Signal tests not applicable on Windows', 1 if $^O eq 'MSWin32';

		Object::Configure::restore_signal_handlers();
		$Object::Configure::_original_usr1_handler = undef;

		$SIG{USR1} = 'IGNORE';
		my $obj = bless { _config_files => [] }, 'Reg::Ignore';
		Object::Configure::register_object('Reg::Ignore', $obj);

		my $warned = '';
		local $SIG{__WARN__} = sub { $warned .= $_[0] };

		lives_ok { $SIG{USR1}->() }
			'P4: IGNORE prior handler → no croak, no carp, handler body runs cleanly';

		delete $Object::Configure::_object_registry{'Reg::Ignore'};
		Object::Configure::restore_signal_handlers();
	}
};

subtest 'PATH register_object/P5: unknown string handler → carp in signal handler' => sub {
	plan tests => 2;
	SKIP: {
		skip 'Signal tests not applicable on Windows', 2 if $^O eq 'MSWin32';

		Object::Configure::restore_signal_handlers();
		$Object::Configure::_original_usr1_handler = undef;

		$SIG{USR1} = 'PIPE';    # neither CODE, DEFAULT, nor IGNORE
		my $obj = bless { _config_files => [] }, 'Reg::Unknown';
		Object::Configure::register_object('Reg::Unknown', $obj);

		my $warned = '';
		local $SIG{__WARN__} = sub { $warned .= $_[0] };

		$SIG{USR1}->();

		like($warned, qr/Cannot chain/, 'P5: unknown handler → "Cannot chain" carp emitted');
		like($warned, qr/PIPE/, 'P5: unknown handler name included in carp message');

		delete $Object::Configure::_object_registry{'Reg::Unknown'};
		Object::Configure::restore_signal_handlers();
	}
};

# =============================================================================
# FUNCTION: restore_signal_handlers()
# =============================================================================

subtest 'PATH restore_signal_handlers/P1: handler defined → restored' => sub {
	plan tests => 2;
	SKIP: {
		skip 'Signal tests not applicable on Windows', 2 if $^O eq 'MSWin32';

		$Object::Configure::_original_usr1_handler = 'DEFAULT';
		Object::Configure::restore_signal_handlers();
		ok(!defined $Object::Configure::_original_usr1_handler,
			'restore P1: $_original_usr1_handler cleared after restore');
		is($SIG{USR1}, 'DEFAULT', 'restore P1: $SIG{USR1} restored to saved value');
	}
};

subtest 'PATH restore_signal_handlers/P2: handler not defined → no-op' => sub {
	plan tests => 1;
	$Object::Configure::_original_usr1_handler = undef;
	lives_ok { Object::Configure::restore_signal_handlers() }
		'restore P2: undef handler → no-op, no croak';
};

# =============================================================================
# FUNCTION: reload_config()
# =============================================================================

subtest 'PATH reload_config/P1: empty registry → return 0' => sub {
	plan tests => 1;
	local %Object::Configure::_object_registry = ();
	my $count = Object::Configure::reload_config();
	is($count, 0, 'reload P1: empty registry → 0 objects reloaded');
};

subtest 'PATH reload_config/P2: live object → reload succeeds, count=1' => sub {
	plan tests => 2;
	my $temp = tempdir(CLEANUP => 1);
	my $path = make_config($temp, 'reload-live.yml',
		"---\nReload__Live__Class:\n  live_key: live_value\n");

	my $r = Object::Configure::configure('Reload::Live::Class', { config_file => $path });
	my $obj = bless $r, 'Reload::Live::Class';

	local %Object::Configure::_object_registry = ();
	Object::Configure::register_object('Reload::Live::Class', $obj);
	Object::Configure::restore_signal_handlers();   # don't leave SIGUSR1 installed

	my $count = Object::Configure::reload_config();
	ok($count >= 1, 'reload P2: live object → count >= 1');
	is($obj->{live_key}, 'live_value', 'reload P2: object value intact after reload');
};

subtest 'PATH reload_config/P3: dead weak ref → pruned, class key deleted' => sub {
	plan tests => 2;
	local %Object::Configure::_object_registry = ();

	# Create and register an object, then let it go out of scope
	{
		my $temp = tempdir(CLEANUP => 1);
		my $path = make_config($temp, 'reload-dead.yml', "---\n");
		my $r = Object::Configure::configure('Reload::Dead::Class', { config_file => $path });
		my $obj = bless $r, 'Reload::Dead::Class';
		Object::Configure::register_object('Reload::Dead::Class', $obj);
		Object::Configure::restore_signal_handlers();
		# $obj goes out of scope here; weak ref becomes undef
	}

	my $count = Object::Configure::reload_config();
	is($count, 0, 'reload P3: dead ref → 0 objects reloaded');
	ok(!exists $Object::Configure::_object_registry{'Reload::Dead::Class'},
		'reload P3: class key deleted from registry after all refs are dead');
};

subtest 'PATH reload_config/P4: _reload_object_config throws → carp, no count bump' => sub {
	plan tests => 2;
	my $temp = tempdir(CLEANUP => 1);
	my $path = make_config($temp, 'reload-throw.yml', "---\n");

	my $r = Object::Configure::configure('Reload::Throw::Class', { config_file => $path });
	my $obj = bless $r, 'Reload::Throw::Class';

	local %Object::Configure::_object_registry = ();
	Object::Configure::register_object('Reload::Throw::Class', $obj);
	Object::Configure::restore_signal_handlers();

	# Override _reload_object_config in the symbol table so the eval+carp branch fires.
	# Test::Mockingbird does not reliably intercept same-package internal sub calls
	# because the compiled call site may hold a direct reference to the original CV.
	my $warned = '';
	local $SIG{__WARN__} = sub { $warned .= $_[0] };
	my $count;
	{
		no warnings 'redefine';
		local *Object::Configure::_reload_object_config = sub {
			die "injected reload error\n";
		};
		$count = Object::Configure::reload_config();
	}

	is($count, 0, 'reload P4: exception in reload → count not incremented');
	like($warned, qr/Failed to reload config/, 'reload P4: carp warning emitted');
};

# =============================================================================
# FUNCTION: disable_hot_reload()
# =============================================================================

subtest 'PATH disable_hot_reload/P1: no watcher → no-op' => sub {
	plan tests => 1;
	%Object::Configure::_config_watchers = ();
	lives_ok { Object::Configure::disable_hot_reload() }
		'disable P1: no active watcher → no-op, no croak';
};

subtest 'PATH disable_hot_reload/P2: invalid PID (pid=1) → kill skipped, state cleared' => sub {
	plan tests => 2;
	# Manually inject pid=1 (init) — the PID guard must NOT call kill()
	%Object::Configure::_config_watchers = (pid => 1);

	lives_ok { Object::Configure::disable_hot_reload() }
		'disable P2: pid=1 → no croak (kill guard fires)';
	ok(!%Object::Configure::_config_watchers,
		'disable P2: state cleared even when kill was skipped');
};

subtest 'PATH disable_hot_reload/P3: pid=$$ (self) → kill skipped, state cleared' => sub {
	plan tests => 2;
	%Object::Configure::_config_watchers = (pid => $$);

	lives_ok { Object::Configure::disable_hot_reload() }
		'disable P3: pid=$$ → no croak (self-signal guard fires)';
	ok(!%Object::Configure::_config_watchers,
		'disable P3: state cleared even when kill was skipped');
};

subtest 'PATH disable_hot_reload/P4: valid PID → child terminated, state cleared' => sub {
	plan tests => 2;
	SKIP: {
		skip 'Fork not applicable on Windows', 2 if $^O eq 'MSWin32';

		%Object::Configure::_config_watchers = ();
		my $pid = Object::Configure::enable_hot_reload(interval => 60);
		ok($pid > 0, 'disable P4 setup: watcher forked');
		Object::Configure::disable_hot_reload();
		ok(!%Object::Configure::_config_watchers,
			'disable P4: config_watchers cleared after clean shutdown');
	}
};

# =============================================================================
# FUNCTION: _reload_object_config()
# =============================================================================

subtest 'PATH _reload_object_config/PA: not blessed → early return' => sub {
	plan tests => 1;
	# Passing an unblessed hashref; function must return without doing anything
	my $h = { _config_file => '/fake/path' };
	lives_ok { Object::Configure::_reload_object_config($h) }
		'roc PA: unblessed ref → early return, no croak';
};

subtest 'PATH _reload_object_config/PB: traversal in _config_file → carp, return' => sub {
	plan tests => 2;
	my $obj = bless { _config_file => '../../etc/passwd' }, 'Roc::Traversal';

	my $warned = '';
	local $SIG{__WARN__} = sub { $warned .= $_[0] };
	Object::Configure::_reload_object_config($obj);

	like($warned, qr/traversal/, 'roc PB: traversal path → carp with "traversal"');
	# Object is not modified (carp+return before any I/O)
	is($obj->{_config_file}, '../../etc/passwd', 'roc PB: object not modified');
};

subtest 'PATH _reload_object_config/PC: no config file key → early return' => sub {
	plan tests => 1;
	my $obj = bless { key => 'val' }, 'Roc::NoFile';
	lives_ok { Object::Configure::_reload_object_config($obj) }
		'roc PC: no _config_file → early return, no croak';
};

subtest 'PATH _reload_object_config/PD: config_file does not exist → early return' => sub {
	plan tests => 1;
	my $obj = bless { _config_file => '/nonexistent/path/file.yml' }, 'Roc::Gone';
	lives_ok { Object::Configure::_reload_object_config($obj) }
		'roc PD: file not on disk → early return, no croak';
};

subtest 'PATH _reload_object_config/PE: private key (starts with _) → skipped' => sub {
	plan tests => 2;
	my $temp = tempdir(CLEANUP => 1);
	# Config file sets a key starting with _ — must be ignored
	my $path = make_config($temp, 'roc-private.yml',
		"---\nRoc__Private__Class:\n  _secret: new_value\n  public: updated\n");

	my $obj = bless {
		_config_file => $path,
		_secret      => 'original',
		public       => 'old',
	}, 'Roc::Private::Class';

	Object::Configure::_reload_object_config($obj);

	is($obj->{_secret}, 'original', 'roc PE: private key (_secret) not overwritten');
	is($obj->{public},  'updated',  'roc PE: public key updated from config');
};

subtest 'PATH _reload_object_config/PF: logger key with NULL → direct assign' => sub {
	plan tests => 1;
	my $temp = tempdir(CLEANUP => 1);
	my $path = make_config($temp, 'roc-lognull.yml',
		"---\nRoc__Lognull__Class:\n  logger: 'NULL'\n");

	my $obj = bless { _config_file => $path, logger => 'prior' }, 'Roc::Lognull::Class';
	Object::Configure::_reload_object_config($obj);
	is($obj->{logger}, 'NULL', 'roc PF: logger=NULL in config → direct assign (no wrapping)');
};

subtest 'PATH _reload_object_config/PG: logger key with spec → _reconfigure_logger' => sub {
	plan tests => 1;
	my $temp = tempdir(CLEANUP => 1);
	my $path = make_config($temp, 'roc-logspec.yml',
		"---\nRoc__Logspec__Class:\n  logger:\n    level: notice\n");

	my $obj = bless { _config_file => $path }, 'Roc::Logspec::Class';
	Object::Configure::_reload_object_config($obj);
	ok(blessed($obj->{logger}) && $obj->{logger}->isa('Log::Abstraction'),
		'roc PG: logger hashref spec → _reconfigure_logger creates Log::Abstraction');
};

subtest 'PATH _reload_object_config/PH: _on_config_reload callback invoked' => sub {
	plan tests => 2;
	my $temp = tempdir(CLEANUP => 1);
	my $path = make_config($temp, 'roc-callback.yml',
		"---\nRoc__Callback__Class:\n  val: refreshed\n");

	my $hook_called = 0;
	my $obj = bless {
		_config_file => $path,
		val          => 'old',
	}, 'Roc::Callback::Class';

	# Install _on_config_reload method on the fly
	{ no strict 'refs'; *{'Roc::Callback::Class::_on_config_reload'} = sub { $hook_called++ }; }

	Object::Configure::_reload_object_config($obj);

	is($obj->{val}, 'refreshed', 'roc PH: object updated from config');
	is($hook_called, 1, 'roc PH: _on_config_reload hook called exactly once');
};

# =============================================================================
# FUNCTION: instantiate()
# =============================================================================

subtest 'PATH instantiate: no _config_file → register_object NOT called' => sub {
	plan tests => 2;
	# A class that has new() but no config file → register_object skipped
	package Inst::NoConfig;
	sub new { my ($c, $p) = @_; bless { %$p }, $c }
	package main;

	local %Object::Configure::_object_registry = ();
	my $obj = Object::Configure::instantiate(class => 'Inst::NoConfig');
	ok(blessed($obj) && $obj->isa('Inst::NoConfig'),
		'instantiate: object created without config file');
	ok(!exists $Object::Configure::_object_registry{'Inst::NoConfig'},
		'instantiate: register_object NOT called when no _config_file');
};

subtest 'PATH instantiate: with _config_file → register_object called' => sub {
	plan tests => 2;
	my $temp = tempdir(CLEANUP => 1);
	my $path = make_config($temp, 'inst-config.yml', "---\n");

	package Inst::WithConfig;
	sub new { my ($c, $p) = @_; bless { %$p }, $c }
	package main;

	local %Object::Configure::_object_registry = ();
	my $obj = Object::Configure::instantiate(
		class       => 'Inst::WithConfig',
		config_file => $path,
	);
	ok(blessed($obj) && $obj->isa('Inst::WithConfig'),
		'instantiate: object created with config file');
	ok(exists $Object::Configure::_object_registry{'Inst::WithConfig'},
		'instantiate: register_object called when _config_file is present');

	Object::Configure::restore_signal_handlers();
	delete $Object::Configure::_object_registry{'Inst::WithConfig'};
};

done_testing();
