#!/usr/bin/env perl

# Test the hot reload funcionality

use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempfile tempdir);
use File::Spec;
use Time::HiRes qw(sleep);
use IO::Handle;

BEGIN { use_ok('Object::Configure'); }

diag('This test has sleeps so it may take a few seconds');

# Create a test class that uses Object::Configure
{
	package TestClass;
	use Object::Configure;
	use Params::Get;

	sub new {
		my $class = shift;
		my $params = Object::Configure::configure($class, { @_ });
		my $self = bless $params, $class;

		# Register for hot reload if config file is provided
		Object::Configure::register_object($class, $self) if $params->{_config_file};

		return $self;
	}

	sub get_value {
		my $self = shift;
		return $self->{test_value} || 'default';
	}

	sub get_logger_file {
		my $self = shift;
		return $self->{'logger.file'};
		# return $self->{logger} && $self->{logger}->{file} ? $self->{logger}->{file} : undef;
	}

	# Reload hook for testing
	sub _on_config_reload {
		my ($self, $new_config) = @_;
		$self->{_reload_called} = 1;
		$self->{_reload_count} = ($self->{_reload_count} || 0) + 1;
	}

	sub was_reloaded {
		my $self = shift;
		return $self->{_reload_called} || 0;
	}

	sub reload_count {
		my $self = shift;
		return $self->{_reload_count} || 0;
	}
}

# Global test variables
my $temp_dir = tempdir(CLEANUP => 1);
my $config_file = File::Spec->catfile($temp_dir, 'test.conf');
my $log_file = File::Spec->catfile($temp_dir, 'test.log');

# Test basic configuration loading
subtest 'Basic configuration loading' => sub {
	plan tests => 4;

	# Create initial config file
	write_config_file($config_file, {
		test_value => 'initial_value',
		'logger.file' => $log_file
	});

	ok(-f $config_file, 'Config file was created');

	my $obj = TestClass->new(config_file => $config_file);

	ok($obj, 'Object created successfully');
	is($obj->get_value(), 'initial_value', 'Initial config value loaded');
	ok(!$obj->was_reloaded(), 'Object not marked as reloaded initially');
};

# Test manual configuration reload
subtest 'Manual configuration reload' => sub {
	plan tests => 5;

	# Create object with initial config
	write_config_file($config_file, {
		test_value => 'before_reload'
	});

	my $obj = TestClass->new(config_file => $config_file);
	is($obj->get_value(), 'before_reload', 'Initial value correct');

	# Update config file
	write_config_file($config_file, {
		test_value => 'after_reload'
	});

	# Manually trigger reload
	my $reload_count = Object::Configure::reload_config();

	ok($reload_count > 0, 'Config reload returned positive count');
	is($obj->get_value(), 'after_reload', 'Value updated after manual reload');
	ok($obj->was_reloaded(), 'Reload hook was called');
	is($obj->reload_count(), 1, 'Reload count is correct');
};

# Test object registration
subtest 'Object registration' => sub {
	my $obj1 = TestClass->new();  # No config file - should not be registered
	my $obj2 = TestClass->new(config_file => $config_file);  # Should be registered

	# Update config
	write_config_file($config_file, {
		test_value => 'registration_test'
	});

	my $reload_count = Object::Configure::reload_config();

	ok(!$obj1->was_reloaded(), 'Object without config file was not reloaded');
	ok($obj2->was_reloaded(), 'Object with config file was reloaded');
};

# Test signal handler chaining
subtest 'Signal handler chaining' => sub {
	Object::Configure::restore_signal_handlers();

	plan(skip_all => 'Windows does not support SIGUSR1') if($^O eq 'MSWin32');

	my $original_called = 0;
	my $original_handler = sub { $original_called++ };

	# Set up original handler
	$SIG{USR1} = $original_handler;

	# Create object (this should install our handler)
	my $obj = TestClass->new(config_file => $config_file);

	# Check that our handler is installed but original is preserved
	my $handler_info = Object::Configure::get_signal_handler_info();
	ok($handler_info->{hot_reload_active}, 'Hot reload signal handler is active');
	is(ref($handler_info->{original_usr1}), 'CODE', 'Original handler preserved as code ref');

	# Update config file
	write_config_file($config_file, {
		test_value => 'signal_test'
	});

	# Send USR1 signal to ourselves
	kill 'USR1', $$;

	# Give it a moment to process
	sleep(0.1);

	ok($obj->was_reloaded(), 'Object was reloaded via signal');
	is($original_called, 1, 'Original signal handler was called');

	# Restore handlers
	Object::Configure::restore_signal_handlers();
	is($SIG{USR1}, $original_handler, 'Original handler restored');
};

# Test hot reload enable/disable
subtest 'Hot reload enable/disable' => sub {
	plan(skip_all => 'Windows does not support SIGUSR1') if($^O eq 'MSWin32');
	my $callback_called = 0;
	my $callback = sub { $callback_called++ };

	# Enable hot reload
	my $watcher_pid = Object::Configure::enable_hot_reload(
		interval => 1,  # Check every 1 second for faster testing
		callback => $callback
	);

	ok($watcher_pid, 'Hot reload enabled and returned PID');
	ok($watcher_pid > 0, 'Watcher PID is positive');

	# Verify watcher process exists
	my $process_exists = kill(0, $watcher_pid);
	ok($process_exists, 'Watcher process is running');

	sleep(1);	# Allow the subsystem to get started

	# Create object and update config
	my $obj = TestClass->new(config_file => $config_file);
	write_config_file($config_file, {
		test_value => 'hot_reload_test'
	});

	# Wait for the watcher to detect the change
	sleep(2);

	# Check if reload happened
	ok($obj->was_reloaded(), 'Object was hot reloaded');

	cmp_ok($callback_called, '>', 0, 'Callback was called');

	# Disable hot reload
	Object::Configure::disable_hot_reload();

	# Verify watcher process is gone
	sleep(0.5);  # Give it time to shut down
	my $process_gone = !kill(0, $watcher_pid);
	ok($process_gone, 'Watcher process was terminated');
};

# Test multiple objects
subtest 'Multiple object reload' => sub {
	write_config_file($config_file, {
		test_value => 'multi_initial'
	});

	my @objects = map { TestClass->new(config_file => $config_file) } 1..3;

	# Update config
	write_config_file($config_file, {
		test_value => 'multi_updated'
	});

	my $reload_count = Object::Configure::reload_config();

	is($reload_count, 3, 'All three objects were reloaded');

	foreach my $i (0..2) {
		is($objects[$i]->get_value(), 'multi_updated', "Object $i has updated value");
		ok($objects[$i]->was_reloaded(), "Object $i was marked as reloaded");
	}
};

# Test weak reference cleanup
subtest 'Weak reference cleanup' => sub {
	write_config_file($config_file, {
		test_value => 'weak_ref_test'
	});

	# Create object in limited scope
	my $reload_count_before;
	{
		my $obj = TestClass->new(config_file => $config_file);
		$reload_count_before = Object::Configure::reload_config();
	}  # Object goes out of scope here

	# Force garbage collection
	undef;  # Give GC a hint

	# Update config and reload again
	write_config_file($config_file, {
		test_value => 'after_cleanup'
	});

	my $reload_count_after = Object::Configure::reload_config();

	# The count should be lower since the object was garbage collected
	ok($reload_count_after < $reload_count_before || $reload_count_after == 0,
	   'Weak references allow garbage collection');
};

# Test logger reconfiguration
subtest 'Logger reconfiguration' => sub {

	my $log_file1 = File::Spec->catfile($temp_dir, 'test1.log');
	my $log_file2 = File::Spec->catfile($temp_dir, 'test2.log');

	# Initial config with first log file
	write_config_file($config_file, {
		test_value => 'logger_test',
		'logger.file' => $log_file1
	});

	my $obj = TestClass->new(config_file => $config_file);
	is($obj->get_logger_file(), $log_file1, 'Initial logger file set');

	# Update config with second log file
	write_config_file($config_file, {
		test_value => 'logger_test',
		'logger.file' => $log_file2
	});

	my $reload_count = Object::Configure::reload_config();

	cmp_ok($reload_count, '>', 0, 'Config reload returned positive count');

	is($obj->get_logger_file(), $log_file2, 'Logger file updated after reload');
};

# Test error handling
subtest 'Error handling' => sub {
	# Test with non-existent config file
	my $bad_config = File::Spec->catfile($temp_dir, 'nonexistent.conf');

	throws_ok {
		TestClass->new(config_file => $bad_config);
	} qr/No such file or directory/, 'Dies with non-existent config file';

	# Test reload with deleted config file
	my $obj = TestClass->new(config_file => $config_file);
	unlink($config_file);

	lives_ok {
		Object::Configure::reload_config();
	} 'Survives reload when config file is deleted';
};

# Helper function to write config file
sub write_config_file {
	my ($filename, $config) = @_;

	open my $fh, '>', $filename or die "Cannot write $filename: $!";

	# Object::Configure converts :: to __ for section names
	print $fh "[TestClass]\n";
	foreach my $key (sort keys %$config) {
		print $fh "$key = $config->{$key}\n";
	}

	# Ensure file is flushed to disk
	if (defined fileno($fh)) {
		$fh->flush();
	}

	close $fh;

	# Small delay to ensure filesystem has the update
	select(undef, undef, undef, 0.01);
}

# Cleanup
END {
	eval { Object::Configure::disable_hot_reload(); };
	eval { Object::Configure::restore_signal_handlers(); };
}

done_testing();
