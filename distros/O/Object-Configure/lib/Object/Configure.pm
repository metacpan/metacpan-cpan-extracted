package Object::Configure;

# TODO: configuration inheritance from parents

use strict;
use warnings;

use Carp;
use Config::Abstraction 0.36;
use Log::Abstraction 0.26;
use Params::Get 0.13;
use Return::Set;
use Scalar::Util qw(blessed weaken);
use Time::HiRes qw(time);
use File::stat;

# Global registry to track configured objects for hot reload
our %_object_registry = ();
our %_config_watchers = ();
our %_config_file_stats = ();

# Keep track of the original USR1 handler for chaining
our $_original_usr1_handler;

=head1 NAME

Object::Configure - Runtime Configuration for an Object

=head1 VERSION

0.17

=cut

our $VERSION = 0.17;

=head1 SYNOPSIS

The C<Object::Configure> module is a lightweight utility designed to inject runtime parameters into other classes,
primarily by layering configuration and logging support,
when instatiating objects.

L<Log::Abstraction> and L<Config::Abstraction> are modules developed to solve a specific need,
runtime configurability without needing to rewrite or hardcode behaviours.
The goal is to allow individual modules to enable or disable features on the fly,
and to do it using whatever configuration system the user prefers.

Although the initial aim was general configurability,
the primary use case that's emerged has been fine-grained logging control,
more flexible and easier to manage than what you'd typically do with L<Log::Log4perl>.
For example,
you might want one module to log verbosely while another stays quiet,
and be able to toggle that dynamically - without making invasive changes to each module.

To tie it all together,
there is C<Object::Configure>.
It sits on L<Log::Abstraction> and L<Config::Abstraction>,
and with just a couple of extra lines in a class constructor,
you can hook in this behaviour seamlessly.
The intent is to keep things modular and reusable,
especially across larger systems or in situations where you want user-selectable behaviour.

Add this to your constructor:

   package My::Module;

   use Object::Configure;
   use Params::Get;

   sub new {
        my $class = shift;
        my $params = Object::Configure::configure($class, @_ ? \@_ : undef);	# Reads in the runtime configuration settings
        # or my $params = Object::Configure::configure($class, { @_ });

        return bless $params, $class;
    }

Throughout your class, add code such as:

    sub method
    {
        my $self = shift;

        $self->{'logger'}->trace(ref($self), ': ', __LINE__, ' entering method');
    }

=head3 CONFIGURATION INHERITANCE

C<Object::Configure> supports configuration inheritance, allowing child classes to inherit and override configuration settings from their parent classes. When a class is configured, the module automatically traverses the inheritance hierarchy (using C<@ISA>) and loads configuration files for each ancestor class in the chain.

Configuration files are loaded in order from the most general (base class) to the most specific (child class), with later files overriding earlier ones. For example, if C<My::Child::Class> inherits from C<My::Parent::Class>, which inherits from C<My::Base::Class>, the module will:

=over 4

=item 1. Load C<my-base-class.yml> (or .conf, .json, etc.) if it exists

=item 2. Load C<my-parent-class.yml> if it exists, overriding base settings

=item 3. Load C<my-child-class.yml>, overriding both parent and base settings

=back

The configuration files should be named using lowercase versions of the class name with C<::> replaced by hyphens (C<->).
For example, C<My::Parent::Class> would use C<my-parent-class.yml>.

This allows you to define common settings in a base class configuration file and selectively override them in child class configurations, promoting DRY (Don't Repeat Yourself) principles and making it easier to manage configuration across class hierarchies.

Example:

    # File: config/my-base-class.yml
    ---
    My__Base__Class:
      timeout: 30
      retries: 3
      log_level: info

    # File: config/my-child-class.yml
    ---
    My__Child__Class:
      timeout: 60
      # Inherits retries: 3 and log_level: info from parent

    # Result: Child class gets timeout=60, retries=3, log_level=info

Parent configuration files are optional.
If a parent class's configuration file doesn't exist, the module simply skips it and continues up the inheritance chain.
All discovered configuration files are tracked in the C<_config_files> array for hot reload support.

=head2 CHANGING BEHAVIOUR AT RUN TIME

=head3 USING A CONFIGURATION FILE

To control behavior at runtime, C<Object::Configure> supports loading settings from a configuration file via L<Config::Abstraction>.

A minimal example of a config file (C<~/.conf/local.conf>) might look like:

   [My__Module]
   logger.file = /var/log/mymodule.log

The C<configure()> function will read this file,
overlay it onto your default parameters,
and initialize the logger accordingly.

If the file is not readable and no config_dirs are provided,
the module will throw an error.
To be clear, in this case, inheritance is not followed.

This mechanism allows dynamic tuning of logging behavior (or other parameters you expose) without modifying code.

More details to be written.

=head3 USING ENVIRONMENT VARIABLES

C<Object::Configure> also supports runtime configuration via environment variables,
without requiring a configuration file.

Environment variables are read automatically when you use the C<configure()> function,
thanks to its integration with L<Config::Abstraction>.
These variables should be prefixed with your class name, followed by a double colon.

For example, to enable syslog logging for your C<My::Module> class,
you could set:

    export My__Module__logger__file=/var/log/mymodule.log

This would be equivalent to passing the following in your constructor:

     My::Module->new(logger => Log::Abstraction->new({ file => '/var/log/mymodule.log' });

All environment variables are read and merged into the default parameters under the section named after your class.
This allows centralized and temporary control of settings (e.g., for production diagnostics or ad hoc testing) without modifying code or files.

Note that environment variable settings take effect regardless of whether a configuration file is used,
and are applied during the call to C<configure()>.

More details to be written.

=head2 HOT RELOAD

Hot reload is not supported on Windows.

=head3 Basic Hot Reload Setup

    package My::App;
    use Object::Configure;

    sub new {
        my $class = shift;
        my $params = Object::Configure::configure($class, @_ ? \@_ : undef);
        my $self = bless $params, $class;

        # Register for hot reload
        Object::Configure::register_object($class, $self) if $params->{_config_file};

        return $self;
    }

    # Optional: Define a reload hook
    sub _on_config_reload {
        my ($self, $new_config) = @_;
        print "My::App config was reloaded!\n";
        # Custom reload logic here
    }

=head3 Enable Hot Reload in Your Main Application

    # Enable hot reload with custom callback
    Object::Configure::enable_hot_reload(
        interval => 5,  # Check every 5 seconds
        callback => sub {
            print "Configuration files have been reloaded!\n";
        }
    );

    # Your application continues running...
    # Config changes will be automatically detected and applied

=head3 Manual Reload

    # Manually trigger a reload
    my $count = Object::Configure::reload_config();
    print "Reloaded configuration for $count objects\n";

=head1 SUBROUTINES/METHODS

=head2 configure

Configure your class at runtime with hot reload support.

Takes arguments:

=over 4

=item * C<class>

=item * C<params>

A hashref containing default parameters to be used in the constructor.

=item * C<carp_on_warn>

If set to 1, call C<Carp::carp> on C<warn()>.
This value is also read from the configuration file,
which will take precedence.
The default is 0.

=item * C<croak_on_error>

If set to 1, call C<Carp::croak> on C<error()>.
This value is also read from the configuration file,
which will take precedence.
The default is 1.

=item * C<logger>

The logger to use.
If none is given, an instatiation of L<Log::Abstraction> will be created, unless the logger is set to NULL.

=item * C<schema>

A L<Params::Validate::Strict> compatible schema to validate the configuration file against.

=back

Returns a hash ref containing the new values for the constructor.

Now you can set up a configuration file and environment variables to configure your object.

=cut

sub configure {
	my $class = $_[0];
	my $params = $_[1] || {};	# Contains the defaults, the run time config will overwrite them
	my $array;

	if(exists($params->{'logger'}) && (ref($params->{'logger'}) eq 'ARRAY')) {
		$array = delete $params->{'logger'};
	}

	my $original_class = $class;
	$class =~ s/::/__/g;

	# Store config file path for hot reload
	my $config_file = $params->{'config_file'};
	my $config_dirs = $params->{'config_dirs'};

	# Get inheritance chain for finding ancestor config files
	my @inheritance_chain = _get_inheritance_chain($original_class);

	# Build list of config files to load (ancestor to child order)
	my @config_files_to_load = ();
	my %tracked_files = ();

	if ($config_file) {
		# Check if primary config file is readable (unless config_dirs provided)
		if ((!$config_dirs) && (!-r $config_file)) {
			croak("$class: ", $config_file, ": $!");
		}

		# Find config files for each class in the hierarchy
		# Important: iterate in reverse order (base -> parent -> child)
		foreach my $ancestor_class (reverse @inheritance_chain) {
			my $ancestor_config_file = _find_class_config_file(
				$ancestor_class,
				$config_file,
				$config_dirs
			);

			# Skip if this is the primary config file - it will be added at the end
			if ($ancestor_config_file && $ancestor_config_file eq $config_file) {
				next;
			}

			# Only add if we found a file and haven't already added it
			if ($ancestor_config_file && -r $ancestor_config_file && !$tracked_files{$ancestor_config_file}) {
				push @config_files_to_load, {
					file => $ancestor_config_file,
					class => $ancestor_class
				};
				$tracked_files{$ancestor_config_file} = 1;

				# Track for hot reload
				if (-f $ancestor_config_file) {
					$_config_file_stats{$ancestor_config_file} = stat($ancestor_config_file);
				}
			}
		}

		# Ensure the primary config file is included LAST (highest priority)
		# This handles the case where the primary file doesn't match the class name pattern
		if ($config_file && !$tracked_files{$config_file} && -r $config_file) {
			push @config_files_to_load, {
				file => $config_file,
				class => $original_class
			};
			$tracked_files{$config_file} = 1;

			if (-f $config_file) {
				$_config_file_stats{$config_file} = stat($config_file);
			}
		}
	}

	# Sort by class hierarchy to ensure correct order (base -> parent -> child)
	# This must happen AFTER all files are collected
	if (@config_files_to_load) {
		my %class_order;
		for my $i (0..$#inheritance_chain) {
			$class_order{$inheritance_chain[$i]} = $i;
		}
		@config_files_to_load = sort {
			($class_order{$a->{class}} // 999) <=> ($class_order{$b->{class}} // 999)
		} @config_files_to_load;
	}

	# Load and merge configurations from all files
	if (@config_files_to_load) {
		# Start with the passed-in defaults
		my $merged_params = { %$params };

		foreach my $config_info (@config_files_to_load) {
			my $cfg_file = $config_info->{file};
			my $cfg_class = $config_info->{class};
			my $section_name = $cfg_class;
			$section_name =~ s/::/__/g;

			# When loading individual config files for inheritance,
			# don't pass config_dirs - just load the specific file
			my $config = Config::Abstraction->new(
				config_file => $cfg_file,
				env_prefix => "${section_name}__"
			);

			if ($config) {
				# Get this config file's values for the section
				my $this_config = $config->merge_defaults(
					defaults => {},
					section => $section_name,
					merge => 1,
					deep => 1
				);

				# Deep merge: later configs override earlier ones
				$merged_params = _deep_merge($merged_params, $this_config);
			} elsif ($@) {
				carp("Warning: Can't load configuration from $cfg_file: $@");
			}
		}

		$params = $merged_params;

	} elsif (my $config = Config::Abstraction->new(env_prefix => "${class}__")) {
		# Handle environment variables with inheritance
		my $merged_config = {};

		# Merge ancestor configurations from environment
		foreach my $ancestor_class (reverse @inheritance_chain) {
			my $section_name = $ancestor_class;
			$section_name =~ s/::/__/g;

			my $ancestor_env_config = Config::Abstraction->new(
				env_prefix => "${section_name}__"
			);

			if ($ancestor_env_config) {
				my $ancestor_config = $ancestor_env_config->merge_defaults(
					defaults => {},
					section => $section_name,
					merge => 1,
					deep => 1
				);
				$merged_config = _deep_merge($merged_config, $ancestor_config);
			}
		}

		$params = $config->merge_defaults(
			defaults => $params,
			section => $class,
			merge => 1,
			deep => 1
		);

		# Apply inherited config
		$params = _deep_merge($merged_config, $params);

		# Track this config file for hot reload
		if ($params->{config_path} && -f $params->{config_path}) {
			$_config_file_stats{$params->{config_path}} = stat($params->{config_path});
		}
	}

	my $croak_on_error = exists($params->{'croak_on_error'}) ? $params->{'croak_on_error'} : 1;
	my $carp_on_warn = exists($params->{'carp_on_warn'}) ? $params->{'carp_on_warn'} : 0;

	# Load the default logger
	if (my $logger = $params->{'logger'}) {
		if ($params->{'logger'} ne 'NULL') {
			if(ref($logger) eq 'HASH') {
				if ($logger->{'syslog'}) {
					$params->{'logger'} = Log::Abstraction->new({
						carp_on_warn => $carp_on_warn,
						syslog => $logger->{'syslog'},
						%{$logger}
					});
				} else {
					$params->{'logger'} = Log::Abstraction->new({
						carp_on_warn => $carp_on_warn,
						%{$logger}
					});
				}
			} elsif(!blessed($logger) || !$logger->isa('Log::Abstraction')) {
				$params->{'logger'} = Log::Abstraction->new({
					carp_on_warn => $carp_on_warn,
					logger => $logger
				});
			}
		}
	} elsif ($array) {
		$params->{'logger'} = Log::Abstraction->new(
			array => $array,
			carp_on_warn => $carp_on_warn
		);
		undef $array;
	} else {
		$params->{'logger'} = Log::Abstraction->new(carp_on_warn => $carp_on_warn);
	}

	if ($array && !$params->{'logger'}->{'array'}) {
		$params->{'logger'}->{'array'} = $array;
	}

	# Store config file path in params for hot reload
	$params->{_config_file} = $config_file if(defined($config_file));
	$params->{_config_files} = [map { $_->{file} } @config_files_to_load] if @config_files_to_load;

	return Return::Set::set_return($params, { 'type' => 'hashref' });
}

# Find the appropriate config file for a given class
# Looks for class-specific config files based on naming conventions
sub _find_class_config_file {
	my ($class, $base_config_file, $config_dirs) = @_;

	# Convert class name to file-friendly format
	my $class_file = lc($class);
	$class_file =~ s/::/-/g;

	# Extract directory, basename, and extension from base config file
	my ($base_dir, $base_name, $base_ext);

	if ($base_config_file =~ m{^(.*/)([^/]+?)(\.[^.]+)?$}) {
		$base_dir = $1 || '';
		$base_name = $2;
		$base_ext = $3 || '';
	} else {
		$base_name = $base_config_file;
		$base_dir = '';
		$base_ext = '';
	}

	# Try several naming patterns
	my @patterns = (
		"${base_dir}${class_file}${base_ext}",           # my-parent-class.yml
		"${base_dir}${class_file}.conf",                  # my-parent-class.conf
		"${base_dir}${class_file}.yml",                   # my-parent-class.yml
		"${base_dir}${class_file}.yaml",                  # my-parent-class.yaml
		"${base_dir}${class_file}.json",                  # my-parent-class.json
	);

	# Also try with config_dirs if provided
	if ($config_dirs && ref($config_dirs) eq 'ARRAY') {
		foreach my $dir (@$config_dirs) {
			# Remove trailing slash if present
			$dir =~ s{/$}{};
			push @patterns, (
				"${dir}/${class_file}${base_ext}",
				"${dir}/${class_file}.conf",
				"${dir}/${class_file}.yml",
				"${dir}/${class_file}.yaml",
				"${dir}/${class_file}.json",
			);
		}
	}

	# Return the first file that exists and is readable
	foreach my $pattern (@patterns) {
		if (-r $pattern && -f $pattern) {
			return $pattern;
		}
	}

	return undef;
}

# Helper function to get the inheritance chain for a class
sub _get_inheritance_chain {
	my ($class) = @_;
	my @chain = ();
	my %seen = ();

	_walk_isa($class, \@chain, \%seen);

	return @chain;
}

# Recursive function to walk the @ISA hierarchy
sub _walk_isa {
	my ($class, $chain, $seen) = @_;

	return if $seen->{$class}++;

	# Get the @ISA array for this class
	no strict 'refs';
	my @isa = @{"${class}::ISA"};
	use strict 'refs';

	# Recursively process parent classes first
	foreach my $parent (@isa) {
		# Skip common base classes that won't have configs
		next if $parent eq 'Exporter';
		next if $parent eq 'DynaLoader';
		next if $parent eq 'UNIVERSAL';

		_walk_isa($parent, $chain, $seen);
	}

	# Add current class to chain (after parents)
	push @$chain, $class;
}

# Deep merge two hash references
# Second hash takes precedence over first
sub _deep_merge {
	my ($base, $overlay) = @_;

	return $overlay unless ref($base) eq 'HASH';
	return $base unless ref($overlay) eq 'HASH';

	my $result = { %$base };

	foreach my $key (keys %$overlay) {
		if (ref($overlay->{$key}) eq 'HASH' && ref($result->{$key}) eq 'HASH') {
			$result->{$key} = _deep_merge($result->{$key}, $overlay->{$key});
		} else {
			$result->{$key} = $overlay->{$key};
		}
	}

	return $result;
}


=head2 instantiate($class,...)

Create and configure an object of the given class.
This is a quick and dirty way of making third-party classes configurable at runtime.

=cut

sub instantiate
{
	my $params = Params::Get::get_params('class', @_);

	my $class = $params->{'class'};
	$params = configure($class, $params);

	my $obj = $class->new($params);

	# Register object for hot reload if config file is used
	if ($params->{_config_file}) {
		register_object($class, $obj);
	}

	return $obj;
}

=head1 HOT RELOAD FEATURES

=head2 enable_hot_reload

Enable hot reloading for configuration files.

    Object::Configure::enable_hot_reload(
        interval => 5,  # Check every 5 seconds (default: 10)
        callback => sub { print "Config reloaded!\n"; }  # Optional callback
    );

=cut

sub enable_hot_reload {
	my %params = @_;

	my $interval = $params{interval} || 10;
	my $callback = $params{callback};

	# Don't start multiple watchers
	return if %_config_watchers;

	# Fork a background process to watch config files
	if (my $pid = fork()) {
		# Parent process - store the watcher PID
		$_config_watchers{pid} = $pid;
		$_config_watchers{callback} = $callback;
		return $pid;
	} elsif (defined $pid) {
		# Child process - run the file watcher
		_run_config_watcher($interval, $callback);
		exit 0;
	} else {
		croak("Failed to fork config watcher: $!");
	}
}

=head2 disable_hot_reload

Disable hot reloading and stop the background watcher.

    Object::Configure::disable_hot_reload();

=cut

sub disable_hot_reload {
	if (my $pid = $_config_watchers{pid}) {
		kill('TERM', $pid);
		waitpid($pid, 0);
		%_config_watchers = ();
	}
}

=head2 reload_config

Manually trigger a configuration reload for all registered objects.

    Object::Configure::reload_config();

=cut

sub reload_config {
	my $reloaded_count = 0;

	foreach my $class_key (keys %_object_registry) {
		my $objects = $_object_registry{$class_key};

		# Clean up dead object references
		@$objects = grep { defined $_ } @$objects;

		foreach my $obj_ref (@$objects) {
			if (my $obj = $$obj_ref) {
				eval {
					_reload_object_config($obj);
					$reloaded_count++;
				};
				if ($@) {
					warn "Failed to reload config for object: $@";
				}
			}
		}

		# Remove empty entries
		delete $_object_registry{$class_key} unless @$objects;
	}

	return $reloaded_count;
}

# Internal function to run the config file watcher
sub _run_config_watcher {
	my ($interval, $callback) = @_;

	# Set up signal handlers for clean shutdown
	local $SIG{TERM} = sub { exit 0 };
	local $SIG{INT} = sub { exit 0 };

	while (1) {
		sleep($interval);

		my $changes_detected = 0;

		# Check each monitored config file
		foreach my $config_file (keys %_config_file_stats) {
			if (-f $config_file) {
				my $current_stat = stat($config_file);
				my $stored_stat = $_config_file_stats{$config_file};

				# Compare modification times
				if ((!$stored_stat) || ($current_stat->mtime > $stored_stat->mtime)) {
					$_config_file_stats{$config_file} = $current_stat;
					$changes_detected = 1;
				}
			} else {
				# File was deleted
				delete $_config_file_stats{$config_file};
				$changes_detected = 1;
			}
		}

		if($changes_detected) {
			if($^O ne 'MSWin32') {
				# Reload configurations in the main process
				# Use a signal or shared memory mechanism
				if(my $parent_pid = getppid()) {
					kill('USR1', $parent_pid);
				}
			}
		}
	}
}

# Internal function to reload a single object's configuration
sub _reload_object_config {
	my ($obj) = @_;

	return unless blessed($obj);

	my $class = ref($obj);
	my $original_class = $class;
	$class =~ s/::/__/g;

	# Get the original config file path if it exists
	my $config_file = $obj->{_config_file} || $obj->{config_file};
	return unless $config_file && -f $config_file;

	# Reload the configuration
	my $config = Config::Abstraction->new(
		config_file => $config_file,
		env_prefix => "${class}__"
	);

	if ($config) {
		# Use merge_defaults with empty defaults to get just the config values
		my $new_params = $config->merge_defaults(
			defaults => {},
			section => $class,
			merge => 1,
			deep => 1
		);

		# Update object properties, preserving non-config data
		foreach my $key (keys %$new_params) {
			next if $key =~ /^_/;	# Skip private properties

			if($key =~ /^logger/ && $new_params->{$key} ne 'NULL') {
				# Handle logger reconfiguration specially
				_reconfigure_logger($obj, $key, $new_params->{$key});
			} else {
				$obj->{$key} = $new_params->{$key};
			}
		}

		# Call object's reload hook if it exists
		if ($obj->can('_on_config_reload')) {
			$obj->_on_config_reload($new_params);
		}

		# Log the reload if logger exists
		if ($obj->{logger} && $obj->{logger}->can('info')) {
			$obj->{logger}->info("Configuration reloaded for $original_class");
		}
	}
}

# Internal function to reconfigure the logger
sub _reconfigure_logger
{
	my ($obj, $key, $logger_config) = @_;

	if (ref($logger_config) eq 'HASH') {
		# Create new logger with new config
		my $carp_on_warn = $obj->{carp_on_warn} || 0;

		if ($logger_config->{syslog}) {
			$obj->{$key} = Log::Abstraction->new({
				carp_on_warn => $carp_on_warn,
				syslog => $logger_config->{syslog},
				%$logger_config
			});
		} else {
			$obj->{$key} = Log::Abstraction->new({
				carp_on_warn => $carp_on_warn,
				%$logger_config
			});
		}
	} else {
		$obj->{$key} = $logger_config;
	}
}

=head2 register_object

Register an object for hot reload monitoring.

    Object::Configure::register_object($class, $obj);

This is automatically called by the configure() function when a config file is used,
but can also be called manually to register objects for hot reload.

=cut

sub register_object {
	my ($class, $obj) = @_;

	# Use weak references to avoid memory leaks
	my $obj_ref = \$obj;
	weaken($$obj_ref);

	push @{$_object_registry{$class}}, $obj_ref;

	# Set up signal handler for hot reload (only once)
	if (!defined $_original_usr1_handler) {
		# Store the existing handler (could be DEFAULT, IGNORE, or a code ref)
		$_original_usr1_handler = $SIG{USR1} || 'DEFAULT';

		return if($^O eq 'MSWin32');	# There is no SIGUSR1 on Windows

		$SIG{USR1} = sub {
			# Handle our hot reload first
			reload_config();
			if ($_config_watchers{callback}) {
				$_config_watchers{callback}->();
			}

			# Chain to the original handler if it exists and is callable
			if (ref($_original_usr1_handler) eq 'CODE') {
				$_original_usr1_handler->();
			} elsif ($_original_usr1_handler eq 'DEFAULT') {
				# Let the default handler run (which typically does nothing for USR1)
				# We don't need to explicitly call it
			} elsif ($_original_usr1_handler eq 'IGNORE') {
				# Do nothing - the signal was being ignored
			}
			# Note: If it was some other string, it was probably a custom handler name
			# but we can't easily call those, so we'll just warn
			elsif ($_original_usr1_handler ne 'DEFAULT' && $_original_usr1_handler ne 'IGNORE') {
				warn "Object::Configure: Cannot chain to non-code USR1 handler: $_original_usr1_handler";
			}
		};
	}
}

=head2 restore_signal_handlers

Restore original signal handlers and disable hot reload integration.
Useful when you want to cleanly shut down the hot reload system.

    Object::Configure::restore_signal_handlers();

=cut

sub restore_signal_handlers
{
	if (defined $_original_usr1_handler) {
		$SIG{USR1} = $_original_usr1_handler if($^O ne 'MSWin32');	# There is no SIGUSR1 on Windows
		$_original_usr1_handler = undef;
	}
}

=head2 get_signal_handler_info

Get information about the current signal handler setup.
Useful for debugging signal handler chains.

    my $info = Object::Configure::get_signal_handler_info();
    print "Original USR1 handler: ", $info->{original_usr1} || 'none', "\n";
    print "Hot reload active: ", $info->{hot_reload_active} ? 'yes' : 'no', "\n";

=cut

sub get_signal_handler_info {
	return {
		original_usr1 => $_original_usr1_handler,
		current_usr1 => $SIG{USR1},
		hot_reload_active => defined $_original_usr1_handler,
		watcher_pid => $_config_watchers{pid},
	};
}

# Cleanup on module destruction
END {
	disable_hot_reload();

	# Restore original USR1 handler if we modified it
	restore_signal_handlers();
}

=head1 SEE ALSO

=over 4

=item * L<Config::Abstraction>

=item * L<Log::Abstraction>

=item * Test coverage report: L<https://nigelhorne.github.io/Object-Configure/coverage/>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-object-configure at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Configure>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Object::Configure

=head1 LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
