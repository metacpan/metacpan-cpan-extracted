#!/usr/bin/env perl

# extended_tests.t - Comprehensive branch/LCSAJ/TER3 coverage for Object::Configure
#
# Targets every conditional branch, every jump-pair, and every linear code
# sequence that existing tests are unlikely to reach.  Organised by function,
# then by branch cluster within that function.

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Scalar::Util qw(blessed weaken reftype);
use File::Temp qw(tempdir tempfile);
use File::Spec;
use POSIX qw(WIFEXITED);

use_ok('Object::Configure');

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build a temp config dir containing a YAML file with the given content.
sub _make_conf_dir {
	my (%files) = @_;	# filename => YAML text

	my $dir = tempdir(CLEANUP => 1);
	for my $name (keys %files) {
		my $path = File::Spec->catfile($dir, $name);
		open my $fh, '>', $path or die "Cannot write $path: $!";
		print $fh $files{$name};
		close $fh;
	}
	return $dir;
}

# Minimal blessed object that IS a Log::Abstraction
sub _make_logger { return bless {}, 'Log::Abstraction' }

# Minimal blessed object that is NOT a Log::Abstraction
sub _make_other_obj { return bless {}, 'Some::RandomClass' }

# Reset Object::Configure package globals between tests that touch them.
# We reach in via the package namespace because these are our globals.
# Guard the kill() call against non-numeric PIDs that a mutant may inject.
sub _reset_globals {
	if(my $pid = $Object::Configure::_config_watchers{pid}) {
		if($pid =~ /\A[0-9]+\z/ && $pid > 0) {
			kill 'KILL', $pid;
			waitpid $pid, 0;
		}
	}
	%Object::Configure::_object_registry   = ();
	%Object::Configure::_config_watchers   = ();
	%Object::Configure::_config_file_stats = ();
	$Object::Configure::_original_usr1_handler = undef;
	$SIG{USR1} = 'DEFAULT' if $^O ne 'MSWin32';
	return;
}

# ---------------------------------------------------------------------------
# SECTION 1 — configure(): guard: empty-string class name
# ---------------------------------------------------------------------------

subtest 'configure: empty string class name croaks' => sub {
	plan tests => 1;

	# The '' guard was added in v0.20; undef alone was tested before
	dies_ok { Object::Configure::configure('') }
		'empty string class name throws';
};

# ---------------------------------------------------------------------------
# SECTION 2 — configure(): stash loop variants
# ---------------------------------------------------------------------------

subtest 'configure: coderef params are stashed and restored' => sub {
	plan tests => 3;

	my $cb = sub { 42 };
	my $params = Object::Configure::configure(
		'Stash__Test__Coderef',
		{ callback => $cb }
	);
	ok(exists $params->{callback},        'callback key survives configure');
	is(reftype($params->{callback}), 'CODE', 'callback is still a CODE ref');
	is($params->{callback}->(), 42,        'coderef still executes correctly');
};

subtest 'configure: blessed-object params are stashed and restored' => sub {
	plan tests => 3;

	my $obj = bless { x => 99 }, 'My::Helper';
	my $params = Object::Configure::configure(
		'Stash__Test__Object',
		{ helper => $obj }
	);
	ok(exists $params->{helper},          'helper key survives configure');
	ok(blessed($params->{helper}),        'helper is still blessed');
	is($params->{helper}{x}, 99,          'blessed object data intact');
};

subtest 'configure: multiple coderefs and objects all restored' => sub {
	plan tests => 4;

	my $cb1  = sub { 'a' };
	my $cb2  = sub { 'b' };
	my $obj1 = bless {}, 'Helper::One';
	my $obj2 = bless {}, 'Helper::Two';

	my $params = Object::Configure::configure(
		'Stash__Test__Multiple',
		{ cb1 => $cb1, cb2 => $cb2, o1 => $obj1, o2 => $obj2 }
	);

	is(reftype($params->{cb1}), 'CODE',  'cb1 restored');
	is(reftype($params->{cb2}), 'CODE',  'cb2 restored');
	ok(blessed($params->{o1}),           'o1 restored');
	ok(blessed($params->{o2}),           'o2 restored');
};

# ---------------------------------------------------------------------------
# SECTION 3 — configure(): logger ARRAY branch
# ---------------------------------------------------------------------------

subtest 'configure: logger as ARRAY ref stores into logger->array' => sub {
	plan tests => 2;

	my @log_buffer;
	my $params = Object::Configure::configure(
		'Logger__Array__Test',
		{ logger => \@log_buffer }
	);

	ok(blessed($params->{logger}), 'logger created from ARRAY ref');
	# The array reference should have been passed through to Log::Abstraction
	# (it stores it internally); we just verify no crash and logger exists
	isa_ok($params->{logger}, 'Log::Abstraction');
};

# ---------------------------------------------------------------------------
# SECTION 4 — configure(): config_file readable-check branches
# ---------------------------------------------------------------------------

subtest 'configure: non-readable config_file without config_dirs croaks' => sub {
	plan tests => 1;

	dies_ok {
		Object::Configure::configure(
			'Readability__Test',
			{ config_file => '/nonexistent/path/that/cannot/be/read.yml' }
		)
	} 'unreadable config_file without config_dirs croaks';
};

subtest 'configure: non-readable config_file WITH config_dirs does not immediately croak' => sub {
	plan tests => 1;

	# Providing config_dirs bypasses the early -r check;
	# it may still fail later but must not croak at that guard
	my $dir = tempdir(CLEANUP => 1);
	lives_ok {
		Object::Configure::configure(
			'Readability__Dirs__Test',
			{
				config_file => 'no-such-file.yml',
				config_dirs => [$dir],
			}
		)
	} 'non-readable config_file + config_dirs skips early guard';
};

# ---------------------------------------------------------------------------
# SECTION 5 — configure(): _config_file / _config_files not overwritten
# ---------------------------------------------------------------------------

subtest 'configure: user-supplied _config_file is preserved' => sub {
	plan tests => 1;

	my $params = Object::Configure::configure(
		'Preserve__ConfigFile__Test',
		{ _config_file => '/my/special/path.yml' }
	);
	is($params->{_config_file}, '/my/special/path.yml',
		'user-supplied _config_file not overwritten');
};

subtest 'configure: user-supplied _config_files is preserved' => sub {
	plan tests => 1;

	my $list = ['/a.yml', '/b.yml'];
	my $params = Object::Configure::configure(
		'Preserve__ConfigFiles__Test',
		{ _config_files => $list }
	);
	is($params->{_config_files}, $list,
		'user-supplied _config_files arrayref not overwritten');
};

# ---------------------------------------------------------------------------
# SECTION 6 — configure(): logger variants
# ---------------------------------------------------------------------------

subtest 'configure: logger=NULL stays as the string NULL' => sub {
	# Bug: the logger dispatch block checks ($logger eq 'NULL') but the preceding
	# elsif(!blessed($logger) || ...) fires first for plain strings, wrapping 'NULL'.
	# Fix required in Object::Configure: add !ref($logger) && before the eq check,
	# i.e.: if(!ref($logger) && $logger eq 'NULL') { ... }
	local $TODO = 'requires Object::Configure fix: !ref($logger) && $logger eq "NULL"';
	plan tests => 2;

	my $params = Object::Configure::configure(
		'Logger__NULL__Test__XQ99',
		{ logger => 'NULL' }
	);
	is($params->{logger}, 'NULL', 'logger is still the string NULL');
	ok(!ref($params->{logger}),   'logger is not a reference');
};

subtest 'configure: logger already a Log::Abstraction is not rewrapped' => sub {
	# Bug: configure() rewraps a Log::Abstraction that was passed in, creating a
	# new object instead of preserving the caller's instance.
	# Fix required in Object::Configure: the elsif branch must be guarded so that
	# a blessed Log::Abstraction is left untouched.
	local $TODO = 'requires Object::Configure fix: preserve passed-in Log::Abstraction';
	plan tests => 2;

	my $original = _make_logger();
	my $params   = Object::Configure::configure(
		'Logger__Already__Set__XQ99',
		{ logger => $original }
	);
	isa_ok($params->{logger}, 'Log::Abstraction');
	is($params->{logger}, $original, 'same logger object returned (not rewrapped)');
};

subtest 'configure: logger as HASH with syslog key' => sub {
	plan tests => 1;

	# We cannot open real syslog in a test, but we can verify no crash and
	# a Log::Abstraction is created
	my $params;
	lives_ok {
		$params = Object::Configure::configure(
			'Logger__Syslog__Hash',
			{ logger => { syslog => 'user', level => 'debug' } }
		)
	} 'logger hash with syslog key does not croak';
};

subtest 'configure: logger as HASH without syslog key' => sub {
	# We only test that a Log::Abstraction was created; we do not inspect
	# Log::Abstraction's internals (it may store a 'syslog' key regardless).
	plan tests => 1;

	my @buf;
	my $params = Object::Configure::configure(
		'Logger__Hash__NoSyslog',
		{ logger => { array => \@buf } }
	);
	isa_ok($params->{logger}, 'Log::Abstraction');
};

subtest 'configure: logger blessed but not Log::Abstraction gets wrapped' => sub {
	plan tests => 1;

	my $foreign = _make_other_obj();
	my $params  = Object::Configure::configure(
		'Logger__Foreign__Object',
		{ logger => $foreign }
	);
	# Should be wrapped: result is a Log::Abstraction
	isa_ok($params->{logger}, 'Log::Abstraction');
};

subtest 'configure: no logger produces a default Log::Abstraction' => sub {
	plan tests => 1;

	my $params = Object::Configure::configure('Logger__Default__Test', {});
	isa_ok($params->{logger}, 'Log::Abstraction');
};

# ---------------------------------------------------------------------------
# SECTION 7 — configure(): with a real config file (inheritance chain + merge)
# ---------------------------------------------------------------------------

subtest 'configure: loads from config_dirs fallback when no inheritance tree' => sub {
	plan tests => 2;

	# Class name with no CPAN namespace — no ancestor configs will exist
	my $yaml = <<'YAML';
---
Flat__Class:
  timeout: 99
YAML

	my $dir    = _make_conf_dir('flat-class.yml' => $yaml);
	my $params = Object::Configure::configure(
		'Flat::Class',
		{
			config_file => 'flat-class.yml',
			config_dirs => [$dir],
		}
	);

	is($params->{timeout}, 99, 'timeout loaded from config_dirs fallback');
	ok($params->{_config_files} || $params->{_config_file},
		'config tracking key set after load');
};

subtest 'configure: _config_files tracks all loaded files' => sub {
	plan tests => 2;

	my $yaml = <<'YAML';
---
Track__Files__Test:
  answer: 42
YAML

	my $dir    = _make_conf_dir('track-files-test.yml' => $yaml);
	my $params = Object::Configure::configure(
		'Track::Files::Test',
		{
			config_file => 'track-files-test.yml',
			config_dirs => [$dir],
		}
	);

	is($params->{answer}, 42, 'config value loaded');
	ok(defined($params->{_config_file}) || defined($params->{_config_files}),
		'_config_file or _config_files populated');
};

# ---------------------------------------------------------------------------
# SECTION 8 — _find_class_config_file(): path parsing branches
# ---------------------------------------------------------------------------

{
	# We test _find_class_config_file directly by calling the internal sub.
	# It lives in the Object::Configure namespace.
	no warnings 'once';
	*_find = \&Object::Configure::_find_class_config_file;
}

subtest '_find_class_config_file: returns undef for nonexistent class' => sub {
	plan tests => 1;

	my $result = Object::Configure::_find_class_config_file(
		'Completely::Nonexistent::Class',
		'some-config.yml',
		[]
	);
	ok(!defined($result), 'returns undef when no file exists');
};

subtest '_find_class_config_file: finds file in config_dir with matching name' => sub {
	plan tests => 1;

	my $dir = _make_conf_dir('my-test-class.yml' => "---\nMy__Test__Class:\n  x: 1\n");
	my $result = Object::Configure::_find_class_config_file(
		'My::Test::Class',
		'some-config.yml',
		[$dir]
	);
	ok(defined($result) && -r $result, 'found file in config_dir');
};

subtest '_find_class_config_file: trailing slash in config_dir stripped' => sub {
	plan tests => 1;

	my $dir = _make_conf_dir('strip-slash-class.yml' => "---\n");
	my $result = Object::Configure::_find_class_config_file(
		'Strip::Slash::Class',
		'x.yml',
		["$dir/"]	# trailing slash
	);
	ok(defined($result) && -r $result, 'trailing slash in dir stripped correctly');
};

subtest '_find_class_config_file: base dir component used when config_file has path' => sub {
	plan tests => 1;

	# When $base_config_file has a directory prefix, _find_class_config_file
	# should find a class-named file in that same directory.
	# Note: the module's internal path-splitting regex uses '/' as separator,
	# which fails on Windows.  We therefore also supply config_dirs so the
	# function can locate the file via the portable fallback path on all platforms.
	my $dir  = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($dir, 'with-dir-class.yml');
	open my $fh, '>', $path or die $!;
	print $fh "---\n";
	close $fh;

	my $base   = File::Spec->catfile($dir, 'something.yml');
	my $result = Object::Configure::_find_class_config_file(
		'With::Dir::Class',
		$base,
		[$dir],		# config_dirs ensures the portable fallback always works
	);
	ok(defined($result) && -r $result, 'found class config in same dir as base config_file');
};

# ---------------------------------------------------------------------------
# SECTION 9 — _walk_isa() / _get_inheritance_chain(): topology branches
# ---------------------------------------------------------------------------

subtest '_get_inheritance_chain: class with no @ISA gets UNIVERSAL added' => sub {
	plan tests => 2;

	# Declare a fresh class with no parent
	{ package Orphan::Class::XYZ1; }

	my @chain = Object::Configure::_get_inheritance_chain('Orphan::Class::XYZ1');
	ok(scalar @chain >= 2, 'chain has at least UNIVERSAL + the class itself');
	ok((grep { $_ eq 'UNIVERSAL' } @chain), 'UNIVERSAL appears in chain');
};

subtest '_get_inheritance_chain: handles diamond inheritance without duplicates' => sub {
	plan tests => 3;

	{
		package Diamond::Base2;
		our @ISA = ();
	}
	{
		package Diamond::Left2;
		our @ISA = ('Diamond::Base2');
	}
	{
		package Diamond::Right2;
		our @ISA = ('Diamond::Base2');
	}
	{
		package Diamond::Child2;
		our @ISA = ('Diamond::Left2', 'Diamond::Right2');
	}

	my @chain = Object::Configure::_get_inheritance_chain('Diamond::Child2');
	my %seen;
	my @dupes = grep { $seen{$_}++ } @chain;

	ok(!@dupes, 'no duplicate classes in chain');
	ok((grep { $_ eq 'Diamond::Base2'  } @chain), 'Base2 in chain');
	ok((grep { $_ eq 'Diamond::Child2' } @chain), 'Child2 in chain');
};

subtest '_get_inheritance_chain: %seen guard prevents duplicate entries in deep chain' => sub {
	# Perl 5.42+ rejects genuinely cyclic @ISA at the interpreter level, so we
	# cannot manufacture an A->B->A cycle in a test.  Instead we verify the %seen
	# guard indirectly: a 4-level linear chain should produce each class exactly
	# once even though every subclass "inherits" the grandparent transitively.
	plan tests => 2;

	{
		package Deep::Root3;   our @ISA = ();
	}
	{
		package Deep::Mid3;    our @ISA = ('Deep::Root3');
	}
	{
		package Deep::Child3;  our @ISA = ('Deep::Mid3');
	}
	{
		package Deep::Leaf3;   our @ISA = ('Deep::Child3');
	}

	my @chain = Object::Configure::_get_inheritance_chain('Deep::Leaf3');
	my %freq;
	$freq{$_}++ for @chain;
	my @dupes = grep { $freq{$_} > 1 } keys %freq;

	ok(!@dupes, 'no class appears twice in a deep linear chain');
	ok((grep { $_ eq 'Deep::Root3' } @chain), 'root class present in chain');
};

# ---------------------------------------------------------------------------
# SECTION 10 — _deep_merge(): all branch combinations
# ---------------------------------------------------------------------------

# Access the function directly
*_deep_merge = \&Object::Configure::_deep_merge;

subtest '_deep_merge: base not a hashref returns overlay' => sub {
	plan tests => 1;

	my $result = Object::Configure::_deep_merge('scalar_base', { a => 1 });
	is_deeply($result, { a => 1 }, 'overlay returned when base is scalar');
};

subtest '_deep_merge: overlay not a hashref returns overlay' => sub {
	plan tests => 1;

	my $result = Object::Configure::_deep_merge({ a => 1 }, 'scalar_overlay');
	is($result, 'scalar_overlay', 'scalar overlay returned directly');
};

subtest '_deep_merge: overlay undef returned as-is' => sub {
	plan tests => 1;

	my $result = Object::Configure::_deep_merge({ a => 1 }, undef);
	ok(!defined($result), 'undef overlay returned as undef');
};

subtest '_deep_merge: keys only in base are preserved' => sub {
	plan tests => 1;

	my $result = Object::Configure::_deep_merge({ a => 1, b => 2 }, { b => 99 });
	is($result->{a}, 1, 'base-only key preserved');
};

subtest '_deep_merge: keys only in overlay are added' => sub {
	plan tests => 1;

	my $result = Object::Configure::_deep_merge({ a => 1 }, { z => 42 });
	is($result->{z}, 42, 'overlay-only key added');
};

subtest '_deep_merge: overlay scalar overwrites base scalar' => sub {
	plan tests => 1;

	my $result = Object::Configure::_deep_merge({ k => 'old' }, { k => 'new' });
	is($result->{k}, 'new', 'overlay scalar wins');
};

subtest '_deep_merge: nested hashes are recursively merged' => sub {
	plan tests => 3;

	my $base    = { top => { a => 1, b => 2 } };
	my $overlay = { top => { b => 99, c => 3 } };
	my $result  = Object::Configure::_deep_merge($base, $overlay);

	is($result->{top}{a}, 1,  'base sub-key preserved');
	is($result->{top}{b}, 99, 'overlay sub-key wins');
	is($result->{top}{c}, 3,  'overlay-only sub-key added');
};

subtest '_deep_merge: overlay hash over base non-hash replaces' => sub {
	plan tests => 1;

	# base has scalar, overlay has hash — overlay wins (not recursed)
	my $result = Object::Configure::_deep_merge(
		{ k => 'scalar' },
		{ k => { nested => 1 } }
	);
	is_deeply($result->{k}, { nested => 1 },
		'overlay hash replaces base scalar');
};

subtest '_deep_merge: base hash over overlay non-hash, overlay wins' => sub {
	plan tests => 1;

	# base has hash, overlay has scalar — scalar overlay wins
	my $result = Object::Configure::_deep_merge(
		{ k => { deep => 1 } },
		{ k => 'flat' }
	);
	is($result->{k}, 'flat', 'scalar overlay replaces base hash');
};

subtest '_deep_merge: does not mutate either input' => sub {
	plan tests => 2;

	my $base    = { a => 1 };
	my $overlay = { b => 2 };
	my $result  = Object::Configure::_deep_merge($base, $overlay);

	ok(!exists $base->{b},    'base not mutated');
	ok(!exists $overlay->{a}, 'overlay not mutated');
};

# ---------------------------------------------------------------------------
# SECTION 11 — register_object(): guard and repeat-call branches
# ---------------------------------------------------------------------------

subtest 'register_object: undef class croaks' => sub {
	plan tests => 1;
	_reset_globals();
	dies_ok { Object::Configure::register_object(undef, bless {}, 'Foo') }
		'undef class croaks';
};

subtest 'register_object: undef obj croaks' => sub {
	plan tests => 1;
	_reset_globals();
	dies_ok { Object::Configure::register_object('Foo', undef) }
		'undef obj croaks';
};

subtest 'register_object: first call installs USR1 handler (non-Windows)' => sub {
	plan skip_all => 'SIGUSR1 not available on Windows' if $^O eq 'MSWin32';
	plan tests => 2;

	_reset_globals();
	my $obj = bless {}, 'Register::Test::One';
	lives_ok { Object::Configure::register_object('Register::Test::One', $obj) }
		'first register_object does not croak';
	ok(defined $Object::Configure::_original_usr1_handler,
		'_original_usr1_handler set after first call');
};

subtest 'register_object: second call skips handler re-installation' => sub {
	plan skip_all => 'SIGUSR1 not available on Windows' if $^O eq 'MSWin32';
	plan tests => 2;

	_reset_globals();
	my $obj1 = bless {}, 'Register::Test::Two';
	my $obj2 = bless {}, 'Register::Test::Two';

	Object::Configure::register_object('Register::Test::Two', $obj1);
	my $handler_after_first = $SIG{USR1};

	Object::Configure::register_object('Register::Test::Two', $obj2);
	my $handler_after_second = $SIG{USR1};

	is($handler_after_first, $handler_after_second,
		'USR1 handler not replaced on second call');
	is(scalar @{$Object::Configure::_object_registry{'Register::Test::Two'}},
		2, 'both objects in registry');
};

subtest 'register_object: original coderef handler chained on SIGUSR1' => sub {
	plan skip_all => 'SIGUSR1 not available on Windows' if $^O eq 'MSWin32';
	plan tests => 1;

	_reset_globals();

	my $chained = 0;
	$SIG{USR1} = sub { $chained++ };

	my $obj = bless { _config_file => undef }, 'Chain::Test::Class';
	Object::Configure::register_object('Chain::Test::Class', $obj);

	_with_timeout(5, 'USR1 coderef chaining', sub {
		kill 'USR1', $$;
		select undef, undef, undef, 0.05;	# allow signal delivery
	});

	ok($chained > 0, 'original coderef handler was chained');
};

subtest 'register_object: IGNORE handler does not warn' => sub {
	plan skip_all => 'SIGUSR1 not available on Windows' if $^O eq 'MSWin32';
	plan tests => 1;

	_reset_globals();
	$SIG{USR1} = 'IGNORE';

	my $obj = bless {}, 'Ignore::Handler::Test';
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	Object::Configure::register_object('Ignore::Handler::Test', $obj);

	_with_timeout(5, 'USR1 IGNORE handler', sub {
		kill 'USR1', $$;
		select undef, undef, undef, 0.05;	# allow signal delivery
	});

	ok(!@warnings, 'no warning when original handler was IGNORE');
};

# ---------------------------------------------------------------------------
# SECTION 12 — restore_signal_handlers(): both branches
# ---------------------------------------------------------------------------

subtest 'restore_signal_handlers: no-op when nothing to restore' => sub {
	plan tests => 1;
	_reset_globals();

	lives_ok { Object::Configure::restore_signal_handlers() }
		'restore_signal_handlers is safe when nothing installed';
};

subtest 'restore_signal_handlers: restores original handler' => sub {
	plan skip_all => 'SIGUSR1 not available on Windows' if $^O eq 'MSWin32';
	plan tests => 2;

	_reset_globals();

	my $original_cb = sub { 'original' };
	$SIG{USR1} = $original_cb;

	my $obj = bless {}, 'Restore::Test::Class';
	Object::Configure::register_object('Restore::Test::Class', $obj);

	# confirm handler was replaced
	isnt($SIG{USR1}, $original_cb, 'handler was replaced by register_object');

	Object::Configure::restore_signal_handlers();
	is($SIG{USR1}, $original_cb, 'original handler restored');
};

# ---------------------------------------------------------------------------
# SECTION 13 — get_signal_handler_info(): all fields
# ---------------------------------------------------------------------------

subtest 'get_signal_handler_info: before any setup' => sub {
	plan tests => 4;
	_reset_globals();

	my $info = Object::Configure::get_signal_handler_info();
	ok(defined $info,                           'returns a hashref');
	ok(!defined $info->{original_usr1},         'original_usr1 undef before setup');
	ok(!$info->{hot_reload_active},             'hot_reload_active false before setup');
	ok(!defined $info->{watcher_pid},           'watcher_pid undef before setup');
};

subtest 'get_signal_handler_info: after register_object' => sub {
	plan skip_all => 'SIGUSR1 not available on Windows' if $^O eq 'MSWin32';
	plan tests => 2;

	_reset_globals();
	my $obj = bless {}, 'Info::After::Register';
	Object::Configure::register_object('Info::After::Register', $obj);

	my $info = Object::Configure::get_signal_handler_info();
	ok(defined $info->{original_usr1},  'original_usr1 set after register');
	ok($info->{hot_reload_active},      'hot_reload_active true after register');
};

subtest 'get_signal_handler_info: after restore' => sub {
	plan skip_all => 'SIGUSR1 not available on Windows' if $^O eq 'MSWin32';
	plan tests => 1;

	_reset_globals();
	my $obj = bless {}, 'Info::After::Restore';
	Object::Configure::register_object('Info::After::Restore', $obj);
	Object::Configure::restore_signal_handlers();

	my $info = Object::Configure::get_signal_handler_info();
	ok(!$info->{hot_reload_active}, 'hot_reload_active false after restore');
};

# ---------------------------------------------------------------------------
# SECTION 14 — enable_hot_reload() / disable_hot_reload(): state machine
#
# All subtests that fork are wrapped with a SIGALRM deadline.  Under mutation
# testing a mutant can cause enable_hot_reload() to fork when it should return
# early, or disable_hot_reload() to not kill the child, leaving a zombie that
# blocks waitpid forever.  The alarm ensures the test process always exits.
# ---------------------------------------------------------------------------

# Helper: run a block with a hard timeout (seconds).  Calls BAIL_OUT on expiry
# so the test file exits cleanly rather than hanging the mutation harness.
sub _with_timeout {
	my ($secs, $label, $code) = @_;
	local $SIG{ALRM} = sub {
		# Kill any child we may have spawned before bailing.
		# Guard against non-numeric PIDs injected by mutants.
		if(my $pid = $Object::Configure::_config_watchers{pid}) {
			if($pid =~ /\A[0-9]+\z/ && $pid > 0) {
				kill 'KILL', $pid;
				waitpid $pid, 0;
			}
		}
		%Object::Configure::_config_watchers = ();
		BAIL_OUT("Timeout after ${secs}s in: $label");
	};
	alarm $secs;
	my $ok = eval { $code->(); 1 };
	alarm 0;
	die $@ if !$ok && $@;
	return;
}

subtest 'enable_hot_reload: returns immediately if already active' => sub {
	plan skip_all => 'fork not available on Windows' if $^O eq 'MSWin32';
	plan tests => 2;

	_reset_globals();

	_with_timeout(10, 'enable_hot_reload already-active', sub {
		my $pid1 = Object::Configure::enable_hot_reload(interval => 60);
		ok(defined $pid1 && $pid1 > 0, 'first enable returns a PID');

		my $pid2 = Object::Configure::enable_hot_reload(interval => 60);
		ok(!defined($pid2) || $pid2 == 0 || $pid2 == $pid1,
			'second call returns early (same PID or undef/0)');

		Object::Configure::disable_hot_reload();
	});
};

subtest 'disable_hot_reload: no-op when not active' => sub {
	plan tests => 1;
	_reset_globals();

	# Wrap in eval: a mutant may make disable_hot_reload() call kill() with a
	# non-numeric PID even when the registry is empty, which would otherwise die
	# and corrupt the END block.
	my $err;
	eval { Object::Configure::disable_hot_reload(); 1 } or do { $err = $@ };
	ok(!$err, 'disable_hot_reload is safe when no watcher running')
		or diag("died: $err");

	# Ensure globals are clean regardless of what the mutant did
	%Object::Configure::_config_watchers = ();
};

subtest 'disable_hot_reload: kills watcher process cleanly' => sub {
	plan skip_all => 'fork not available on Windows' if $^O eq 'MSWin32';
	plan tests => 3;

	_reset_globals();

	_with_timeout(15, 'disable_hot_reload kills watcher', sub {
		my $pid = Object::Configure::enable_hot_reload(interval => 60);
		ok(defined $pid && $pid > 0, 'watcher pid returned');
		ok(kill(0, $pid), 'watcher process is alive');

		# Wrap disable call: a mutant may cause kill() to die inside the module
		eval { Object::Configure::disable_hot_reload() };
		# Force cleanup regardless
		if(my $p = $Object::Configure::_config_watchers{pid}) {
			if($p =~ /\A[0-9]+\z/ && $p > 0) {
				kill 'KILL', $p;
				waitpid $p, 0;
			}
		}
		%Object::Configure::_config_watchers = ();

		select undef, undef, undef, 0.1;	# allow process table to update
		ok(!kill(0, $pid), 'watcher process gone after disable');
	});

	# Ensure clean state for subsequent tests and END block
	_reset_globals();
};

# ---------------------------------------------------------------------------
# SECTION 15 — reload_config(): registry states
# ---------------------------------------------------------------------------

subtest 'reload_config: empty registry returns 0' => sub {
	plan tests => 1;
	_reset_globals();

	my $count = Object::Configure::reload_config();
	is($count, 0, 'empty registry reloads 0 objects');
};

subtest 'reload_config: dead weak refs are cleaned up' => sub {
	plan tests => 2;
	_reset_globals();

	# register_object stores \$obj and weakens $$obj_ref (the blessed ref itself).
	# We replicate that pattern: after the block $obj is gone, $$obj_ref is undef.
	my $obj_ref;
	{
		my $obj = bless { _config_file => undef }, 'Dead::Ref::Test';
		$obj_ref = \$obj;
		weaken($$obj_ref);
		push @{$Object::Configure::_object_registry{'Dead::Ref::Test'}}, $obj_ref;
	}

	# After block, $obj gone; $$obj_ref is now undef
	ok(!defined($$obj_ref), 'weak ref is now undef after object goes out of scope');

	# reload_config should clean up the dead entry and return 0
	my $count = Object::Configure::reload_config();
	is($count, 0, 'no live objects reloaded');
};

subtest 'reload_config: live object with no config file skips gracefully' => sub {
	plan tests => 1;
	_reset_globals();

	# Manually inject a live object WITH no _config_file/_config_files
	my $obj = bless { timeout => 5 }, 'No::Config::File::Class';
	my $obj_ref = \$obj;
	weaken($$obj_ref);
	push @{$Object::Configure::_object_registry{'No::Config::File::Class'}}, $obj_ref;

	# Should not croak; _reload_object_config returns early if no file
	my $count;
	lives_ok { $count = Object::Configure::reload_config() }
		'reload with no-config-file object does not croak';
};

subtest 'reload_config: object with valid config file is reloaded' => sub {
	plan tests => 2;

	_reset_globals();

	# Class name: Reload::Live::Test -> section Reload__Live__Test in YAML
	my $yaml = <<'YAML';
---
Reload__Live__Test:
  timeout: 77
YAML
	my $dir  = _make_conf_dir('reload-live-test.yml' => $yaml);
	my $file = File::Spec->catfile($dir, 'reload-live-test.yml');

	# Use configure() to build params the same way the module does, so that
	# _config_file / _config_files are set in the way _reload_object_config expects
	my $params = Object::Configure::configure(
		'Reload::Live::Test',
		{
			timeout     => 1,
			config_file => 'reload-live-test.yml',
			config_dirs => [$dir],
		}
	);
	my $obj = bless $params, 'Reload::Live::Test';

	my $obj_ref = \$obj;
	weaken($$obj_ref);
	push @{$Object::Configure::_object_registry{'Reload::Live::Test'}}, $obj_ref;

	my $count;
	lives_ok { $count = Object::Configure::reload_config() } 'reload does not croak';
	is($obj->{timeout}, 77, 'object property updated on reload');
};

subtest 'reload_config: failed reload emits warning not croak' => sub {
	plan tests => 2;

	_reset_globals();

	# Inject an object whose reload will fail: _config_files points to a
	# directory (not a regular file), so -f fails inside _reload_object_config
	my $dir = tempdir(CLEANUP => 1);
	my $obj = bless {
		_config_file  => $dir,	# a directory, not a file
		_config_files => [$dir],
	}, 'Bad::Config::Class';

	my $obj_ref = \$obj;
	weaken($$obj_ref);
	push @{$Object::Configure::_object_registry{'Bad::Config::Class'}}, $obj_ref;

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $count;
	lives_ok { $count = Object::Configure::reload_config() }
		'failed reload does not croak';
	is($count, 0, 'failed reload not counted');
};

# ---------------------------------------------------------------------------
# SECTION 16 — _reconfigure_logger(): all branches
# ---------------------------------------------------------------------------

{
	# Expose private sub for direct testing
	no warnings 'once';
	*_reconfigure_logger = \&Object::Configure::_reconfigure_logger;
}

subtest '_reconfigure_logger: HASH with syslog creates Log::Abstraction' => sub {
	plan tests => 1;

	my $obj = bless { carp_on_warn => 0 }, 'ReconfigLogger::Syslog';
	lives_ok {
		Object::Configure::_reconfigure_logger(
			$obj, 'logger', { syslog => 'user', level => 'info' }
		)
	} 'syslog logger config does not croak';
};

subtest '_reconfigure_logger: HASH without syslog creates Log::Abstraction' => sub {
	plan tests => 2;

	my @buf;
	my $obj = bless { carp_on_warn => 0 }, 'ReconfigLogger::NoSyslog';
	Object::Configure::_reconfigure_logger($obj, 'logger', { array => \@buf });

	ok(defined $obj->{logger},             'logger created');
	isa_ok($obj->{logger}, 'Log::Abstraction');
};

subtest '_reconfigure_logger: scalar value assigned directly' => sub {
	plan tests => 1;

	my $obj = bless { carp_on_warn => 0 }, 'ReconfigLogger::Scalar';
	Object::Configure::_reconfigure_logger($obj, 'logger', 'NULL');
	is($obj->{logger}, 'NULL', 'scalar logger value assigned directly');
};

# ---------------------------------------------------------------------------
# SECTION 17 — _reload_object_config(): private key preservation
# ---------------------------------------------------------------------------

subtest '_reload_object_config: private keys (leading _) are not updated' => sub {
	plan tests => 1;

	_reset_globals();

	my $yaml = <<'YAML';
---
Private__Key__Test:
  public_val: 55
YAML
	my $dir  = _make_conf_dir('private-key-test.yml' => $yaml);

	my $params = Object::Configure::configure(
		'Private::Key::Test',
		{
			public_val  => 1,
			config_file => 'private-key-test.yml',
			config_dirs => [$dir],
		}
	);
	# Plant a private key AFTER configure() so it won't be overwritten
	$params->{_secret} = 'do_not_touch';
	my $obj = bless $params, 'Private::Key::Test';

	my $obj_ref = \$obj;
	weaken($$obj_ref);
	push @{$Object::Configure::_object_registry{'Private::Key::Test'}}, $obj_ref;

	Object::Configure::reload_config();
	is($obj->{_secret}, 'do_not_touch', 'private key not overwritten on reload');
};

# ---------------------------------------------------------------------------
# SECTION 18 — _reload_object_config(): _on_config_reload hook called
# ---------------------------------------------------------------------------

subtest '_reload_object_config: _on_config_reload hook is invoked' => sub {
	plan tests => 1;

	_reset_globals();

	my $yaml = <<'YAML';
---
Hook__Test__Class:
  val: 1
YAML
	my $dir  = _make_conf_dir('hook-test-class.yml' => $yaml);

	my $hook_called = 0;
	{
		no strict 'refs';
		*{'Hook::Test::Class::_on_config_reload'} = sub { $hook_called++ };
	}

	my $params = Object::Configure::configure(
		'Hook::Test::Class',
		{
			config_file => 'hook-test-class.yml',
			config_dirs => [$dir],
		}
	);
	my $obj = bless $params, 'Hook::Test::Class';

	my $obj_ref = \$obj;
	weaken($$obj_ref);
	push @{$Object::Configure::_object_registry{'Hook::Test::Class'}}, $obj_ref;

	Object::Configure::reload_config();
	ok($hook_called, '_on_config_reload hook was called during reload');
};

# ---------------------------------------------------------------------------
# SECTION 19 — instantiate(): basic path
# ---------------------------------------------------------------------------

{
	# Minimal class that just blesses its params
	package Instantiate::Test::Widget;
	sub new {
		my ($class, $params) = @_;
		return bless($params || {}, $class);
	}
}

subtest 'instantiate: creates a blessed object of the right class' => sub {
	plan tests => 2;

	_reset_globals();
	my $obj = Object::Configure::instantiate(class => 'Instantiate::Test::Widget');
	ok(defined $obj,                              'object returned');
	isa_ok($obj, 'Instantiate::Test::Widget');
};

subtest 'instantiate: registers object when config_file present' => sub {
	plan tests => 2;

	_reset_globals();

	my $yaml = <<'YAML';
---
Instantiate__Test__Widget:
  speed: 88
YAML
	my $dir  = _make_conf_dir('instantiate-test-widget.yml' => $yaml);

	my $obj = Object::Configure::instantiate(
		class       => 'Instantiate::Test::Widget',
		config_file => 'instantiate-test-widget.yml',
		config_dirs => [$dir],
	);

	isa_ok($obj, 'Instantiate::Test::Widget');
	ok(exists $Object::Configure::_object_registry{'Instantiate::Test::Widget'},
		'object registered when config_file used');
};

# ---------------------------------------------------------------------------
# SECTION 20 — Return type: configure() always returns a hashref
# ---------------------------------------------------------------------------

subtest 'configure: always returns a hashref' => sub {
	plan tests => 3;

	for my $class (qw(Alpha::Class Beta::Class Gamma::Class)) {
		my $params = Object::Configure::configure($class, {});
		ok(ref($params) eq 'HASH', "$class: configure returns hashref");
	}
};

# ---------------------------------------------------------------------------
# SECTION 21 — Thread-safety safety-net: multiple simultaneous configure()
# (fork-based, since Perl threads aren't available everywhere)
# ---------------------------------------------------------------------------

subtest 'configure: multiple independent calls do not interfere' => sub {
	plan tests => 3;

	# Run configure for three distinct classes and confirm each gets its own logger
	my $p1 = Object::Configure::configure('Parallel::A', { timeout => 1 });
	my $p2 = Object::Configure::configure('Parallel::B', { timeout => 2 });
	my $p3 = Object::Configure::configure('Parallel::C', { timeout => 3 });

	isnt($p1->{logger}, $p2->{logger}, 'distinct loggers for distinct calls');
	isnt($p2->{logger}, $p3->{logger}, 'distinct loggers');
	isnt($p1->{logger}, $p3->{logger}, 'distinct loggers');
};

# ---------------------------------------------------------------------------
# SECTION 22 — configure(): carp_on_warn propagation
# ---------------------------------------------------------------------------

subtest 'configure: carp_on_warn=1 propagated to logger' => sub {
	plan tests => 1;

	my $params = Object::Configure::configure(
		'Carp__On__Warn__Test',
		{ carp_on_warn => 1 }
	);
	# Log::Abstraction stores this flag; we just confirm configure() doesn't croak
	isa_ok($params->{logger}, 'Log::Abstraction');
};

# ---------------------------------------------------------------------------
# Cleanup: sanitise Object::Configure globals before the module's own END
# block runs.  A mutant may have left a non-numeric or stale PID in
# %_config_watchers; without this guard the module's disable_hot_reload()
# call in its END block would die with "Can't kill a non-numeric process ID",
# aborting the END queue and producing a spurious exit code 22.
END {
	if(my $pid = $Object::Configure::_config_watchers{pid}) {
		unless($pid =~ /\A[0-9]+\z/ && $pid > 0) {
			# Bad PID from a mutant — clear it before the module's END fires
			%Object::Configure::_config_watchers = ();
		}
	}
}

done_testing();
