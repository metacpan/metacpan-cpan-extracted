#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Test::Mockingbird 0.10;
use File::Temp qw(tempdir);
use File::Spec;
use Log::Abstraction;
use Scalar::Util qw(blessed isweak);

# Load the module under test
BEGIN { use_ok('Object::Configure') }

# Test helper: create a temp config file
sub create_test_config {
	my ($dir, $filename, $content) = @_;
	my $path = File::Spec->catfile($dir, $filename);
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print $fh $content;
	close $fh;
	return $path;
}

subtest 'configure() - basic functionality with no config file' => sub {
	my $class = 'Test::Class::One';
	my $params = {
		foo => 'bar',
		timeout => 30
	};

	my $result = Object::Configure::configure($class, $params);

	ok(ref($result) eq 'HASH', 'Returns hashref');
	is($result->{foo}, 'bar', 'Preserves original params');
	is($result->{timeout}, 30, 'Preserves timeout param');
	ok(blessed($result->{logger}), 'Logger is blessed object');
	isa_ok($result->{logger}, 'Log::Abstraction', 'Logger');

	done_testing();
};

subtest 'configure() - preserves coderefs automatically' => sub {
	my $class = 'Test::Class::Two';
	my $callback = sub { return 'test' };
	my $params = {
		on_error => $callback,
		timeout => 30
	};

	my $result = Object::Configure::configure($class, $params);

	is(ref($result->{on_error}), 'CODE', 'Coderef preserved');
	is($result->{on_error}, $callback, 'Same coderef returned');
	is($result->{on_error}->(), 'test', 'Coderef still works');
	is($result->{timeout}, 30, 'Other params preserved');

	done_testing();
};

subtest 'configure() - preserves blessed objects automatically' => sub {
	my $class = 'Test::Class::Three';
	my $obj = bless { data => 'test' }, 'Some::Class';
	my $params = {
		custom_obj => $obj,
		timeout => 30
	};

	my $result = Object::Configure::configure($class, $params);

	ok(blessed($result->{custom_obj}), 'Object is still blessed');
	is($result->{custom_obj}, $obj, 'Same object returned');
	is($result->{custom_obj}{data}, 'test', 'Object data intact');
	is($result->{timeout}, 30, 'Other params preserved');

	done_testing();
};

subtest 'configure() - throws on undefined class' => sub {
	# Partition boundary: undef and empty string are the two terminal-invalid inputs.
	# Premise: guard clause fires before any config work — prove both gates.
	throws_ok {
		Object::Configure::configure(undef, {});
	} qr/configure: what class do you want to configure/, 'Croaks on undef class';

	throws_ok {
		Object::Configure::configure('', {});
	} qr/configure: what class do you want to configure/, 'Croaks on empty-string class';

	done_testing();
};

subtest 'configure() - handles logger parameter as hashref' => sub {
	my $class = 'Test::Class::Logger';
	my $params = {
		logger => { level => 'debug' }
	};

	my $result = Object::Configure::configure($class, $params);

	ok(blessed($result->{logger}), 'Logger created from hashref');
	isa_ok($result->{logger}, 'Log::Abstraction', 'Logger');

	done_testing();
};

subtest 'configure() - handles logger parameter as arrayref' => sub {
	my $class = 'Test::Class::LoggerArray';
	my @messages;
	my $params = {
		logger => \@messages
	};

	my $result = Object::Configure::configure($class, $params);

	ok(blessed($result->{logger}), 'Logger created from arrayref');
	isa_ok($result->{logger}, 'Log::Abstraction', 'Logger');
	is($result->{logger}{array}, \@messages, 'Array preserved in logger');

	done_testing();
};

subtest 'configure() - handles logger parameter as coderef' => sub {
	my $class = 'Test::Class::LoggerCode';
	my $logger_sub = sub { warn "log: @_" };
	my $params = {
		logger => $logger_sub
	};

	my $result = Object::Configure::configure($class, $params);

	ok(blessed($result->{logger}), 'Logger created from coderef');
	isa_ok($result->{logger}, 'Log::Abstraction', 'Logger');

	done_testing();
};

subtest 'configure() - loads config file when provided' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);
	my $config_content = <<'EOF';
---
Test__Class__ConfigFile:
  from_config: "yes"
  timeout: 60
EOF
	create_test_config($temp_dir, 'test.yml', $config_content);

	my $class = 'Test::Class::ConfigFile';
	my $params = {
		config_file => 'test.yml',
		config_dirs => [$temp_dir],
		timeout => 30
	};

	my $result = Object::Configure::configure($class, $params);

	is($result->{from_config}, 'yes', 'Config value loaded');
	is($result->{timeout}, 60, 'Config overrides default');
	ok(defined($result->{_config_file}), '_config_file set');
	ok(ref($result->{_config_files}) eq 'ARRAY', '_config_files is array');

	done_testing();
};

subtest 'configure() - throws on unreadable config file without config_dirs' => sub {
	my $class = 'Test::Class::BadConfig';
	my $params = {
		config_file => '/nonexistent/config.yml'
	};

	throws_ok {
		Object::Configure::configure($class, $params);
	} qr/Test__Class__BadConfig: \/nonexistent\/config\.yml/, 'Croaks on missing config';

	done_testing();
};

subtest '_find_class_config_file() - finds files with various extensions' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'my-test-class.yml', "---\ntest: 1\n");

	my $found = Object::Configure::_find_class_config_file(
		'My::Test::Class',
		'base.yml',
		[$temp_dir]
	);

	ok(defined($found), 'Found config file');
	like($found, qr/my-test-class\.yml$/, 'Correct filename');
	ok(-r $found, 'File is readable');

	done_testing();
};

subtest '_find_class_config_file() - tries multiple extensions' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'my-test.conf', "# test");

	my $found = Object::Configure::_find_class_config_file(
		'My::Test',
		'base.yml',
		[$temp_dir]
	);

	ok(defined($found), 'Found .conf file when .yml not present');
	like($found, qr/my-test\.conf$/, 'Found .conf extension');

	done_testing();
};

subtest '_find_class_config_file() - returns undef when file not found' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);

	my $found = Object::Configure::_find_class_config_file(
		'My::Nonexistent::Class',
		'base.yml',
		[$temp_dir]
	);

	ok(!defined($found), 'Returns undef for nonexistent file');

	done_testing();
};

subtest '_get_inheritance_chain() - single class with no parents' => sub {
	my @chain = Object::Configure::_get_inheritance_chain('Test::Standalone');

	ok(scalar(@chain) > 0, 'Chain not empty');
	ok(grep({ $_ eq 'UNIVERSAL' } @chain), 'UNIVERSAL in chain');
	ok(grep({ $_ eq 'Test::Standalone' } @chain), 'Class itself in chain');

	done_testing();
};

subtest '_get_inheritance_chain() - class with parent' => sub {
	{
		package Test::Parent;
		sub new { bless {}, shift }
	}
	{
		package Test::Child;
		use base 'Test::Parent';
		sub new { bless {}, shift }
	}

	my @chain = Object::Configure::_get_inheritance_chain('Test::Child');

	ok(grep({ $_ eq 'UNIVERSAL' } @chain), 'UNIVERSAL in chain');
	ok(grep({ $_ eq 'Test::Parent' } @chain), 'Parent in chain');
	ok(grep({ $_ eq 'Test::Child' } @chain), 'Child in chain');

	# Verify order: UNIVERSAL, Parent, Child
	my %positions;
	for my $i (0..$#chain) {
		$positions{$chain[$i]} = $i;
	}
	ok($positions{'UNIVERSAL'} < $positions{'Test::Parent'}, 'UNIVERSAL before Parent');
	ok($positions{'Test::Parent'} < $positions{'Test::Child'}, 'Parent before Child');

	done_testing();
};

subtest '_get_inheritance_chain() - UNIVERSAL appears exactly once' => sub {
	my @chain = Object::Configure::_get_inheritance_chain('Test::Solo');

	my $universal_count = grep { $_ eq 'UNIVERSAL' } @chain;
	is($universal_count, 1, 'UNIVERSAL appears exactly once');

	done_testing();
};

subtest '_deep_merge() - merges two hashes' => sub {
	my $base = {
		foo => 1,
		bar => 2,
		nested => { a => 1 }
	};
	my $overlay = {
		bar => 3,
		baz => 4,
		nested => { b => 2 }
	};

	my $result = Object::Configure::_deep_merge($base, $overlay);

	is($result->{foo}, 1, 'Base value preserved');
	is($result->{bar}, 3, 'Overlay overrides base');
	is($result->{baz}, 4, 'New value from overlay');
	is($result->{nested}{a}, 1, 'Nested base value preserved');
	is($result->{nested}{b}, 2, 'Nested overlay value added');

	done_testing();
};

subtest '_deep_merge() - handles non-hash inputs' => sub {
	my $result1 = Object::Configure::_deep_merge('not_hash', { foo => 1 });
	is_deeply($result1, { foo => 1 }, 'Returns overlay when base not hash');

	my $result2 = Object::Configure::_deep_merge({ foo => 1 }, 'not_hash');
	is($result2, 'not_hash', 'Returns overlay when overlay not hash (overlay takes precedence)');

	my $result3 = Object::Configure::_deep_merge('not_hash', 'also_not_hash');
	is($result3, 'also_not_hash', 'Returns overlay when neither is hash');

	done_testing();
};

subtest 'instantiate() - creates object with configuration' => sub {
	{
		package Test::Instantiable;
		sub new {
			my ($class, $params) = @_;
			return bless $params, $class;
		}
	}

	my $obj = Object::Configure::instantiate(
		class => 'Test::Instantiable',
		foo => 'bar'
	);

	ok(blessed($obj), 'Object is blessed');
	isa_ok($obj, 'Test::Instantiable', 'Object');
	is($obj->{foo}, 'bar', 'Parameter passed through');
	ok(blessed($obj->{logger}), 'Logger added');

	done_testing();
};

subtest 'register_object() - requires both arguments' => sub {
	throws_ok {
		Object::Configure::register_object('Some::Class', undef);
	} qr/register_object: Usage/, 'Croaks with undef object';

	throws_ok {
		Object::Configure::register_object(undef, {});
	} qr/register_object: Usage/, 'Croaks with undef class';

	done_testing();
};

subtest 'register_object() - adds to registry' => sub {
	my $obj = bless { foo => 'bar' }, 'Test::Registerable';

	Object::Configure::register_object('Test::Registerable', $obj);

	ok(exists($Object::Configure::_object_registry{'Test::Registerable'}),
		'Registry entry created');
	ok(scalar(@{$Object::Configure::_object_registry{'Test::Registerable'}}) > 0,
		'Object added to registry');

	# Cleanup
	delete $Object::Configure::_object_registry{'Test::Registerable'};

	done_testing();
};

subtest 'get_signal_handler_info() - returns info hash' => sub {
	my $info = Object::Configure::get_signal_handler_info();

	ok(ref($info) eq 'HASH', 'Returns hashref');
	ok(exists($info->{original_usr1}), 'Has original_usr1 key');
	ok(exists($info->{current_usr1}), 'Has current_usr1 key');
	ok(exists($info->{hot_reload_active}), 'Has hot_reload_active key');
	ok(exists($info->{watcher_pid}), 'Has watcher_pid key');

	done_testing();
};

subtest 'reload_config() - returns count' => sub {
	# Should return 0 when no objects registered
	my $count = Object::Configure::reload_config();

	ok(defined($count), 'Returns defined value');
	is($count, 0, 'Returns 0 when no objects registered');

	done_testing();
};

subtest 'disable_hot_reload() - safe to call when not enabled' => sub {
	lives_ok {
		Object::Configure::disable_hot_reload();
	} 'Safe to call when hot reload not enabled';

	done_testing();
};

subtest 'restore_signal_handlers() - safe to call when not set' => sub {
	lives_ok {
		Object::Configure::restore_signal_handlers();
	} 'Safe to call when no handlers were installed';

	done_testing();
};

subtest 'configure() - carp_on_warn is forwarded to the logger' => sub {
	# Premise 1: configure() extracts carp_on_warn from params.
	# Premise 2: _build_logger receives it and passes it to Log::Abstraction.
	# Conclusion: result->{logger}{carp_on_warn} == 1.
	my $result = Object::Configure::configure('Test::Class::CarpOnWarn', {
		carp_on_warn => 1,
		timeout      => 30,
	});

	isa_ok($result->{logger}, 'Log::Abstraction', 'Logger');
	is($result->{logger}{carp_on_warn}, 1, 'carp_on_warn propagated to logger');

	done_testing();
};

subtest 'configure() - croak_on_error=0 is preserved in result' => sub {
	# Prove the param survives the merge and is not reset by a default.
	my $result = Object::Configure::configure('Test::Class::CroakOnError', {
		croak_on_error => 0,
		timeout        => 30,
	});

	is($result->{croak_on_error}, 0, 'croak_on_error=0 preserved');

	done_testing();
};

subtest 'configure() - logger set to NULL' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);

	# Create an empty config file to prevent Config::Abstraction from
	# looking in default locations like ~/conf/local.yaml
	my $config_content = <<'EOF';
---
Test__Class__NullLogger__Unique__No__Config:
  timeout: 30
EOF
	create_test_config($temp_dir, 'empty.yml', $config_content);

	# Use a very unique class name that won't have config anywhere
	my $class = 'Test::Class::NullLogger::Unique::No::Config';
	my $params = {
		logger => 'NULL',
		timeout => 30,
		config_file => 'empty.yml',
		config_dirs => [$temp_dir]
	};

	my $result = Object::Configure::configure($class, $params);

	is($result->{logger}, 'NULL', 'Logger remains NULL when set to NULL');

	done_testing();
};

subtest 'configure() - preserves multiple coderefs' => sub {
	my $class = 'Test::Class::MultiCode';
	my $cb1 = sub { return 1 };
	my $cb2 = sub { return 2 };
	my $params = {
		on_error => $cb1,
		on_success => $cb2,
		timeout => 30
	};

	my $result = Object::Configure::configure($class, $params);

	is(ref($result->{on_error}), 'CODE', 'First coderef preserved');
	is(ref($result->{on_success}), 'CODE', 'Second coderef preserved');
	is($result->{on_error}->(), 1, 'First coderef works');
	is($result->{on_success}->(), 2, 'Second coderef works');

	done_testing();
};

subtest '_build_logger() - undef spec yields default Log::Abstraction' => sub {
	# Premise: undef means "no preference" — a default logger must be constructed.
	my $logger = Object::Configure::_build_logger(undef, 0);
	isa_ok($logger, 'Log::Abstraction', 'Default logger');

	done_testing();
};

subtest '_build_logger() - NULL string yields the literal NULL sentinel' => sub {
	# Premise: caller explicitly opts out of logging.
	# Conclusion: return value is the string 'NULL', not a blessed object.
	my $logger = Object::Configure::_build_logger('NULL', 0);
	is($logger, 'NULL', 'NULL sentinel returned as-is');
	ok(!blessed($logger), 'NULL sentinel is not blessed');

	done_testing();
};

subtest '_build_logger() - arrayref spec yields logger with array stash' => sub {
	my @buf;
	my $logger = Object::Configure::_build_logger(\@buf, 0);
	isa_ok($logger, 'Log::Abstraction', 'Logger from arrayref');
	is($logger->{array}, \@buf, 'Buffer wired into logger');

	done_testing();
};

subtest '_build_logger() - hashref spec merges options' => sub {
	my $logger = Object::Configure::_build_logger({ level => 'debug' }, 0);
	isa_ok($logger, 'Log::Abstraction', 'Logger from hashref');

	done_testing();
};

subtest '_build_logger() - blessed Log::Abstraction passes through unchanged' => sub {
	# Premise: caller already owns a logger instance — no reconstruction needed.
	# Conclusion: identity preserved (same reference returned).
	my $existing = Log::Abstraction->new();
	my $logger   = Object::Configure::_build_logger($existing, 0);
	is($logger, $existing, 'Pre-built logger returned by identity');

	done_testing();
};

subtest '_build_logger() - carp_on_warn forwarded for every constructing spec type' => sub {
	# Prove the flag reaches the object for the three constructing spec types.
	for my $spec (undef, { level => 'info' }, []) {
		my $label  = !defined($spec) ? 'undef' : (ref($spec) || $spec);
		my $logger = Object::Configure::_build_logger($spec, 1);
		is($logger->{carp_on_warn}, 1, "carp_on_warn=1 propagated for spec=$label");
	}

	done_testing();
};

subtest '_deep_merge() - three-level nesting: grandchild overrides grandparent' => sub {
	# Boundary: prove recursion depth >= 3 is correct (not just 2).
	my $base = { a => { b => { c => 1, d => 2 } } };
	my $over = { a => { b => { c => 9 } } };
	my $r    = Object::Configure::_deep_merge($base, $over);

	is($r->{a}{b}{c}, 9, 'Grandchild key overridden');
	is($r->{a}{b}{d}, 2, 'Sibling grandchild key preserved');

	done_testing();
};

subtest '_find_class_config_file() - finds file in same dir as primary (no config_dirs)' => sub {
	# Prove the base-dir probe works without config_dirs.
	# Premise: primary file and ancestor file share the same directory.
	my $temp_dir = tempdir(CLEANUP => 1);
	my $primary  = File::Spec->catfile($temp_dir, 'child.yml');
	open my $fh, '>', $primary or die $!;
	print $fh "---\n";
	close $fh;

	my $ancestor = File::Spec->catfile($temp_dir, 'my-ancestor.yml');
	open $fh, '>', $ancestor or die $!;
	print $fh "---\n";
	close $fh;

	my $found = Object::Configure::_find_class_config_file(
		'My::Ancestor',
		$primary,
		undef		# no config_dirs
	);

	ok(defined($found),                   'File found via primary dir');
	like($found, qr/my-ancestor\.yml$/, 'Correct ancestor filename');

	done_testing();
};

# =============================================================================
# Security guard S2: configure() class-name validation
# Premise: configure() rejects any $class that is not a syntactically legal Perl
# package name before it propagates into env_prefix, croak messages, or the cache.
# Each input below is a distinct equivalence partition with a unique failure mode.
# =============================================================================
subtest 'configure() - rejects invalid class names (S2 security guard)' => sub {
	my @bad_classes = (
		['1Bad',           'starts with digit'],
		['Bad::1Bad',      'component starts with digit'],
		['Bad|Class',      'shell pipe metachar'],
		["Bad\nClass",     'newline injection'],
		["Bad\0Class",     'null-byte injection'],
		['::Bad',          'leading double-colon (empty first component)'],
		['Bad@Class',      'at-sign'],
		['Bad Class',      'space character'],
	);

	for my $pair (@bad_classes) {
		my ($bad, $label) = @$pair;
		throws_ok {
			Object::Configure::configure($bad, {});
		} qr/configure: invalid class name/,
			"Croaks for $label";
	}

	# Boundary: the two smallest valid class names must NOT trigger the guard.
	lives_ok { Object::Configure::configure('A',  {}) } 'Single letter class is valid';
	lives_ok { Object::Configure::configure('_A', {}) } 'Underscore-prefixed class is valid';

	done_testing();
};

# =============================================================================
# Security guard S1: configure() path-traversal rejection in config_file
# Exploit: Config::Abstraction parses any readable file as conf.  A path like
# "../../etc/passwd" with $RE_PATH_TRAVERSAL sequences would reach the filesystem
# before the guard fires.  The guard must croak BEFORE any -r probe.
# =============================================================================
subtest 'configure() - path traversal in config_file triggers croak (S1 security guard)' => sub {
	my @traversal_paths = (
		'../etc/passwd',
		'../../etc/passwd',
		'foo/../etc/passwd',
		'/safe/../etc/passwd',
	);

	for my $path (@traversal_paths) {
		throws_ok {
			Object::Configure::configure('Test::PathTraversal::Guard', {
				config_file => $path,
			});
		} qr/config_file contains path traversal sequences/,
			"Croaks on traversal path: $path";
	}

	done_testing();
};

# =============================================================================
# configure() with undef params
# Premise: $_[1] // {} treats undef identically to an empty hashref.
# Conclusion: the result must be a valid config with a logger, not a crash.
# =============================================================================
subtest 'configure() - undef params argument treated as empty hashref' => sub {
	my $result = Object::Configure::configure('Test::UndefParams', undef);

	ok(ref($result) eq 'HASH', 'Returns hashref');
	ok(blessed($result->{logger}), 'Logger created from default');
	isa_ok($result->{logger}, 'Log::Abstraction', 'Logger');

	done_testing();
};

# =============================================================================
# configure() with environment variables (no config file)
# Premise: when no config_file is supplied, configure() merges env vars for the
# class and its ancestors via Config::Abstraction.
# =============================================================================
subtest 'configure() - env vars are merged when no config_file given' => sub {
	local %ENV;
	$ENV{'Test__EnvMerge__timeout'} = '99';

	my $result = Object::Configure::configure('Test::EnvMerge', {});

	is($result->{timeout}, 99, 'Env var Test__EnvMerge__timeout merged into result');

	done_testing();
};

# =============================================================================
# _build_logger() - scalar spec (non-NULL, non-ref, non-blessed)
# Premise: an arbitrary string is forwarded to Log::Abstraction as the 'logger' key.
# =============================================================================
subtest '_build_logger() - scalar spec forwarded to Log::Abstraction' => sub {
	my $logger = Object::Configure::_build_logger('syslog', 0);
	isa_ok($logger, 'Log::Abstraction', 'Logger created from scalar spec');

	done_testing();
};

# =============================================================================
# _reconfigure_logger()
# This private helper replaces a live object's logger from a new config spec.
# =============================================================================
subtest '_reconfigure_logger() - replaces logger in-place using new spec' => sub {
	my $obj = bless { carp_on_warn => 0, logger => Log::Abstraction->new() },
		'Test::Reconfigure';
	my $old_logger = $obj->{logger};

	Object::Configure::_reconfigure_logger($obj, 'logger', { level => 'debug' });

	ok(blessed($obj->{logger}), 'Logger key replaced with blessed object');
	isa_ok($obj->{logger}, 'Log::Abstraction', 'Replacement logger');
	isnt($obj->{logger}, $old_logger, 'A new instance was created, not the old one');

	done_testing();
};

subtest '_reconfigure_logger() - propagates carp_on_warn from object to new logger' => sub {
	# Premise 1: $obj->{carp_on_warn} = 1.
	# Premise 2: _reconfigure_logger reads carp_on_warn from $obj.
	# Conclusion: the new logger has carp_on_warn = 1.
	my $obj = bless { carp_on_warn => 1 }, 'Test::Reconfigure::CarpOnWarn';
	Object::Configure::_reconfigure_logger($obj, 'logger', {});

	is($obj->{logger}{carp_on_warn}, 1, 'carp_on_warn propagated from object to new logger');

	done_testing();
};

# =============================================================================
# _reload_object_config()
# Tests guard clauses and key-filtering logic of this private reload helper.
# =============================================================================
subtest '_reload_object_config() - returns early for an unblessed argument' => sub {
	# Guard: blessed() check must fire before any filesystem access.
	lives_ok {
		Object::Configure::_reload_object_config({ _config_file => '/etc/passwd' });
	} 'Silently ignores an unblessed hashref';

	done_testing();
};

subtest '_reload_object_config() - rejects path traversal in _config_file (S1b)' => sub {
	# Exploit: a deserialization gadget or malicious config merge could poison
	# $obj->{_config_file} with a traversal path, redirecting hot-reload to read
	# arbitrary system files.  The S1b guard must carp and return early.
	my $obj = bless { _config_file => '../../etc/passwd' },
		'Test::Reload::PathCheck';

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	Object::Configure::_reload_object_config($obj);

	ok(grep({ /traversal/i } @warnings),
		'carp emitted for traversal path in _config_file');

	done_testing();
};

subtest '_reload_object_config() - does not update private keys, does update public keys' => sub {
	# Private keys (^_) are intentionally skipped to protect internal bookkeeping.
	my $temp_dir = tempdir(CLEANUP => 1);
	my $config_content = <<'YAML';
---
Test__Reload__Private:
  public_key: updated_value
YAML
	my $config_file = create_test_config($temp_dir, 'test-reload-private.yml', $config_content);

	my $obj = bless {
		_config_file => $config_file,
		public_key   => 'original',
		_private_key => 'preserved',
	}, 'Test::Reload::Private';

	Object::Configure::_reload_object_config($obj);

	is($obj->{public_key},   'updated_value', 'Public key updated from reloaded config file');
	is($obj->{_private_key}, 'preserved',     'Private key not overwritten (skipped by ^_ guard)');

	done_testing();
};

# =============================================================================
# register_object() — weak-reference storage
# Premise: Scalar::Util::weaken is applied so the registry does not keep objects alive.
# =============================================================================
subtest 'register_object() - stores a weak reference to the object' => sub {
	my $obj = bless { value => 42 }, 'Test::WeakRefCheck';
	Object::Configure::register_object('Test::WeakRefCheck', $obj);

	my $stored_ref = $Object::Configure::_object_registry{'Test::WeakRefCheck'}[-1];

	# $$stored_ref is the scalar that was weakened by weaken($$obj_ref) in register_object.
	ok(isweak($$stored_ref), 'Registry entry holds a weak reference to the object');

	# Cleanup so it does not interfere with reload_config() tests.
	delete $Object::Configure::_object_registry{'Test::WeakRefCheck'};

	done_testing();
};

# =============================================================================
# get_signal_handler_info() — hot_reload_active reflects real state
# =============================================================================
subtest 'get_signal_handler_info() - hot_reload_active matches $_original_usr1_handler state' => sub {
	my $info = Object::Configure::get_signal_handler_info();

	is(
		$info->{hot_reload_active},
		defined($Object::Configure::_original_usr1_handler) ? 1 : 0,
		'hot_reload_active is true IFF $_original_usr1_handler is defined'
	);

	done_testing();
};

# =============================================================================
# restore_signal_handlers() — after synthetic handler installation
# =============================================================================
subtest 'restore_signal_handlers() - clears handler state and restores SIG{USR1}' => sub {
	SKIP: {
		skip 'SIGUSR1 not available on Windows', 2 if $^O eq 'MSWin32';

		# Temporarily fake the installed-handler state so we can verify restoration.
		local $Object::Configure::_original_usr1_handler;
		local $SIG{USR1};

		$Object::Configure::_original_usr1_handler = 'DEFAULT';
		$SIG{USR1} = sub { };    # synthetic placeholder handler

		Object::Configure::restore_signal_handlers();

		ok(!defined($Object::Configure::_original_usr1_handler),
			'$_original_usr1_handler cleared after restore');
		is($SIG{USR1}, 'DEFAULT', 'SIG{USR1} restored to the saved value');
	}

	done_testing();
};

# =============================================================================
# enable_hot_reload() — early-return guard when already watching
# Premise: if %_config_watchers is non-empty, a second call must return immediately
# without forking another child (which would leave an orphaned watcher process).
# =============================================================================
subtest 'enable_hot_reload() - returns early when watcher already active' => sub {
	SKIP: {
		skip 'SIGUSR1 not available on Windows', 1 if $^O eq 'MSWin32';

		local %Object::Configure::_config_watchers;
		$Object::Configure::_config_watchers{pid} = 99999;    # fake active watcher

		my $ret = Object::Configure::enable_hot_reload(interval => 5);

		ok(!defined($ret), 'Returns undef when watcher already active (no double-fork)');
	}

	done_testing();
};

# =============================================================================
# _find_class_config_file() — config_dirs element with trailing slash
# Premise: the trailing-slash strip uses a COPY of $dir, not an alias.
# Conclusion: the caller's config_dirs array element must be unchanged after the call.
# =============================================================================
subtest '_find_class_config_file() - trailing slash in config_dirs is stripped without mutating caller' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'my-trailing.yml', "---\ntest: 1\n");

	my @dirs = ("$temp_dir/");    # intentional trailing slash
	my $orig = $dirs[0];          # captured before the call

	# Clear cache so this fresh temp_dir is not shadowed by a prior undef sentinel.
	my $cache_key = join("\0", 'My::Trailing', 'base.yml', $dirs[0]);
	delete $Object::Configure::_find_cache{$cache_key};

	my $found = Object::Configure::_find_class_config_file(
		'My::Trailing',
		'base.yml',
		\@dirs
	);

	ok(defined($found),             'File found despite trailing slash in config_dirs entry');
	like($found, qr/my-trailing\.yml$/, 'Correct filename returned');
	is($dirs[0], $orig,             'config_dirs element not mutated by the trailing-slash strip');

	done_testing();
};

# =============================================================================
# _get_inheritance_chain() — memoization cache populated on first call
# Premise: %_chain_cache is populated after the first call; second call is O(1).
# =============================================================================
subtest '_get_inheritance_chain() - populates %_chain_cache on first call' => sub {
	my $class = 'Test::Memo::Chain::New';
	delete $Object::Configure::_chain_cache{$class};    # ensure cold start

	my @chain1 = Object::Configure::_get_inheritance_chain($class);
	ok(exists($Object::Configure::_chain_cache{$class}), 'Cache entry created after first call');

	my @chain2 = Object::Configure::_get_inheritance_chain($class);
	is_deeply(\@chain1, \@chain2, 'Second (memoized) call returns identical chain');

	done_testing();
};

# =============================================================================
# _deep_merge() — arrayref in overlay replaces base arrayref wholesale
# Design invariant: arrays are NOT merged element-by-element; overlay wins entirely.
# =============================================================================
subtest '_deep_merge() - arrayref overlay replaces base arrayref wholesale' => sub {
	my $base    = { list => [1, 2, 3], other => 'keep' };
	my $overlay = { list => [4, 5] };

	my $result = Object::Configure::_deep_merge($base, $overlay);

	is_deeply($result->{list}, [4, 5], 'Overlay arrayref replaces base arrayref entirely');
	is($result->{other}, 'keep',       'Unrelated base key preserved');

	done_testing();
};

# =============================================================================
# Memory cycle check — configure() result must be GC-friendly
# =============================================================================
subtest 'configure() result has no circular references (memory-cycle check)' => sub {
	eval { require Test::Memory::Cycle; 1 } or do {
		plan skip_all => 'Test::Memory::Cycle not installed';
		return;
	};

	my $result = Object::Configure::configure('Test::MemCycle', { foo => 'bar' });

	Test::Memory::Cycle::memory_cycle_ok($result, 'No circular refs in configure() output');

	done_testing();
};

done_testing();

