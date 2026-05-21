#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Test::Mockingbird 0.10;
use File::Temp qw(tempdir);
use File::Spec;
use Scalar::Util qw(blessed);

# Load the module under test
BEGIN { use_ok('Object::Configure') }

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

done_testing();
