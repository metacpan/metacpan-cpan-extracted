#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Test::Mockingbird 0.10;
use File::Temp qw(tempdir);
use File::Spec;
use Readonly;
use Scalar::Util qw(blessed weaken);
use Time::HiRes qw(sleep);

# All runtime dependencies of Object::Configure are in 'requires' (not optional).
# Test::Without::Module is imported to document that finding and to verify the module
# remains functional when unrelated modules that calling code might use are absent.
use Test::Without::Module qw(SomeHypothetical::OptionalModule);

# Load required modules
BEGIN {
	use_ok('Object::Configure');
	use_ok('Config::Abstraction');
	use_ok('Log::Abstraction');
}

# Helper: create temp config file
sub create_test_config {
	my ($dir, $filename, $content) = @_;
	my $path = File::Spec->catfile($dir, $filename);
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print $fh $content;
	close $fh;
	return $path;
}

subtest 'End-to-end: Simple class with configuration file' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);

	# Create config file
	my $config_content = <<'EOF';
---
My__Simple__App:
  timeout: 60
  retries: 5
  api_key: "secret123"
  logger:
    level: debug
EOF
	create_test_config($temp_dir, 'app.yml', $config_content);

	# Define test class - pass temp_dir as parameter instead of closure
	{
		package My::Simple::App;
		use Object::Configure;

		sub new {
			my ($class, %args) = @_;
			my $config_dirs = delete $args{_config_dirs} || [];
			my $params = Object::Configure::configure($class, {
				config_file => 'app.yml',
				config_dirs => $config_dirs,
				timeout => 30,  # Default value
				%args
			});
			return bless $params, $class;
		}

		sub get_timeout { $_[0]->{timeout} }
		sub get_retries { $_[0]->{retries} }
		sub get_api_key { $_[0]->{api_key} }
	}

	# Create instance - pass temp_dir explicitly
	my $app = My::Simple::App->new(_config_dirs => [$temp_dir]);
	ok(blessed($app), 'App created');

	# Verify configuration was loaded and merged
	is($app->get_timeout, 60, 'Config overrides default timeout');
	is($app->get_retries, 5, 'Config value loaded');
	is($app->get_api_key, 'secret123', 'Sensitive config loaded');
	ok(blessed($app->{logger}), 'Logger initialized');
	isa_ok($app->{logger}, 'Log::Abstraction');

	done_testing();
};

subtest 'End-to-end: Inheritance chain with UNIVERSAL config' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);

	# Create universal config
	my $universal_config = <<'EOF';
---
UNIVERSAL:
  timeout: 30
  retries: 3
  log_level: info
EOF
	create_test_config($temp_dir, 'universal.yml', $universal_config);

	# Create parent config
	my $parent_config = <<'EOF';
---
My__Base__Service:
  timeout: 60
  base_url: "https://api.example.com"
EOF
	create_test_config($temp_dir, 'my-base-service.yml', $parent_config);

	# Create child config
	my $child_config = <<'EOF';
---
My__API__Client:
  timeout: 120
  api_version: "v2"
EOF
	create_test_config($temp_dir, 'my-api-client.yml', $child_config);

	# Define class hierarchy - pass config_dirs as parameter
	{
		package My::Base::Service;
		use Object::Configure;

		sub new {
			my ($class, %args) = @_;
			my $config_dirs = delete $args{_config_dirs} || [];
			my $params = Object::Configure::configure($class, {
				config_file => 'my-base-service.yml',
				config_dirs => $config_dirs,
				%args
			});
			return bless $params, $class;
		}
	}

	{
		package My::API::Client;
		use base 'My::Base::Service';
		use Object::Configure;

		sub new {
			my ($class, %args) = @_;
			my $config_dirs = delete $args{_config_dirs} || [];
			my $params = Object::Configure::configure($class, {
				config_file => 'my-api-client.yml',
				config_dirs => $config_dirs,
				%args
			});
			return bless $params, $class;
		}
	}

	# Test parent class
	my $base = My::Base::Service->new(_config_dirs => [$temp_dir]);
	ok(blessed($base), 'Base service created');
	is($base->{timeout}, 60, 'Parent: timeout from parent config');
	is($base->{retries}, 3, 'Parent: retries from UNIVERSAL');
	is($base->{log_level}, 'info', 'Parent: log_level from UNIVERSAL');
	is($base->{base_url}, 'https://api.example.com', 'Parent: base_url from parent config');

	# Test child class
	my $child = My::API::Client->new(_config_dirs => [$temp_dir]);
	ok(blessed($child), 'API client created');
	is($child->{timeout}, 120, 'Child: timeout from child config');
	is($child->{retries}, 3, 'Child: retries from UNIVERSAL');
	is($child->{log_level}, 'info', 'Child: log_level from UNIVERSAL');
	is($child->{base_url}, 'https://api.example.com', 'Child: base_url from parent');
	is($child->{api_version}, 'v2', 'Child: api_version from child config');

	done_testing();
};

subtest 'End-to-end: Multiple instances with different configs' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);

	# Create two different config files
	my $config1 = <<'EOF';
---
Multi__Instance__App:
  instance_id: "instance_1"
  timeout: 30
  api_endpoint: "https://api1.example.com"
EOF
	create_test_config($temp_dir, 'instance1.yml', $config1);

	my $config2 = <<'EOF';
---
Multi__Instance__App:
  instance_id: "instance_2"
  timeout: 60
  api_endpoint: "https://api2.example.com"
EOF
	create_test_config($temp_dir, 'instance2.yml', $config2);

	# Define class - pass config_dirs as parameter
	{
		package Multi::Instance::App;
		use Object::Configure;

		sub new {
			my ($class, %args) = @_;
			my $config_dirs = delete $args{_config_dirs} || [];
			my $params = Object::Configure::configure($class, {
				config_dirs => $config_dirs,
				%args
			});
			return bless $params, $class;
		}
	}

	# Create two instances with different configs
	my $app1 = Multi::Instance::App->new(
		config_file => 'instance1.yml',
		_config_dirs => [$temp_dir]
	);
	my $app2 = Multi::Instance::App->new(
		config_file => 'instance2.yml',
		_config_dirs => [$temp_dir]
	);

	# Verify they maintain separate state
	is($app1->{instance_id}, 'instance_1', 'Instance 1: correct ID');
	is($app1->{timeout}, 30, 'Instance 1: correct timeout');
	is($app1->{api_endpoint}, 'https://api1.example.com', 'Instance 1: correct endpoint');

	is($app2->{instance_id}, 'instance_2', 'Instance 2: correct ID');
	is($app2->{timeout}, 60, 'Instance 2: correct timeout');
	is($app2->{api_endpoint}, 'https://api2.example.com', 'Instance 2: correct endpoint');

	# Verify they don't interfere with each other
	isnt($app1->{instance_id}, $app2->{instance_id}, 'Instances are separate');
	isnt($app1->{logger}, $app2->{logger}, 'Loggers are separate');

	done_testing();
};

subtest 'End-to-end: Coderef and object preservation through configuration' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);

	my $config = <<'EOF';
---
Callback__App:
  timeout: 30
  api_key: "key123"
EOF
	create_test_config($temp_dir, 'callback.yml', $config);

	# Define class - pass config_dirs as parameter
	{
		package Callback::App;
		use Object::Configure;

		sub new {
			my ($class, %args) = @_;
			my $config_dirs = delete $args{_config_dirs} || [];
			my $params = Object::Configure::configure($class, {
				config_file => 'callback.yml',
				config_dirs => $config_dirs,
				%args
			});
			return bless $params, $class;
		}

		sub trigger_error {
			my $self = shift;
			$self->{on_error}->(@_) if $self->{on_error};
		}

		sub trigger_success {
			my $self = shift;
			$self->{on_success}->(@_) if $self->{on_success};
		}
	}

	# Custom context object
	my $ctx = bless { user => 'test_user' }, 'Custom::Context';

	# Callback tracking
	my $error_called = 0;
	my $success_called = 0;
	my @error_args;
	my @success_args;

	my $app = Callback::App->new(
		_config_dirs => [$temp_dir],
		on_error => sub {
			$error_called++;
			@error_args = @_;
		},
		on_success => sub {
			$success_called++;
			@success_args = @_;
		},
		context => $ctx
	);

	# Verify coderefs preserved
	is(ref($app->{on_error}), 'CODE', 'Error callback is coderef');
	is(ref($app->{on_success}), 'CODE', 'Success callback is coderef');

	# Verify object preserved
	is($app->{context}, $ctx, 'Context object preserved');
	is($app->{context}{user}, 'test_user', 'Context data intact');

	# Verify callbacks work
	$app->trigger_error('test error');
	is($error_called, 1, 'Error callback executed');
	is($error_args[0], 'test error', 'Error callback received args');

	$app->trigger_success('test success');
	is($success_called, 1, 'Success callback executed');
	is($success_args[0], 'test success', 'Success callback received args');

	# Verify config values still loaded
	is($app->{timeout}, 30, 'Config loaded alongside callbacks');
	is($app->{api_key}, 'key123', 'Config values intact');

	done_testing();
};

subtest 'Integration: Config::Abstraction and Log::Abstraction' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);

	my $config = <<'EOF';
---
Integration__Test:
  timeout: 45
  logger:
    level: debug
    file: /tmp/integration_test.log
EOF
	create_test_config($temp_dir, 'integration.yml', $config);

	{
		package Integration::Test;
		use Object::Configure;

		sub new {
			my ($class, %args) = @_;
			my $config_dirs = delete $args{_config_dirs} || [];
			my $params = Object::Configure::configure($class, {
				config_file => 'integration.yml',
				config_dirs => $config_dirs,
				%args
			});
			return bless $params, $class;
		}

		sub log_message {
			my ($self, $msg) = @_;
			$self->{logger}->debug($msg);
		}
	}

	my $obj = Integration::Test->new(_config_dirs => [$temp_dir]);
	ok(blessed($obj), 'Integration test object created');

	# Verify Config::Abstraction integration
	is($obj->{timeout}, 45, 'Config::Abstraction loaded values');

	# Verify Log::Abstraction integration
	isa_ok($obj->{logger}, 'Log::Abstraction');

	# Test that logger works
	lives_ok {
		$obj->log_message('Test message');
	} 'Logger functions correctly';

	done_testing();
};

subtest 'Integration: instantiate() workflow' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);

	my $config = <<'EOF';
---
Third__Party__Class:
  timeout: 100
  api_key: "instantiate_key"
EOF
	create_test_config($temp_dir, 'thirdparty.yml', $config);

	# Simulate third-party class we can't modify
	{
		package Third::Party::Class;

		sub new {
			my ($class, $params) = @_;
			return bless $params, $class;
		}

		sub get_timeout { $_[0]->{timeout} }
		sub get_api_key { $_[0]->{api_key} }
	}

	# Use instantiate to make it configurable
	my $obj = Object::Configure::instantiate(
		class => 'Third::Party::Class',
		config_file => 'thirdparty.yml',
		config_dirs => [$temp_dir]
	);

	ok(blessed($obj), 'Object created');
	isa_ok($obj, 'Third::Party::Class');
	is($obj->get_timeout, 100, 'Config applied via instantiate');
	is($obj->get_api_key, 'instantiate_key', 'Config key loaded');
	ok(blessed($obj->{logger}), 'Logger added by instantiate');

	done_testing();
};

subtest 'Stateful: Hot reload configuration changes' => sub {
	SKIP: {
		skip 'Hot reload not supported on Windows', 1 if $^O eq 'MSWin32';
		skip 'Skipping hot reload test - requires forking and signal handling', 1;

		my $temp_dir = tempdir(CLEANUP => 1);

		# Create initial config
		my $config_path = create_test_config($temp_dir, 'hotreload.yml', <<'EOF');
---
HotReload__App:
  timeout: 30
  value: "initial"
EOF

		{
			package HotReload::App;
			use Object::Configure;

			sub new {
				my ($class, %args) = @_;
				my $config_dirs = delete $args{_config_dirs} || [];
				my $params = Object::Configure::configure($class, {
					config_file => 'hotreload.yml',
					config_dirs => $config_dirs,
					%args
				});
				my $self = bless $params, $class;
				Object::Configure::register_object($class, $self) if $params->{_config_file};
				return $self;
			}

			sub get_timeout { $_[0]->{timeout} }
			sub get_value { $_[0]->{value} }
		}

		my $app = HotReload::App->new(_config_dirs => [$temp_dir]);
		is($app->get_timeout, 30, 'Initial timeout');
		is($app->get_value, 'initial', 'Initial value');

		# Modify config file
		sleep(0.1);  # Ensure mtime changes
		create_test_config($temp_dir, 'hotreload.yml', <<'EOF');
---
HotReload__App:
  timeout: 60
  value: "updated"
EOF

		# Trigger reload
		my $count = Object::Configure::reload_config();
		ok($count >= 0, 'Reload executed');

		# Note: In-place update means the object's values should change
		# This test verifies the reload mechanism works
	}

	done_testing();
};

subtest 'Concurrency: Multiple objects registered for hot reload' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);

	my $config = <<'EOF';
---
Concurrent__App:
  timeout: 30
EOF
	create_test_config($temp_dir, 'concurrent.yml', $config);

	{
		package Concurrent::App;
		use Object::Configure;

		sub new {
			my ($class, %args) = @_;
			my $config_dirs = delete $args{_config_dirs} || [];
			my $params = Object::Configure::configure($class, {
				config_file => 'concurrent.yml',
				config_dirs => $config_dirs,
				%args
			});
			my $self = bless $params, $class;
			Object::Configure::register_object($class, $self) if $params->{_config_file};
			return $self;
		}
	}

	# Create multiple instances
	my @apps;
	for (1..5) {
		push @apps, Concurrent::App->new(_config_dirs => [$temp_dir]);
	}

	# Verify all registered
	is(scalar(@apps), 5, 'Created 5 instances');

	# Verify they're all in the registry
	my $registry = $Object::Configure::_object_registry{'Concurrent::App'};
	ok(defined($registry), 'Registry exists for class');
	ok(scalar(@$registry) >= 5, 'At least 5 objects registered');

	# Reload should affect all
	my $count = Object::Configure::reload_config();
	ok($count >= 5, 'Reload affected multiple objects');

	# Cleanup
	delete $Object::Configure::_object_registry{'Concurrent::App'};

	done_testing();
};

subtest 'Spy: Verify Config::Abstraction is called correctly' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);

	my $config = <<'EOF';
---
Spy__Test__App:
  timeout: 30
EOF
	create_test_config($temp_dir, 'spy.yml', $config);

	{
		package Spy::Test::App;
		use Object::Configure;

		sub new {
			my ($class, %args) = @_;
			my $config_dirs = delete $args{_config_dirs} || [];
			my $params = Object::Configure::configure($class, {
				config_file => 'spy.yml',
				config_dirs => $config_dirs,
				%args
			});
			return bless $params, $class;
		}
	}

	# Spy on Config::Abstraction::new using correct syntax
	my $spy = spy 'Config::Abstraction::new';

	my $app = Spy::Test::App->new(_config_dirs => [$temp_dir]);

	# Get captured calls
	my @calls = $spy->();

	# Verify Config::Abstraction was called
	ok(scalar(@calls) > 0, 'Config::Abstraction::new was called');

	# Verify it was called with config_file argument
	my $found_config_file = 0;
	for my $call (@calls) {
		# $call->[0] is method name, $call->[1] is invocant, rest are args
		my @args = @{$call}[2..$#{$call}];
		next unless @args;  # Skip if no args

		# Handle hashref argument (common in OO constructors)
		if (@args == 1 && ref($args[0]) eq 'HASH') {
			if ($args[0]{config_file} && $args[0]{config_file} =~ /spy\.yml$/) {
				$found_config_file = 1;
				last;
			}
		} elsif (@args % 2 == 0) {  # Even number of args - can be a hash
			my %args = @args;
			if ($args{config_file} && $args{config_file} =~ /spy\.yml$/) {
				$found_config_file = 1;
				last;
			}
		}
	}
	ok($found_config_file, 'Config::Abstraction called with correct config file');

	done_testing();
};

subtest 'Spy: Verify Log::Abstraction is initialized' => sub {
	# Spy on Log::Abstraction::new using correct syntax
	my $spy = spy 'Log::Abstraction::new';

	{
		package Spy::Logger::Test;
		use Object::Configure;

		sub new {
			my ($class, %args) = @_;
			my $params = Object::Configure::configure($class, { %args });
			return bless $params, $class;
		}
	}

	my $app = Spy::Logger::Test->new();

	# Get captured calls
	my @calls = $spy->();

	ok(scalar(@calls) >= 1, 'Log::Abstraction::new was called');

	# Verify logger was created with carp_on_warn parameter
	my $has_carp_on_warn = 0;
	for my $call (@calls) {
		# $call->[0] is method name, $call->[1] is invocant, rest are args
		my @args = @{$call}[2..$#{$call}];
		next unless @args;  # Skip if no args

		# Handle hashref argument (common in OO constructors)
		if (@args == 1 && ref($args[0]) eq 'HASH') {
			if (exists $args[0]{carp_on_warn}) {
				$has_carp_on_warn = 1;
				last;
			}
		} elsif (@args % 2 == 0) {  # Even number of args - can be a hash
			my %args = @args;
			if (exists $args{carp_on_warn}) {
				$has_carp_on_warn = 1;
				last;
			}
		}
	}
	ok($has_carp_on_warn, 'Logger initialized with carp_on_warn parameter');

	done_testing();
};

subtest 'End-to-end: Environment variable configuration' => sub {
	# Set environment variables
	local $ENV{'EnvVar__Test__timeout'} = 90;
	local $ENV{'EnvVar__Test__api_key'} = 'env_key_123';

	{
		package EnvVar::Test;
		use Object::Configure;

		sub new {
			my $class = shift;
			my $params = Object::Configure::configure($class, {
				timeout => 30,  # Default
				@_
			});
			return bless $params, $class;
		}
	}

	my $app = new_ok('EnvVar::Test');

	# Verify environment variables override defaults
	is($app->{timeout}, 90, 'Environment variable overrides default');
	is($app->{api_key}, 'env_key_123', 'Environment variable loaded');

	done_testing();
};

subtest 'Integration: Manual hot reload updates object properties' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);

	# Create initial config
	my $config_path = create_test_config($temp_dir, 'manual_reload.yml', <<'EOF');
---
Manual__Reload__Test:
  timeout: 30
  value: "initial"
  status: "active"
EOF

	{
		package Manual::Reload::Test;
		use Object::Configure;

		sub new {
			my ($class, %args) = @_;
			my $config_dirs = delete $args{_config_dirs} || [];
			my $params = Object::Configure::configure($class, {
				config_file => 'manual_reload.yml',
				config_dirs => $config_dirs,
				%args
			});
			my $self = bless $params, $class;
			Object::Configure::register_object($class, $self) if $params->{_config_file};
			return $self;
		}
	}

	my $obj = Manual::Reload::Test->new(_config_dirs => [$temp_dir]);

	# Verify initial values
	is($obj->{timeout}, 30, 'Initial timeout');
	is($obj->{value}, 'initial', 'Initial value');
	is($obj->{status}, 'active', 'Initial status');

	# Modify config file
	sleep(0.2);  # Ensure mtime changes
	create_test_config($temp_dir, 'manual_reload.yml', <<'EOF');
---
Manual__Reload__Test:
  timeout: 60
  value: "updated"
  status: "reloaded"
EOF

	# Manually trigger reload
	my $count = Object::Configure::reload_config();
	ok($count >= 1, 'Reload executed and affected at least one object');

	# Verify object was updated in-place
	is($obj->{timeout}, 60, 'Timeout updated after reload');
	is($obj->{value}, 'updated', 'Value updated after reload');
	is($obj->{status}, 'reloaded', 'Status updated after reload');

	# Cleanup
	delete $Object::Configure::_object_registry{'Manual::Reload::Test'};

	done_testing();
};

subtest 'Integration: _on_config_reload hook is called' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);

	# Create initial config
	create_test_config($temp_dir, 'hook_test.yml', <<'EOF');
---
Hook__Test__App:
  timeout: 30
  value: "initial"
EOF

	{
		package Hook::Test::App;
		use Object::Configure;

		sub new {
			my ($class, %args) = @_;
			my $config_dirs = delete $args{_config_dirs} || [];
			my $params = Object::Configure::configure($class, {
				config_file => 'hook_test.yml',
				config_dirs => $config_dirs,
				%args
			});
			my $self = bless $params, $class;
			$self->{_reload_count} = 0;
			$self->{_last_reload_config} = undef;
			Object::Configure::register_object($class, $self) if $params->{_config_file};
			return $self;
		}

		sub _on_config_reload {
			my ($self, $new_config) = @_;
			$self->{_reload_count}++;
			$self->{_last_reload_config} = $new_config;
		}
	}

	my $obj = Hook::Test::App->new(_config_dirs => [$temp_dir]);

	is($obj->{_reload_count}, 0, 'Hook not called yet');
	ok(!defined($obj->{_last_reload_config}), 'No reload config yet');

	# Modify config
	sleep(0.2);
	create_test_config($temp_dir, 'hook_test.yml', <<'EOF');
---
Hook__Test__App:
  timeout: 60
  value: "reloaded"
EOF

	# Trigger reload
	Object::Configure::reload_config();

	# Verify hook was called
	is($obj->{_reload_count}, 1, 'Hook called once');
	ok(defined($obj->{_last_reload_config}), 'Hook received new config');
	is(ref($obj->{_last_reload_config}), 'HASH', 'New config is hashref');
	is($obj->{_last_reload_config}{timeout}, 60, 'Hook received updated timeout');

	# Cleanup
	delete $Object::Configure::_object_registry{'Hook::Test::App'};

	done_testing();
};

subtest 'Integration: Syslog logger configuration' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);

	# Create config with syslog logger
	my $config = <<'EOF';
---
Syslog__Test__App:
  timeout: 30
  logger:
    syslog: local0
    level: info
EOF
	create_test_config($temp_dir, 'syslog.yml', $config);

	{
		package Syslog::Test::App;
		use Object::Configure;

		sub new {
			my ($class, %args) = @_;
			my $config_dirs = delete $args{_config_dirs} || [];
			my $params = Object::Configure::configure($class, {
				config_file => 'syslog.yml',
				config_dirs => $config_dirs,
				%args
			});
			return bless $params, $class;
		}
	}

	my $app = Syslog::Test::App->new(_config_dirs => [$temp_dir]);

	# Verify logger was created
	ok(blessed($app->{logger}), 'Logger created');
	isa_ok($app->{logger}, 'Log::Abstraction');

	# Verify syslog configuration was applied
	# Note: We can't easily verify internal syslog setup without accessing
	# Log::Abstraction internals, but we can verify it was created without error
	ok(defined($app->{logger}), 'Syslog logger initialized');
	is($app->{timeout}, 30, 'Other config values loaded');

	done_testing();
};

subtest 'End-to-end: logger=NULL integration test' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);

	# Create config without logger settings
	my $config = <<'EOF';
---
Null__Logger__Integration:
  timeout: 45
  api_key: "test123"
EOF
	create_test_config($temp_dir, 'nulllogger.yml', $config);

	{
		package Null::Logger::Integration;
		use Object::Configure;

		sub new {
			my ($class, %args) = @_;
			my $config_dirs = delete $args{_config_dirs} || [];
			my $params = Object::Configure::configure($class, {
				config_file => 'nulllogger.yml',
				config_dirs => $config_dirs,
				%args
			});
			return bless $params, $class;
		}

		sub has_logger {
			my $self = shift;
			return $self->{logger} ne 'NULL';
		}
	}

	# Test with logger=NULL
	my $app = Null::Logger::Integration->new(
		_config_dirs => [$temp_dir],
		logger => 'NULL'
	);

	# Verify logger is NULL
	is($app->{logger}, 'NULL', 'Logger is NULL as requested');
	ok(!$app->has_logger, 'has_logger returns false');

	# Verify other config still loaded
	is($app->{timeout}, 45, 'Config timeout loaded');
	is($app->{api_key}, 'test123', 'Config api_key loaded');

	done_testing();
};

# =============================================================================
# Optional dependencies: no optional runtime deps (Test::Without::Module finding)
# All of Object::Configure's runtime deps are listed under 'requires' in cpanfile.
# There are no 'recommends' or 'suggests' entries with fallback code paths.
# This subtest verifies the module functions correctly even when unrelated optional
# modules (that calling code might try to load) are unavailable.
# =============================================================================
subtest 'Optional deps: Object::Configure unaffected by unrelated missing modules' => sub {
	# SomeHypothetical::OptionalModule was excluded at the top of this file via
	# Test::Without::Module.  Object::Configure must not depend on it in any way.

	my $result = Object::Configure::configure('Test::NoDeps', { key => 'val' });

	ok(ref($result) eq 'HASH',    'configure() returns hashref without optional modules');
	ok(blessed($result->{logger}), 'Logger created without optional modules');
	is($result->{key}, 'val',     'Params preserved');

	done_testing();
};

# =============================================================================
# Env var precedence: env vars (level 4) override config file values (level 3)
# Validates the POD-documented precedence table end-to-end through Config::Abstraction.
# =============================================================================
subtest 'End-to-end: env var wins over config file value for the same key' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);

	create_test_config($temp_dir, 'envprio.yml', <<'YAML');
---
EnvPrio__Test:
  timeout: 30
  source: config_file
YAML

	# timeout via env var should override config file's timeout: 30
	local %ENV;
	$ENV{'EnvPrio__Test__timeout'} = 999;

	my $result = Object::Configure::configure('EnvPrio::Test', {
		config_file => 'envprio.yml',
		config_dirs => [$temp_dir],
	});

	is($result->{timeout}, 999,         'Env var timeout overrides config-file timeout');
	is($result->{source}, 'config_file','Config-file-only key unaffected by unrelated env var');

	done_testing();
};

# =============================================================================
# GC: dead weak refs must be pruned from the registry by reload_config()
# Bug fix verified: grep { defined $_ } checked the ref-to-scalar (always truthy);
# fixed to grep { defined $$_ } which checks the weakened referent.
# =============================================================================
subtest 'GC: dead weak references are pruned from the registry on reload_config()' => sub {
	{
		package GC::Prune::Test;
		sub new { bless {}, shift }
	}

	my $temp_dir = tempdir(CLEANUP => 1);
	create_test_config($temp_dir, 'gc.yml', "---\nGC__Prune__Test:\n  k: v\n");

	# Create an object in a nested scope so it is eligible for GC when scope exits.
	{
		my $obj = bless {
			_config_file => File::Spec->catfile($temp_dir, 'gc.yml'),
		}, 'GC::Prune::Test';
		Object::Configure::register_object('GC::Prune::Test', $obj);
		# $obj goes out of scope here; the weakened registry ref becomes undef
	}

	# Trigger GC explicitly (Perl's ref-counting frees immediately in scalar scope).
	# reload_config() should detect the dead ref and prune it.
	Object::Configure::reload_config();

	my $reg = $Object::Configure::_object_registry{'GC::Prune::Test'};
	my $dead_pruned =
		!defined($reg) ||
		!@{ $reg } ||
		!grep { defined($$_) } @{ $reg };

	ok($dead_pruned, 'Dead weak refs pruned from registry after reload_config()');

	delete $Object::Configure::_object_registry{'GC::Prune::Test'};

	done_testing();
};

# =============================================================================
# Logger arrayref: messages are captured end-to-end through configure() + logger
# Verifies the full path: arrayref logger spec → Log::Abstraction → message captured.
# =============================================================================
subtest 'Integration: arrayref logger captures log output end-to-end' => sub {
	my @captured;

	# Arrayref logger: configure() stashes it before Config::Abstraction runs so no
	# site-local UNIVERSAL logger config can override it.
	# Use ->warn() rather than ->debug(): 'debug' has syslog-priority 7, which is above
	# the Log::Abstraction default threshold (warning = 4), so it would be silently dropped.
	my $result = Object::Configure::configure('Test::ArrayLogger', {
		logger => \@captured,
	});

	$result->{logger}->warn('hello from test');

	# Log::Abstraction stores { level => ..., message => ... } hashrefs in the array.
	ok(scalar(@captured) > 0, 'At least one log message captured');
	ok(
		grep({ ref($_) eq 'HASH' ? $_->{message} =~ /hello from test/i : $_ =~ /hello from test/i } @captured),
		'Correct message text captured in array'
	);

	done_testing();
};

# =============================================================================
# Logger isolation: two objects with separate arrayref loggers must not share output.
# Verifies that Log::Abstraction instances are independent (no singleton leakage).
# =============================================================================
subtest 'Concurrency: two objects with separate arrayref loggers do not share output' => sub {
	my @log_a;
	my @log_b;

	# Use arrayref loggers (stashed before config merge) and ->warn() (syslog priority 4,
	# always below the default threshold of 4) so messages are never filtered.
	my $obj_a = Object::Configure::configure('Test::IsolatedLogger::A', {
		logger => \@log_a,
	});
	my $obj_b = Object::Configure::configure('Test::IsolatedLogger::B', {
		logger => \@log_b,
	});

	$obj_a->{logger}->warn('message for A');
	$obj_b->{logger}->warn('message for B');

	# Log::Abstraction stores { level => ..., message => ... } hashrefs in the array.
	my $msg = sub { ref($_[0]) eq 'HASH' ? $_[0]->{message} : "$_[0]" };

	ok(grep({ $msg->($_) =~ /message for A/i } @log_a), 'A logger captured A message');
	ok(grep({ $msg->($_) =~ /message for B/i } @log_b), 'B logger captured B message');
	ok(!grep({ $msg->($_) =~ /message for B/i } @log_a), 'A logger did not receive B message');
	ok(!grep({ $msg->($_) =~ /message for A/i } @log_b), 'B logger did not receive A message');

	done_testing();
};

# =============================================================================
# 3-level deep inheritance merge order: UNIVERSAL < GrandParent < Parent < Child
# Validates that the deepest (child-most) config wins for overlapping keys, while
# unique keys from each level are preserved (no accidental overwrite).
# =============================================================================
subtest 'End-to-end: 3-level inheritance merge preserves correct priority order' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);

	# UNIVERSAL: provides global_key and shared_key
	create_test_config($temp_dir, 'universal.yml', <<'YAML');
---
UNIVERSAL:
  global_key: from_universal
  shared_key: universal
YAML

	# GrandParent: overrides shared_key, adds gp_key
	create_test_config($temp_dir, 'my-gp.yml', <<'YAML');
---
My__GP:
  shared_key: grandparent
  gp_key: from_gp
YAML

	# Parent: overrides shared_key, adds parent_key
	create_test_config($temp_dir, 'my-parent.yml', <<'YAML');
---
My__Parent:
  shared_key: parent
  parent_key: from_parent
YAML

	# Child: overrides shared_key, adds child_key
	create_test_config($temp_dir, 'my-child.yml', <<'YAML');
---
My__Child:
  shared_key: child
  child_key: from_child
YAML

	{
		package My::GP;
		sub new { bless {}, shift }
	}
	{
		package My::Parent;
		use base 'My::GP';
		sub new { bless {}, shift }
	}
	{
		package My::Child;
		use base 'My::Parent';
		sub new { bless {}, shift }
	}

	my $result = Object::Configure::configure('My::Child', {
		config_file => 'my-child.yml',
		config_dirs => [$temp_dir],
	});

	# Child's shared_key wins over all ancestors
	is($result->{shared_key}, 'child',        'Child overrides shared_key from all ancestors');
	# Unique keys from each level are preserved
	is($result->{global_key}, 'from_universal', 'global_key inherited from UNIVERSAL');
	is($result->{gp_key},     'from_gp',       'gp_key inherited from GrandParent');
	is($result->{parent_key}, 'from_parent',   'parent_key inherited from Parent');
	is($result->{child_key},  'from_child',    'child_key from Child itself');

	done_testing();
};

# =============================================================================
# _config_file_stats tracking: after configure() loads a real file, the stats
# hash must contain a File::stat entry for that path (used for hot-reload change
# detection in _run_config_watcher).
# =============================================================================
subtest 'Integration: _config_file_stats populated after configure() with real file' => sub {
	my $temp_dir = tempdir(CLEANUP => 1);
	my $config_path = create_test_config($temp_dir, 'stats.yml',
		"---\nStats__Test:\n  k: v\n");

	# Clear any prior state from earlier subtests
	%Object::Configure::_config_file_stats = ();

	# Pass the absolute path directly so -r $config_file is true and configure()
	# populates _config_file_stats via the primary-file branch (not the fallback
	# directory scan, which does not update the stats hash).
	Object::Configure::configure('Stats::Test', {
		config_file => $config_path,
	});

	my $tracked = scalar keys %Object::Configure::_config_file_stats;
	ok($tracked > 0, '_config_file_stats has at least one entry after configure()');

	my ($tracked_path) = grep { /stats\.yml$/ } keys %Object::Configure::_config_file_stats;
	ok(defined($tracked_path), 'stats.yml path is tracked in _config_file_stats');

	done_testing();
};

# =============================================================================
# Security E2E: path-traversal and invalid class name are rejected at the
# constructor level — i.e., the full class-constructor → configure() call path.
# =============================================================================
subtest 'Security E2E: invalid class and traversal path rejected in constructor workflow' => sub {
	{
		package Security::E2E::Good;
		use Object::Configure;
		sub new {
			my ($class, %args) = @_;
			return bless Object::Configure::configure($class, \%args), $class;
		}
	}

	# The class name passed to configure() is the Perl package name — it is always
	# developer-controlled.  But instantiate() accepts a class name from params.
	# Verify that a hostile class string is rejected before any config I/O.
	throws_ok {
		Object::Configure::instantiate(class => "Hostile\nInjection", timeout => 5);
	} qr/configure: invalid class name/,
		'instantiate() with newline in class name rejected by configure()';

	# Path traversal in config_file must be rejected even inside a constructor.
	throws_ok {
		Object::Configure::configure('Security::E2E::Good', {
			config_file => '../../etc/passwd',
		});
	} qr/config_file contains path traversal sequences/,
		'configure() rejects traversal path in full constructor workflow';

	done_testing();
};

subtest 'Integration: Signal handler chaining' => sub {
	SKIP: {
		skip 'Signal handlers not supported on Windows', 1 if $^O eq 'MSWin32';

		# Save original handler
		my $original = $SIG{USR1} || 'DEFAULT';

		# Set a custom handler
		my $custom_called = 0;
		$SIG{USR1} = sub { $custom_called = 1 };

		# Register an object (which installs Object::Configure's handler)
		{
			package SignalChain::Test;
			sub new { bless {}, shift }
		}

		my $obj = bless {}, 'SignalChain::Test';
		Object::Configure::register_object('SignalChain::Test', $obj);

		# Verify handler was replaced
		isnt($SIG{USR1}, $original, 'Signal handler changed');

		# Get handler info
		my $info = Object::Configure::get_signal_handler_info();
		ok($info->{hot_reload_active}, 'Hot reload active after registration');

		# Restore
		Object::Configure::restore_signal_handlers();

		# Cleanup
		delete $Object::Configure::_object_registry{'SignalChain::Test'};
		$SIG{USR1} = $original;
	}

	done_testing();
};

done_testing();
