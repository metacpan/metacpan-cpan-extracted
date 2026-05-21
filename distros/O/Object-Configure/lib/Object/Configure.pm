package Object::Configure;

use strict;
use warnings;

use Carp;
use Config::Abstraction 0.38;
use File::Spec;
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

0.21

=cut

our $VERSION = 0.21;

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

C<Object::Configure> supports configuration inheritance, allowing child classes to inherit and override configuration settings from their parent classes.
When a class is configured, the module automatically traverses the inheritance hierarchy (using C<@ISA>) and loads configuration files for each ancestor class in the chain.

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

    # File: ~/.conf/my-base-class.yml
    ---
    My__Base__Class:
      timeout: 30
      retries: 3
      log_level: info

    # File: ~/.conf/my-child-class.yml
    ---
    My__Child__Class:
      timeout: 60
      # Inherits retries: 3 and log_level: info from parent

    # Result: Child class gets timeout=60, retries=3, log_level=info

Parent configuration files are optional.
If a parent class's configuration file doesn't exist, the module simply skips it and continues up the inheritance chain.
All discovered configuration files are tracked in the C<_config_files> array for hot reload support.

=head3 UNIVERSAL CONFIGURATION

All Perl classes implicitly inherit from C<UNIVERSAL>.
C<Object::Configure> takes advantage of this to provide a mechanism for universal configuration settings
that apply to all classes by default.

If you create a configuration file named C<universal.yml> (or C<universal.conf>, C<universal.json>, etc.)
in your configuration directory,
the settings in its C<UNIVERSAL> section will be inherited by all classes that use C<Object::Configure>,
unless explicitly overridden by class-specific configuration files.

This is particularly useful for setting application-wide defaults such as logging levels,
timeout values,
or other common parameters that should apply across all modules.

Example C<~/.conf/universal.yml>:

    ---
    UNIVERSAL:
      timeout: 30
      retries: 3
      logger:
        level: info

With this universal configuration file in place,
all classes will inherit these default values.
Individual classes can override any of these settings in their own configuration files:

Example C<~/.conf/my-special-class.yml>:

    ---
    My__Special__Class:
      timeout: 120
      # Inherits retries: 3 and logger.level: info from UNIVERSAL

The universal configuration is loaded first in the inheritance chain,
followed by parent class configurations,
and finally the specific class configuration,
with later configurations overriding earlier ones.

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

=encoding utf8

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

=head3 API Specification

=head4 Input

    schema => {
        class => {
            type => 'string',
            required => 1,
            description => 'Fully-qualified class name'
        },
        params => {
            type => 'hashref',
            optional => 1,
            default => {},
            schema => {
                config_file => {
                    type => 'string',
                    optional => 1,
                    description => 'Configuration file basename'
                }, config_dirs => {
                    type => 'arrayref',
                    optional => 1,
                    description => 'Directories to search for config files'
                }, logger => {
                    type => [qw(hashref coderef object string arrayref)],
                    optional => 1,
                    description => 'Logger configuration or instance'
                }, carp_on_warn => {
                    type => 'boolean',
                    optional => 1,
                    default => 0,
                    description => 'Use Carp::carp for warnings'
                }, croak_on_error => {
                    type => 'boolean',
                    optional => 1,
                    default => 1,
                    description => 'Use Carp::croak for errors'
                }
            }
        }
    }

=head4 Output

    type => 'hashref',
    description => 'Merged configuration parameters',
    schema => {
        logger => {
            type => 'object',
            isa => 'Log::Abstraction',
            description => 'Initialized logger instance'
        },
        _config_file => {
            type => 'string',
            optional => 1,
            description => 'Primary configuration file path'
        },
        _config_files => {
            type => 'arrayref',
            optional => 1,
            description => 'All loaded configuration file paths'
        }
    }

=head3 Formal Specification

    configure: Class × Params → ConfigHash

    Given:
    - C: set of all class names
    - P: set of all parameter hashes
    - F: set of all file paths
    - H: set of all configuration hashes

    State:
    - ConfigFiles: F → H (maps file paths to configuration content)
    - EnvVars: String → String (environment variables)
    - InheritanceChain: C → seq C (ordered sequence of ancestor classes)

    Pre-condition:
    ∀ class ∈ C, params ∈ P •
        class ≠ ∅ ∧
        (params.config_file ≠ ∅ ⇒
            (∃ dir ∈ params.config_dirs • readable(dir/params.config_file)) ∨
            readable(params.config_file))

    Post-condition:
    ∀ result ∈ H •
        result = params ⊕
                 (⊕ f ∈ InheritanceConfigFiles(class) • ConfigFiles(f)) ⊕
                 (⊕ v ∈ RelevantEnvVars(class) • v) ∧
        result.logger ∈ Log::Abstraction ∧
        (∀ k ∈ dom params •
            (params(k) ∈ CodeRef ∨ blessed(params(k))) ⇒ result(k) = params(k))

    where ⊕ denotes hash merge with right-precedence

=cut

sub configure {
	my $class = $_[0];
	my $params = $_[1] || {};	# Contains the defaults, the run time config will overwrite them
	my $array;

	croak(__PACKAGE__, ': configure: what class do you want to configure?') if(!defined($class) || $class eq '');

	# Stash coderefs and blessed objects EXCEPT logger (which needs special handling)

	# Config::Abstraction treats unknown scalar values as config file paths and will
	# attempt to read them, which corrupts coderefs and object references.
	# We must remove these from $params before calling configure(), then restore them
	# afterward. The logger parameter has its own special handling below, so we skip it here.
	# This automatic stashing means users don't need to implement the stash-delete-restore
	# pattern in their own constructors.
	my %stashed_values;
	foreach my $key (keys %$params) {
		next if $key eq 'logger';	# logger has its own special handling below
		my $value = $params->{$key};
		if(ref($value) eq 'CODE' || blessed($value)) {
			$stashed_values{$key} = delete $params->{$key};
		}
	}

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

		if(!scalar(@config_files_to_load)) {
			# Can't find an inheritence tree
			foreach my $dir(@{$config_dirs}) {
				my $candidate = File::Spec->catfile($dir, $config_file);
				if(-r $candidate) {
					push @config_files_to_load, {
						file => $candidate,
						class => $original_class
					};
					last;  # CRITICAL: Stop at first readable file
				}
			}
		}
	}

	# Load and merge configurations from all files
	if (@config_files_to_load) {
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
		if(!ref($logger) && $logger eq 'NULL') {
			# Explicitly keep NULL - do not create a logger
			# The logger param stays as the string 'NULL'
		} elsif(ref($logger) eq 'HASH') {
			if(exists $logger->{'syslog'}) {
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
	} elsif ($array) {
		$params->{'logger'} = Log::Abstraction->new(
			array => $array,
			carp_on_warn => $carp_on_warn
		);
		undef $array;
	} else {
		$params->{'logger'} = Log::Abstraction->new(carp_on_warn => $carp_on_warn);
	}

	if(exists($params->{'logger'}) && ref($params->{'logger'})) {
		if ($array && !$params->{'logger'}->{'array'}) {
			$params->{'logger'}->{'array'} = $array;
		}

		if ($array && !$params->{'logger'}->{'array'}) {
			$params->{'logger'}->{'array'} = $array;
		}
	}

	# Store config file path in params for hot reload
	# Preserve user-provided internal keys
	if (!exists($params->{_config_file})) {
		$params->{_config_file} = $config_file if defined($config_file);
	}
	if (!exists($params->{_config_files})) {
		$params->{_config_files} = [map { $_->{file} } @config_files_to_load] if @config_files_to_load;
	}

	# Restore stashed coderefs and objects via hash slice
	@{$params}{keys %stashed_values} = values %stashed_values if %stashed_values;

	return Return::Set::set_return($params, { 'type' => 'hashref' });
}

# Find the appropriate config file for a given class
# Looks for class-specific config files based on naming conventions
sub _find_class_config_file {
	my ($class, $base_config_file, $config_dirs) = @_;

	# Convert class name to file-friendly format
	my $class_file = lc($class);
	$class_file =~ s/::/-/g;

	# Extract directory and extension from base config file using File::Spec
	# so that path separators are handled correctly on all platforms
	my ($base_vol, $base_dir_part, $base_name_ext) = File::Spec->splitpath($base_config_file);
	my (undef, $base_ext) = $base_name_ext =~ /^(.*?)(\.[^.]+)?$/;
	$base_ext //= '';	# $2 is undef when there is no extension
	my $base_dir = File::Spec->catpath($base_vol, $base_dir_part, '');

	# Try base directory patterns first
	my @base_patterns = (
		File::Spec->catfile($base_dir, "${class_file}${base_ext}"),
		File::Spec->catfile($base_dir, "${class_file}.conf"),
		File::Spec->catfile($base_dir, "${class_file}.yml"),
		File::Spec->catfile($base_dir, "${class_file}.yaml"),
		File::Spec->catfile($base_dir, "${class_file}.json"),
	);

	foreach my $pattern (@base_patterns) {
		if (-r $pattern && -f $pattern) {
			return $pattern;
		}
	}

	# Then try config_dirs in order - fully check each dir before moving to next
	if ($config_dirs && ref($config_dirs) eq 'ARRAY') {
		foreach my $dir (@$config_dirs) {
			# Remove trailing slash if present
			$dir =~ s{/$}{};
			my @dir_patterns = (
				"${dir}/${class_file}${base_ext}",
				"${dir}/${class_file}.conf",
				"${dir}/${class_file}.yml",
				"${dir}/${class_file}.yaml",
				"${dir}/${class_file}.json",
			);
			foreach my $pattern (@dir_patterns) {
				if (-r $pattern && -f $pattern) {
					return $pattern;
				}
			}
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
		# next if $parent eq 'Exporter';
		# next if $parent eq 'DynaLoader';
		# next if $parent eq 'UNIVERSAL';

		_walk_isa($parent, $chain, $seen);
	}

	# If this class has no parents and isn't UNIVERSAL itself,
	# explicitly add UNIVERSAL as a parent
	if (!@isa && $class ne 'UNIVERSAL') {
		_walk_isa('UNIVERSAL', $chain, $seen);
	}

	# Add current class to chain (after parents)
	push @$chain, $class;
}

# Deep merge two hash references
# Second hash takes precedence over first
sub _deep_merge {
	my ($base, $overlay) = @_;

	return $overlay unless ref($base) eq 'HASH';
	return $overlay unless ref($overlay) eq 'HASH';

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

Create and configure an object of a third-party class without modifying the class itself.

=head3 Purpose

Provides a convenient way to make third-party classes (those you cannot modify) configurable
at runtime using Object::Configure. This is a wrapper that calls C<configure> and then
instantiates the class.

=head3 Arguments

Takes a hash or hashref with the following keys:

=over 4

=item * C<class> (Required)

The fully-qualified class name to instantiate (e.g., C<'LWP::UserAgent'>).

=item * Additional keys

Any additional keys are passed through to C<configure> and then to the class constructor.

=back

=head3 Returns

A blessed object of the specified class, configured according to the parameters and
configuration files.

=head3 Side Effects

=over 4

=item * Calls C<configure> (see its side effects)

=item * Calls the C<new> method on the specified class

=item * Registers the object for hot reload if a configuration file was used

=back

=head3 Notes

The specified class must have a C<new> method that accepts a hashref of parameters.
This is a "quick and dirty" way to add configuration support to classes you don't control.

=head3 Usage Example

    use Object::Configure;

    # Configure LWP::UserAgent from a config file
    my $ua = Object::Configure::instantiate(
        class => 'LWP::UserAgent',
        config_file => 'lwp.yml',
        config_dirs => ['/etc/myapp'],
        timeout => 30
    );

=head3 API Specification

=head4 Input

    schema => {
        class => {
            type => 'string',
            required => 1,
            description => 'Class name to instantiate',
            can => 'new'
        }
    }

=head4 Output

    type => 'object',
    description => 'Instance of the specified class'

=head3 Formal Specification

    instantiate: Params → Object

    Given:
    - P: set of all parameter hashes
    - C: set of all class names
    - O: set of all objects

    Pre-condition:
    ∀ params ∈ P •
        params.class ∈ C ∧
        params.class.can('new')

    Post-condition:
    ∀ result ∈ O •
        ∃ config ∈ H •
            config = configure(params.class, params) ∧
            result = params.class.new(config) ∧
            blessed(result) = params.class ∧
            (config._config_file ≠ ∅ ⇒
                result ∈ _object_registry(params.class))

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

Enable automatic hot reloading of configuration files when they are modified.

=head3 Purpose

Starts a background process that monitors configuration files for changes and automatically
reloads them into registered objects. This allows runtime configuration updates without
restarting the application.

=head3 Arguments

Takes a hash with the following optional keys:

=over 4

=item * C<interval> (Optional, default: 10)

Number of seconds between configuration file checks. Lower values provide faster
response to changes but consume more CPU.

=item * C<callback> (Optional)

A coderef to execute after configuration files are reloaded. Useful for logging
or triggering application-specific reload behavior.

=back

=head3 Returns

The process ID (PID) of the background watcher process on success.
Returns immediately if hot reload is already enabled.

=head3 Side Effects

=over 4

=item * Forks a background process to monitor configuration files

=item * The background process sends SIGUSR1 to the parent when changes are detected

=item * Stores the watcher PID in C<%_config_watchers>

=item * May throw an exception (via C<croak>) if the fork fails

=back

=head3 Notes

Hot reload is not supported on Windows due to lack of SIGUSR1 signal support.
The background process runs indefinitely until C<disable_hot_reload> is called.
Objects must be registered via C<register_object> to receive configuration updates.

=head3 Usage Example

    use Object::Configure;

    # Enable hot reload with 5-second check interval
    Object::Configure::enable_hot_reload(
        interval => 5,
        callback => sub {
            my $timestamp = localtime;
            print "[$timestamp] Configuration reloaded\n";
        }
    );

    # Application continues running...
    while (1) {
        # Do work...
        sleep(1);
    }

=head3 API Specification

=head4 Input

    schema => {
        interval => {
            type => 'integer',
            optional => 1,
            default => 10,
            min => 1,
            description => 'Check interval in seconds'
        },
        callback => {
            type => 'coderef',
            optional => 1,
            description => 'Code to execute after reload'
        }
    }

=head4 Output

    type => 'integer',
    description => 'PID of background watcher process',
    condition => 'value > 0'

=head3 Formal Specification

    enable_hot_reload: Interval × Callback → PID

    Given:
    - I: set of positive integers (intervals in seconds)
    - CB: set of code references
    - PID: set of process identifiers

    State:
    - _config_watchers: {pid: PID, callback: CB}
    - _config_file_stats: F → Stat

    Pre-condition:
    ∀ interval ∈ I, callback ∈ CB ∪ {∅} •
        interval ≥ 1 ∧
        _config_watchers = ∅ ∧
        OS ≠ 'MSWin32'

    Post-condition:
    ∀ result ∈ PID •
        result > 0 ∧
        _config_watchers.pid = result ∧
        _config_watchers.callback = callback ∧
        (∀ t ∈ Time •
            (t mod interval = 0) ⇒
                (∃ f ∈ dom _config_file_stats •
                    mtime(f) > _config_file_stats(f).mtime ⇒
                        send_signal(SIGUSR1, parent_process)))

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

Disable hot reloading and terminate the background watcher process.

=head3 Purpose

Cleanly shuts down the hot reload system by terminating the background watcher
process and clearing internal state.

=head3 Arguments

None.

=head3 Returns

Nothing.

=head3 Side Effects

=over 4

=item * Sends SIGTERM to the background watcher process

=item * Waits for the watcher process to terminate

=item * Clears C<%_config_watchers> state

=back

=head3 Notes

Safe to call even if hot reload is not currently enabled.
The function blocks until the watcher process has fully terminated.

=head3 Usage Example

    use Object::Configure;

    # Enable hot reload
    Object::Configure::enable_hot_reload(interval => 5);

    # ... application runs ...

    # Clean shutdown
    Object::Configure::disable_hot_reload();

=head3 API Specification

=head4 Input

    schema => {}

=head4 Output

    type => 'void'

=head3 Formal Specification

    disable_hot_reload: () → ()

    State:
    - _config_watchers: {pid: PID, callback: CB}

    Pre-condition:
    true

    Post-condition:
    _config_watchers = ∅ ∧
    (∀ p ∈ PID •
        p = _config_watchers.pid@pre ⇒
            ¬alive(p))

=cut

sub disable_hot_reload {
	## MUTANT_SKIP_BEGIN
	if (my $pid = $_config_watchers{pid}) {
		# Guard against non-numeric PIDs (e.g. from mutation testing)
		if($pid =~ /\A[0-9]+\z/ && $pid > 0) {
			kill('TERM', $pid);

			# Wait up to 5 seconds for the child to exit; if it doesn't respond
			# to SIGTERM, escalate to SIGKILL to avoid hanging indefinitely
			my $deadline = time() + 5;
			my $kid;
			do {
				$kid = waitpid($pid, POSIX::WNOHANG());
				if($kid == 0 && time() < $deadline) {
					select undef, undef, undef, 0.1;	# sleep 100ms between polls
				}
			} while($kid == 0 && time() < $deadline);

			# Escalate if still alive after timeout
			if($kid == 0) {
				kill('KILL', $pid);
				waitpid($pid, 0);	# SIGKILL is not deferrable; this wait is safe
			}
		}
		%_config_watchers = ();
	}
	## MUTANT_SKIP_END
}

=head2 reload_config

Manually trigger configuration reload for all registered objects.

=head3 Purpose

Forces an immediate reload of configuration from files for all objects that have been
registered for hot reload. This is useful for testing or forcing a reload without
waiting for the automatic file monitoring to detect changes.

=head3 Arguments

None.

=head3 Returns

An integer count of how many objects had their configuration successfully reloaded.

=head3 Side Effects

=over 4

=item * Reads configuration files from disk

=item * Updates object properties with new configuration values

=item * Calls C<_on_config_reload> hook on objects that implement it

=item * Cleans up dead weak references from C<%_object_registry>

=item * May emit warnings if configuration reload fails for any object

=back

=head3 Notes

Only objects registered via C<register_object> are reloaded.
Objects are updated in-place; their identity does not change.
Private properties (those starting with C<_>) are not updated during reload.

=head3 Usage Example

    use Object::Configure;

    # Create and register objects
    my $obj = My::Module->new(config_file => 'app.yml');

    # Manually edit app.yml...

    # Force immediate reload
    my $count = Object::Configure::reload_config();
    print "Reloaded configuration for $count objects\n";

=head3 API Specification

=head4 Input

    schema => {}

=head4 Output

    type => 'integer',
    description => 'Number of objects successfully reloaded',
    condition => 'value >= 0'

=head3 Formal Specification

    reload_config: () → ℕ

    State:
    - _object_registry: C → seq ObjectRef
    - ConfigFiles: F → H

    Pre-condition:
    true

    Post-condition:
    ∀ result ∈ ℕ •
        result = |{obj ∈ flatten(ran _object_registry) |
                   obj ≠ ∅ ∧
                   obj._config_file ∈ dom ConfigFiles}| ∧
        (∀ obj ∈ flatten(ran _object_registry) •
            obj ≠ ∅ ∧ obj._config_file ∈ dom ConfigFiles ⇒
                (∀ k ∈ dom ConfigFiles(obj._config_file) •
                    k ∉ PrivateKeys ⇒
                        obj(k)@post = ConfigFiles(obj._config_file)(k)))

    where PrivateKeys = {k | k starts with '_'}

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
	my $obj = $_[0];

	return unless blessed($obj);

	my $class = ref($obj);
	my $original_class = $class;
	$class =~ s/::/__/g;

	# Get the original config file path(s) if they exist
	# Use the full path from _config_files if available, otherwise try _config_file
	my $config_file;
	if ($obj->{_config_files} && ref($obj->{_config_files}) eq 'ARRAY' && @{$obj->{_config_files}}) {
		# Use the last (most specific) config file
		$config_file = $obj->{_config_files}[-1];
	} else {
		$config_file = $obj->{_config_file} || $obj->{config_file};
	}

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

	return;
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

=head2 register_object($class, $obj)

Register an object for hot reload monitoring.

=head3 Purpose

Adds an object to the hot reload registry so it will receive automatic configuration
updates when files change. Uses weak references to prevent memory leaks.

=head3 Arguments

=over 4

=item * C<class> (Required)

The class name of the object, used for organizing the registry.

=item * C<obj> (Required)

The object instance to register. Must be a blessed reference.

=back

=head3 Returns

Nothing.

=head3 Side Effects

=over 4

=item * Adds a weak reference to the object in C<%_object_registry>

=item * Sets up SIGUSR1 signal handler on first call (Unix-like systems only)

=item * Stores the original SIGUSR1 handler for later restoration

=back

=head3 Notes

Objects are stored using weak references, so they will be automatically
garbage collected when no other references exist.
The SIGUSR1 handler chains to any existing handler that was installed.
On Windows, the signal handler is not installed (SIGUSR1 does not exist).

=head3 Usage Example

    package My::Module;
    use Object::Configure;

    sub new {
        my $class = shift;
        my $params = Object::Configure::configure($class, {
            config_file => 'mymodule.yml',
        });
        my $self = bless $params, $class;

        # Register for hot reload
        Object::Configure::register_object($class, $self)
            if $params->{_config_file};

        return $self;
    }

=head3 API Specification

=head4 Input

    schema => {
        class => {
            type => 'string',
            required => 1,
            description => 'Class name for registry organization'
        },
        obj => {
            type => 'object',
            required => 1,
            description => 'Blessed object instance to register'
        }
    }

=head4 Output

    type => 'void'

=head3 Formal Specification

    register_object: C × O → ()

    Given:
    - C: set of class names
    - O: set of blessed objects
    - OR: C → seq WeakRef(O) (object registry)

    State:
    - _object_registry: OR
    - _original_usr1_handler: SignalHandler ∪ {∅}
    - $SIG{USR1}: SignalHandler

    Pre-condition:
    ∀ class ∈ C, obj ∈ O •
        class ≠ ∅ ∧
        obj ≠ ∅ ∧
        blessed(obj) ≠ ∅

    Post-condition:
    ∀ class ∈ C, obj ∈ O •
        ∃ ref ∈ _object_registry(class) •
            weak(ref) = obj ∧
        (_original_usr1_handler = ∅@pre ⇒
            (_original_usr1_handler@post = $SIG{USR1}@pre ∧
             $SIG{USR1}@post = reload_config_handler))

=cut

sub register_object
{
	my ($class, $obj) = @_;

	croak(__PACKAGE__, '::register_object: Usage ($class, $obj)') unless(defined($class) && defined($obj));

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
	return;	# ensure the functions return nothing (void/empty list)
}

=head2 restore_signal_handlers

Restore original signal handlers and disable hot reload integration.

=head3 Purpose

Restores the signal handler that was in place before Object::Configure installed
its SIGUSR1 handler. This is useful for clean shutdown or when transferring
control to another hot reload system.

=head3 Arguments

None.

=head3 Returns

Nothing.

=head3 Side Effects

=over 4

=item * Restores C<$SIG{USR1}> to its original value

=item * Clears C<$_original_usr1_handler> internal state

=back

=head3 Notes

Safe to call even if Object::Configure never installed a signal handler.
On Windows, this function has no effect (SIGUSR1 does not exist).

=head3 Usage Example

    use Object::Configure;

    # Objects are registered...

    # Clean shutdown
    Object::Configure::disable_hot_reload();
    Object::Configure::restore_signal_handlers();

=head3 API Specification

=head4 Input

    schema => {}

=head4 Output

    type => 'void'

=head3 Formal Specification

    restore_signal_handlers: () → ()

    State:
    - _original_usr1_handler: SignalHandler ∪ {∅}
    - $SIG{USR1}: SignalHandler

    Pre-condition:
    true

    Post-condition:
    $SIG{USR1}@post = _original_usr1_handler@pre ∧
    _original_usr1_handler@post = ∅

=cut

sub restore_signal_handlers
{
	if (defined $_original_usr1_handler) {
		$SIG{USR1} = $_original_usr1_handler if($^O ne 'MSWin32');	# There is no SIGUSR1 on Windows
		$_original_usr1_handler = undef;
	}

	return;	# ensure the functions return nothing (void/empty list)
}

=head2 get_signal_handler_info

Get information about the current signal handler setup for debugging.

=head3 Purpose

Returns diagnostic information about the signal handler state, useful for
debugging signal handler chains or verifying hot reload configuration.

=head3 Arguments

None.

=head3 Returns

A hashref containing the following keys:

=over 4

=item * C<original_usr1>

The signal handler that was installed before Object::Configure's handler,
or undef if no handler was present.

=item * C<current_usr1>

The currently installed SIGUSR1 handler.

=item * C<hot_reload_active>

Boolean indicating whether Object::Configure's hot reload handler is active.

=item * C<watcher_pid>

The PID of the background watcher process, or undef if not running.

=back

=head3 Side Effects

None.

=head3 Notes

This is primarily a debugging aid and is not needed for normal operation.

=head3 Usage Example

    use Object::Configure;
    use Data::Dumper;

    Object::Configure::enable_hot_reload();

    my $info = Object::Configure::get_signal_handler_info();
    print Dumper($info);
    # $VAR1 = {
    #     'original_usr1' => 'DEFAULT',
    #     'current_usr1' => CODE(0x...),
    #     'hot_reload_active' => 1,
    #     'watcher_pid' => 12345
    # };

=head3 API Specification

=head4 Input

    schema => {}

=head4 Output

    type => 'hashref',
    schema => {
        original_usr1 => {
            type => [qw(coderef string undef)],
            description => 'Original SIGUSR1 handler'
        },
        current_usr1 => {
            type => [qw(coderef string undef)],
            description => 'Current SIGUSR1 handler'
        },
        hot_reload_active => {
            type => 'boolean',
            description => 'Whether hot reload is active'
        },
        watcher_pid => {
            type => [qw(integer undef)],
            description => 'Background watcher process PID'
        }
    }

=head3 Formal Specification

    get_signal_handler_info: () → InfoHash

    Given:
    - IH: set of all info hashes

    State:
    - _original_usr1_handler: SignalHandler ∪ {∅}
    - $SIG{USR1}: SignalHandler ∪ {∅}
    - _config_watchers: {pid: PID, callback: CB}

    Pre-condition:
    true

    Post-condition:
    ∀ result ∈ IH •
        result.original_usr1 = _original_usr1_handler ∧
        result.current_usr1 = $SIG{USR1} ∧
        result.hot_reload_active = (_original_usr1_handler ≠ ∅) ∧
        result.watcher_pid = _config_watchers.pid

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

=item * L<Test Dashboard|https://nigelhorne.github.io/Object-Configure/coverage/>

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

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
