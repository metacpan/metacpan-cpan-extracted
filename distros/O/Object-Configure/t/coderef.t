#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 23;
use File::Temp qw(tempdir);
use File::Spec;
use Scalar::Util qw(blessed reftype);

# Create a temporary directory for config files
my $temp_dir = tempdir(CLEANUP => 1);

# Write a simple config file
my $config_file = File::Spec->catfile($temp_dir, 'test.yml');
open my $fh, '>', $config_file or die "Cannot write $config_file: $!";
print $fh <<'EOF';
---
Test__Class__WithCoderef:
  config_value: "from_config"
  timeout: 30
EOF
close $fh;

# Test class that relies on Object::Configure's automatic handling
# (NO manual stash-delete-restore pattern needed)
{
	package Test::Class::WithCoderef;
	use Object::Configure;
	use Carp;

	sub new {
		my $class = shift;
		my %params = @_;

		# Simply pass everything to configure - it handles coderefs/objects automatically
		my $self = Object::Configure::configure($class, {
			config_file => 'test.yml',
			config_dirs => [$temp_dir],
			%params
		});

		return bless $self, $class;
	}
}

# Test class using old manual pattern (for backward compatibility test)
{
	package Test::Class::ManualPattern;
	use Object::Configure;
	use Scalar::Util qw(blessed);
	use Carp;

	sub new {
		my $class = shift;
		my %params = @_;

		# Manual stash-delete-configure-restore pattern
		my %stashed;
		foreach my $key (qw(on_error on_success ctx logger_obj)) {
			if(exists($params{$key})) {
				my $ref = ref($params{$key});
				if($ref eq 'CODE' || blessed($params{$key})) {
					$stashed{$key} = delete $params{$key};
				}
			}
		}

		my $self = Object::Configure::configure($class, {
			config_file => 'test.yml',
			config_dirs => [$temp_dir],
			%params
		});

		# Restore stashed values via hash slice
		@{$self}{keys %stashed} = values %stashed if %stashed;

		return bless $self, $class;
	}
}

# Mock logger object for testing
{
	package Mock::Logger;

	sub new {
		my $class = shift;
		return bless { messages => [] }, $class;
	}

	sub log {
		my ($self, $msg) = @_;
		push @{$self->{messages}}, $msg;
	}
}

# Test 1: Verify coderef is preserved with automatic handling
{
	my $callback_called = 0;
	my $on_error = sub {
		$callback_called++;
		return "error handled";
	};

	my $obj = Test::Class::WithCoderef->new(
		on_error => $on_error,
		custom_param => 'test_value'
	);

	ok(defined $obj, 'Object created with coderef');
	ok(exists($obj->{on_error}), 'on_error key exists');
	is(ref($obj->{on_error}), 'CODE', 'on_error is still a coderef');
	is($obj->{on_error}, $on_error, 'on_error is the same coderef');

	# Test that the coderef still works
	my $result = $obj->{on_error}->();
	is($callback_called, 1, 'Coderef was executed');
	is($result, 'error handled', 'Coderef returned correct value');

	# Verify config values were still loaded
	is($obj->{config_value}, 'from_config', 'Config value loaded correctly');
	is($obj->{timeout}, 30, 'Config timeout loaded correctly');
}

# Test 2: Verify multiple coderefs are preserved
{
	my $error_count = 0;
	my $success_count = 0;

	my $obj = Test::Class::WithCoderef->new(
		on_error => sub { $error_count++ },
		on_success => sub { $success_count++ }
	);

	ok(defined $obj, 'Object created with multiple coderefs');
	is(ref($obj->{on_error}), 'CODE', 'on_error is a coderef');
	is(ref($obj->{on_success}), 'CODE', 'on_success is a coderef');

	$obj->{on_error}->();
	$obj->{on_success}->();

	is($error_count, 1, 'on_error coderef executed');
	is($success_count, 1, 'on_success coderef executed');
}

# Test 3: Verify blessed objects are preserved
{
	my $logger = Mock::Logger->new();

	my $obj = Test::Class::WithCoderef->new(
		logger_obj => $logger
	);

	ok(defined $obj, 'Object created with blessed object');
	ok(exists($obj->{logger_obj}), 'logger_obj key exists');
	ok(blessed($obj->{logger_obj}), 'logger_obj is still blessed');
	isa_ok($obj->{logger_obj}, 'Mock::Logger', 'logger_obj');
	is($obj->{logger_obj}, $logger, 'logger_obj is the same object');

	# Test that the object still works
	$obj->{logger_obj}->log('test message');
	is(scalar(@{$obj->{logger_obj}{messages}}), 1, 'Logger object still functional');
	is($obj->{logger_obj}{messages}[0], 'test message', 'Logger recorded message');
}

# Test 4: Verify manual pattern still works (backward compatibility)
{
	my $callback_called = 0;
	my $on_error = sub { $callback_called++ };

	my $obj = Test::Class::ManualPattern->new(
		on_error => $on_error
	);

	ok(defined $obj, 'Manual pattern object created');
	ok(exists($obj->{on_error}), 'on_error key exists with manual pattern');
	is(ref($obj->{on_error}), 'CODE', 'Manual stash-delete-restore pattern still works');
}
