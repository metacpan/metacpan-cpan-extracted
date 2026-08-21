#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Test::Mockingbird 0.10;
use File::Temp qw(tempdir);
use File::Spec;
use Readonly;
use Scalar::Util qw(blessed);

# Load the module under test
BEGIN { use_ok('Object::Configure') }

# ============================================================================
# API MESSAGE LEDGER
# All POD-documented error/warning messages are tracked here.  New subtests
# below delete an entry once they prove the condition is properly triggered.
# The final subtest asserts the ledger is empty; any remaining entry represents
# a POD message that is untested.
#
# Pre-deleted (covered by existing subtests earlier in this file):
#   msg_what_class      - 'configure() - API: requires class parameter'
#   msg_unreadable_file - 'configure() - API: throws on unreadable config file'
#   msg_register_usage  - 'register_object() - API: requires {class,object} parameter'
# ============================================================================
my %ledger = (
	msg_invalid_class => 'configure: invalid class name (must be a valid Perl package name): CLASS',
	msg_traversal     => 'CLASS: config_file contains path traversal sequences: FILE',
	msg_load_warning  => "Warning: Can't load configuration from FILE: DETAIL",
);

# Mock helper: create temp config file
sub create_test_config {
	my ($dir, $filename, $content) = @_;
	my $path = File::Spec->catfile($dir, $filename);
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print $fh $content;
	close $fh;
	return $path;
}

subtest 'configure() - API: requires class parameter' => sub {
	plan tests => 1;

	throws_ok {
		Object::Configure::configure(undef, {});
	} qr/configure: what class do you want to configure/,
		'Croaks when class is undef';
};

subtest 'configure() - API: accepts optional params hashref' => sub {
	plan tests => 3;

	my $result1 = Object::Configure::configure('Test::Class::One');
	ok(defined($result1), 'Works with no params');

	my $result2 = Object::Configure::configure('Test::Class::Two', {});
	ok(defined($result2), 'Works with empty hashref');

	my $result3 = Object::Configure::configure('Test::Class::Three', { foo => 'bar' });
	ok(defined($result3), 'Works with params');
};

subtest 'configure() - API: returns hashref' => sub {
	plan tests => 1;

	my $result = Object::Configure::configure('Test::Class', { timeout => 30 });

	is(ref($result), 'HASH', 'Returns hashref');
};

subtest 'configure() - API: preserves input parameters' => sub {
	plan tests => 3;

	my $result = Object::Configure::configure('Test::Class', {
		timeout => 30,
		retries => 3,
		custom_param => 'value'
	});

	is($result->{timeout}, 30, 'Timeout preserved');
	is($result->{retries}, 3, 'Retries preserved');
	is($result->{custom_param}, 'value', 'Custom param preserved');
};

subtest 'configure() - API: initializes logger' => sub {
	plan tests => 2;

	my $result = Object::Configure::configure('Test::Class', {});

	ok(exists($result->{logger}), 'Logger key exists');
	ok(blessed($result->{logger}), 'Logger is an object');
};

subtest 'configure() - API: accepts logger as hashref' => sub {
	plan tests => 2;

	my $result = Object::Configure::configure('Test::Class', {
		logger => { level => 'debug' }
	});

	ok(blessed($result->{logger}), 'Logger created from hashref');
	isa_ok($result->{logger}, 'Log::Abstraction');
};

subtest 'configure() - API: accepts logger as coderef' => sub {
	plan tests => 2;

	my $log_sub = sub { warn "log: @_" };
	my $result = Object::Configure::configure('Test::Class', {
		logger => $log_sub
	});

	ok(blessed($result->{logger}), 'Logger created from coderef');
	isa_ok($result->{logger}, 'Log::Abstraction');
};

subtest 'configure() - API: preserves coderefs in params' => sub {
	plan tests => 3;

	my $callback = sub { return 'test' };
	my $result = Object::Configure::configure('Test::Class', {
		on_error => $callback
	});

	ok(exists($result->{on_error}), 'Coderef param exists');
	is(ref($result->{on_error}), 'CODE', 'Is still a coderef');
	is($result->{on_error}, $callback, 'Same coderef returned');
};

subtest 'configure() - API: preserves blessed objects in params' => sub {
	plan tests => 3;

	my $obj = bless { data => 'test' }, 'Custom::Class';
	my $result = Object::Configure::configure('Test::Class', {
		custom_obj => $obj
	});

	ok(exists($result->{custom_obj}), 'Object param exists');
	ok(blessed($result->{custom_obj}), 'Is still blessed');
	is($result->{custom_obj}, $obj, 'Same object returned');
};

subtest 'configure() - API: loads config file when provided' => sub {
	plan tests => 4;

	my $temp_dir = tempdir(CLEANUP => 1);
	my $config_content = <<'EOF';
---
Test__Config__Class:
  from_config: "yes"
  config_timeout: 60
EOF
	create_test_config($temp_dir, 'test.yml', $config_content);

	my $result = Object::Configure::configure('Test::Config::Class', {
		config_file => 'test.yml',
		config_dirs => [$temp_dir],
		param_timeout => 30
	});

	is($result->{from_config}, 'yes', 'Loaded value from config');
	is($result->{config_timeout}, 60, 'Config timeout loaded');
	is($result->{param_timeout}, 30, 'Param preserved alongside config');
	ok(defined($result->{_config_file}), '_config_file metadata set');
};

subtest 'configure() - API: throws on unreadable config file' => sub {
	plan tests => 1;

	throws_ok {
		Object::Configure::configure('Test::Class', {
			config_file => '/nonexistent/path/config.yml'
		});
	} qr/Test__Class:.*\/nonexistent\/path\/config\.yml/,
		'Throws with file path in message';
};

subtest 'configure() - API: handles carp_on_warn parameter' => sub {
	plan tests => 1;

	my $result = Object::Configure::configure('Test::Class', {
		carp_on_warn => 1
	});

	ok(blessed($result->{logger}), 'Logger created with carp_on_warn');
};

subtest 'configure() - API: handles croak_on_error parameter' => sub {
	plan tests => 1;

	my $result = Object::Configure::configure('Test::Class', {
		croak_on_error => 0
	});

	ok(blessed($result->{logger}), 'Logger created with croak_on_error');
};

subtest 'configure() - API: handles logger=NULL' => sub {
	plan tests => 1;

	my $temp_dir = tempdir(CLEANUP => 1);
	my $config_content = "---\nTest__Null__Logger:\n  timeout: 30\n";
	create_test_config($temp_dir, 'null.yml', $config_content);

	my $result = Object::Configure::configure('Test::Null::Logger', {
		logger => 'NULL',
		config_file => 'null.yml',
		config_dirs => [$temp_dir]
	});

	is($result->{logger}, 'NULL', 'Logger remains NULL');
};

subtest 'instantiate() - API: requires class parameter' => sub {
	plan tests => 2;

	{
		package Test::Instantiable::One;
		sub new { my ($class, $params) = @_; bless $params, $class }
	}

	my $obj = Object::Configure::instantiate(
		class => 'Test::Instantiable::One',
		timeout => 30
	);

	ok(defined($obj), 'Object created');
	ok(blessed($obj), 'Object is blessed');
};

subtest 'instantiate() - API: returns blessed object of specified class' => sub {
	plan tests => 2;

	{
		package Test::Instantiable::Two;
		sub new { my ($class, $params) = @_; bless $params, $class }
	}

	my $obj = Object::Configure::instantiate(
		class => 'Test::Instantiable::Two'
	);

	isa_ok($obj, 'Test::Instantiable::Two');
	is(ref($obj), 'Test::Instantiable::Two', 'Correct class');
};

subtest 'instantiate() - API: passes params to constructor' => sub {
	plan tests => 2;

	{
		package Test::Instantiable::Three;
		sub new { my ($class, $params) = @_; bless $params, $class }
	}

	my $obj = Object::Configure::instantiate(
		class => 'Test::Instantiable::Three',
		timeout => 30,
		custom => 'value'
	);

	is($obj->{timeout}, 30, 'Timeout passed');
	is($obj->{custom}, 'value', 'Custom param passed');
};

subtest 'instantiate() - API: configures object before creation' => sub {
	plan tests => 1;

	{
		package Test::Instantiable::Four;
		sub new { my ($class, $params) = @_; bless $params, $class }
	}

	my $obj = Object::Configure::instantiate(
		class => 'Test::Instantiable::Four'
	);

	ok(blessed($obj->{logger}), 'Logger configured');
};

subtest 'register_object() - API: requires class parameter' => sub {
	plan tests => 1;

	my $obj = bless {}, 'Test::Class';

	throws_ok {
		Object::Configure::register_object(undef, $obj);
	} qr/register_object: Usage/, 'Throws without class';
};

subtest 'register_object() - API: requires object parameter' => sub {
	plan tests => 1;

	throws_ok {
		Object::Configure::register_object('Test::Class', undef);
	} qr/register_object: Usage/, 'Throws without object';
};

subtest 'register_object() - API: accepts blessed object' => sub {
	plan tests => 1;

	my $obj = bless { foo => 'bar' }, 'Test::Registerable';

	lives_ok {
		Object::Configure::register_object('Test::Registerable', $obj);
	} 'Accepts blessed object';

	# Cleanup
	delete $Object::Configure::_object_registry{'Test::Registerable'};
};

subtest 'register_object() - API: returns nothing' => sub {
	plan tests => 1;

	my $obj = bless {}, 'Test::Class';
	my $result = Object::Configure::register_object('Test::Class', $obj);

	ok(!defined($result), 'Returns undef/nothing');

	# Cleanup
	delete $Object::Configure::_object_registry{'Test::Class'};
};

subtest 'reload_config() - API: takes no parameters' => sub {
	plan tests => 1;

	lives_ok {
		Object::Configure::reload_config();
	} 'Can be called with no args';
};

subtest 'reload_config() - API: returns integer count' => sub {
	plan tests => 2;

	my $count = Object::Configure::reload_config();

	ok(defined($count), 'Returns defined value');
	like($count, qr/^\d+$/, 'Returns integer');
};

subtest 'reload_config() - API: returns zero when no objects registered' => sub {
	plan tests => 1;

	my $count = Object::Configure::reload_config();

	is($count, 0, 'Returns 0 when registry empty');
};

subtest 'enable_hot_reload() - API: accepts optional interval parameter' => sub {
	plan tests => 1;

	SKIP: {
		skip 'Hot reload not supported on Windows', 1 if $^O eq 'MSWin32';
		skip 'Skipping fork test to avoid background processes', 1;

		my $pid = Object::Configure::enable_hot_reload(interval => 5);
		ok($pid > 0, 'Returns PID');

		Object::Configure::disable_hot_reload();
	}
};

subtest 'enable_hot_reload() - API: accepts optional callback parameter' => sub {
	plan tests => 1;

	SKIP: {
		skip 'Hot reload not supported on Windows', 1 if $^O eq 'MSWin32';
		skip 'Skipping fork test to avoid background processes', 1;

		my $called = 0;
		my $pid = Object::Configure::enable_hot_reload(
			callback => sub { $called = 1 }
		);

		ok($pid > 0, 'Accepts callback');

		Object::Configure::disable_hot_reload();
	}
};

subtest 'enable_hot_reload() - API: returns PID' => sub {
	plan tests => 1;

	SKIP: {
		skip 'Hot reload not supported on Windows', 1 if $^O eq 'MSWin32';
		skip 'Skipping fork test to avoid background processes', 1;

		my $pid = Object::Configure::enable_hot_reload();

		like($pid, qr/^\d+$/, 'Returns integer PID');

		Object::Configure::disable_hot_reload();
	}
};

subtest 'disable_hot_reload() - API: takes no parameters' => sub {
	plan tests => 1;

	lives_ok {
		Object::Configure::disable_hot_reload();
	} 'Can be called with no args';
};

subtest 'disable_hot_reload() - API: returns nothing' => sub {
	plan tests => 1;

	my $result = Object::Configure::disable_hot_reload();

	ok(!defined($result), 'Returns undef/nothing');
};

subtest 'disable_hot_reload() - API: safe to call when not enabled' => sub {
	plan tests => 1;

	lives_ok {
		Object::Configure::disable_hot_reload();
		Object::Configure::disable_hot_reload();
	} 'Safe to call multiple times';
};

subtest 'restore_signal_handlers() - API: takes no parameters' => sub {
	plan tests => 1;

	lives_ok {
		Object::Configure::restore_signal_handlers();
	} 'Can be called with no args';
};

subtest 'restore_signal_handlers() - API: returns nothing' => sub {
	plan tests => 1;

	my $result = Object::Configure::restore_signal_handlers();

	ok(!defined($result), 'Returns undef/nothing');
};

subtest 'restore_signal_handlers() - API: safe to call when not set' => sub {
	plan tests => 1;

	lives_ok {
		Object::Configure::restore_signal_handlers();
		Object::Configure::restore_signal_handlers();
	} 'Safe to call multiple times';
};

subtest 'get_signal_handler_info() - API: takes no parameters' => sub {
	plan tests => 1;

	lives_ok {
		Object::Configure::get_signal_handler_info();
	} 'Can be called with no args';
};

subtest 'get_signal_handler_info() - API: returns hashref' => sub {
	plan tests => 1;

	my $info = Object::Configure::get_signal_handler_info();

	is(ref($info), 'HASH', 'Returns hashref');
};

subtest 'get_signal_handler_info() - API: hashref contains required keys' => sub {
	plan tests => 4;

	my $info = Object::Configure::get_signal_handler_info();

	ok(exists($info->{original_usr1}), 'Has original_usr1 key');
	ok(exists($info->{current_usr1}), 'Has current_usr1 key');
	ok(exists($info->{hot_reload_active}), 'Has hot_reload_active key');
	ok(exists($info->{watcher_pid}), 'Has watcher_pid key');
};

subtest 'get_signal_handler_info() - API: hot_reload_active is boolean' => sub {
	plan tests => 1;

	my $info = Object::Configure::get_signal_handler_info();

	ok($info->{hot_reload_active} == 0 || $info->{hot_reload_active} == 1,
		'hot_reload_active is boolean');
};

# =============================================================================
# NEW SUBTESTS — covers POD messages and invariants not addressed above
# =============================================================================

# --- LEDGER: msg_invalid_class ---
# Security guard S2: class name must match /\A[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*\z/.
# The test exercises two representative invalid-class partitions; t/function.t has
# exhaustive per-case coverage.  Here we verify the documented message text.
subtest 'configure() - API: croaks on invalid class name (S2 guard)' => sub {
	plan tests => 3;

	throws_ok {
		Object::Configure::configure('1BadClass', {});
	} qr/configure: invalid class name/, 'Class starting with digit is rejected';

	throws_ok {
		Object::Configure::configure("Foo\nBar", {});
	} qr/configure: invalid class name/, 'Class with newline is rejected';

	# Boundary: a valid class must NOT trigger this guard.
	lives_ok {
		Object::Configure::configure('Valid::Class', {});
	} 'Valid class name is accepted';

	delete $ledger{msg_invalid_class};
};

# --- LEDGER: msg_traversal ---
# Security guard S1: config_file paths containing ".." are rejected before any
# filesystem probe so Config::Abstraction cannot be redirected to /etc/passwd.
subtest 'configure() - API: croaks on path traversal in config_file (S1 guard)' => sub {
	plan tests => 2;

	throws_ok {
		Object::Configure::configure('Test::Traversal::Unit', {
			config_file => '../../etc/passwd',
		});
	} qr/config_file contains path traversal sequences/,
		'Traversal path rejected with documented message';

	throws_ok {
		Object::Configure::configure('Test::Traversal::Unit', {
			config_file => 'foo/../bar.yml',
		});
	} qr/config_file contains path traversal sequences/,
		'Embedded traversal segment rejected';

	delete $ledger{msg_traversal};
};

# --- LEDGER: msg_load_warning ---
# Forces the "Warning: Can't load configuration from FILE: DETAIL" carp by
# monkey-patching Config::Abstraction::new to return a falsy value with $@ set.
# This is the only condition that requires mocking — the real Config::Abstraction
# always returns a truthy object when given a readable file.
subtest "configure() - API: emits warning when Config::Abstraction fails to parse file" => sub {
	plan tests => 1;

	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'bad.yml', "---\nTest__ParseFail:\n  key: val\n");

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	# Monkey-patch: simulate a Config::Abstraction parse failure.  The config_file
	# path lands in @config_files_to_load (file is readable), then the mocked
	# constructor returns 0 + sets $@ so the elsif($@) branch fires.
	{
		no warnings 'redefine';
		local *Config::Abstraction::new = sub {
			$@ = 'Mock YAML parse error at line 1';
			return 0;
		};

		eval {
			Object::Configure::configure('Test::ParseFail', {
				config_file => 'bad.yml',
				config_dirs => [$temp_dir],
			});
		};
	}

	ok(grep({ /Can't load configuration/i } @warnings),
		"carp emitted with documented message when Config::Abstraction returns falsy");

	delete $ledger{msg_load_warning};
};

# --- Global state: $@ must not be clobbered ---
# configure() uses `local $@` so that internal eval blocks (in Config::Abstraction,
# Log::Abstraction, Return::Set) cannot permanently corrupt the caller's $@.
subtest 'configure() - API: does not clobber caller $@' => sub {
	plan tests => 1;

	$@ = 'caller_error_sentinel';
	Object::Configure::configure('Test::DollarAt', {});

	is($@, 'caller_error_sentinel', '$@ preserved across configure() call');
};

# --- Global state: alarm() must not be reset ---
# None of the configure() paths call sleep() or set alarm(); the timer must survive.
subtest 'configure() - API: does not clobber alarm()' => sub {
	plan tests => 2;

	alarm(120);
	lives_ok { Object::Configure::configure('Test::AlarmCheck', {}) }
		'configure() runs successfully while alarm is active';
	my $remaining = alarm(0);    # cancel and capture remaining time

	ok($remaining > 0, 'alarm() countdown not reset by configure()');
};

# --- _config_files arrayref metadata ---
# The POD documents _config_files as an arrayref of all loaded config file paths.
subtest 'configure() - API: _config_files is arrayref of loaded paths' => sub {
	plan tests => 2;

	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'cfg.yml', "---\nTest__CfgFiles:\n  k: v\n");

	my $result = Object::Configure::configure('Test::CfgFiles', {
		config_file => 'cfg.yml',
		config_dirs => [$temp_dir],
	});

	ok(ref($result->{_config_files}) eq 'ARRAY', '_config_files is an arrayref');
	ok(scalar(@{ $result->{_config_files} }) > 0,  '_config_files contains at least one path');
};

# --- Arrayref logger priority ---
# The POD states: "A caller-supplied logger value (arrayref, ...) always overrides
# any logger: key in the config file."
subtest 'configure() - API: caller arrayref logger wins over config-file logger spec' => sub {
	plan tests => 1;

	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'lgr.yml',
		"---\nTest__LogPriority:\n  logger:\n    level: debug\n");

	my @capture;
	my $result = Object::Configure::configure('Test::LogPriority', {
		config_file => 'lgr.yml',
		config_dirs => [$temp_dir],
		logger      => \@capture,
	});

	is($result->{logger}{array}, \@capture,
		'Caller arrayref logger wired into Log::Abstraction (not replaced by config-file spec)');
};

# --- instantiate() registers object when config_file is present ---
# The POD side-effects say register_object is called when _config_file is set.
subtest 'instantiate() - API: registers object for hot reload when config_file given' => sub {
	plan tests => 2;

	{
		package Test::Instantiable::Reg;
		sub new { my ($class, $params) = @_; bless $params, $class }
	}

	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'ireg.yml',
		"---\nTest__Instantiable__Reg:\n  value: from_config\n");

	my $obj = Object::Configure::instantiate(
		class       => 'Test::Instantiable::Reg',
		config_file => 'ireg.yml',
		config_dirs => [$temp_dir],
	);

	ok(blessed($obj), 'Object is blessed');
	ok(exists($Object::Configure::_object_registry{'Test::Instantiable::Reg'}),
		'Object registered in _object_registry (hot reload side-effect documented in POD)');

	# Cleanup so the registry does not leak into reload_config() tests.
	delete $Object::Configure::_object_registry{'Test::Instantiable::Reg'};
};

# --- Ledger completion check ---
# Any remaining ledger entry represents a POD-documented message that no subtest
# above exercised.  fail() makes the omission visible and actionable.
subtest 'API ledger: all documented messages were exercised' => sub {
	if(%ledger) {
		for my $key (sort keys %ledger) {
			fail("Untested POD message '$key': $ledger{$key}");
		}
	} else {
		pass('All documented messages were triggered by subtests');
	}

	done_testing();
};

done_testing();
