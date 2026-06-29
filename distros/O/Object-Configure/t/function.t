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
	throws_ok {
		Object::Configure::configure(undef, {});
	} qr/configure: what class do you want to configure/, 'Croaks on undef class';

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

subtest '_get_inheritance_chain() - processes class hierarchy' => sub {
	{
		package Test::Base;
		sub new { bless {}, shift }
	}
	{
		package Test::Derived;
		use base 'Test::Base';
		sub new { bless {}, shift }
	}

	my @chain = Object::Configure::_get_inheritance_chain('Test::Derived');

	ok(scalar(@chain) > 0, 'Chain populated');
	ok((grep { $_ eq 'Test::Derived' } @chain), 'Derived class in chain');
	ok((grep { $_ eq 'Test::Base'    } @chain), 'Base class in chain');
	ok((grep { $_ eq 'UNIVERSAL'     } @chain), 'UNIVERSAL in chain');

	done_testing();
};

subtest '_get_inheritance_chain() - adds UNIVERSAL for classes with no parents' => sub {
	my @chain = Object::Configure::_get_inheritance_chain('Test::Orphan');

	ok((grep { $_ eq 'UNIVERSAL'    } @chain), 'UNIVERSAL added for orphan class');
	ok((grep { $_ eq 'Test::Orphan' } @chain), 'Class itself in chain');

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

subtest 'configure() - handles carp_on_warn parameter' => sub {
	my $class = 'Test::Class::CarpOnWarn';
	my $params = {
		carp_on_warn => 1,
		timeout => 30
	};

	my $result = Object::Configure::configure($class, $params);

	ok(blessed($result->{logger}), 'Logger created');
	# Note: can't easily test if logger uses carp without triggering warnings

	done_testing();
};

subtest 'configure() - handles croak_on_error parameter' => sub {
	my $class = 'Test::Class::CroakOnError';
	my $params = {
		croak_on_error => 0,
		timeout => 30
	};

	my $result = Object::Configure::configure($class, $params);

	ok(defined($result), 'Configuration completed');
	# Note: can't easily test croak_on_error without triggering errors

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

done_testing();
