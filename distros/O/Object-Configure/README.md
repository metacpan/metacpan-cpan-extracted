[![CPAN version](https://badge.fury.io/pl/Object-Configure.svg)](https://metacpan.org/pod/Object::Debug)
![Perl CI](https://github.com/nigelhorne/Object-Configure/actions/workflows/perl-ci.yml/badge.svg)

# NAME

Object::Configure - Runtime Configuration for an Object

# VERSION

0.21

# SYNOPSIS

The `Object::Configure` module is a lightweight utility designed to inject runtime parameters into other classes,
primarily by layering configuration and logging support,
when instatiating objects.

[Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) and [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction) are modules developed to solve a specific need,
runtime configurability without needing to rewrite or hardcode behaviours.
The goal is to allow individual modules to enable or disable features on the fly,
and to do it using whatever configuration system the user prefers.

Although the initial aim was general configurability,
the primary use case that's emerged has been fine-grained logging control,
more flexible and easier to manage than what you'd typically do with [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl).
For example,
you might want one module to log verbosely while another stays quiet,
and be able to toggle that dynamically - without making invasive changes to each module.

To tie it all together,
there is `Object::Configure`.
It sits on [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) and [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction),
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
         my $params = Object::Configure::configure($class, @_ ? \@_ : undef);    # Reads in the runtime configuration settings
         # or my $params = Object::Configure::configure($class, { @_ });

         return bless $params, $class;
     }

Throughout your class, add code such as:

    sub method
    {
        my $self = shift;

        $self->{'logger'}->trace(ref($self), ': ', __LINE__, ' entering method');
    }

### CONFIGURATION INHERITANCE

`Object::Configure` supports configuration inheritance, allowing child classes to inherit and override configuration settings from their parent classes.
When a class is configured, the module automatically traverses the inheritance hierarchy (using `@ISA`) and loads configuration files for each ancestor class in the chain.

Configuration files are loaded in order from the most general (base class) to the most specific (child class), with later files overriding earlier ones. For example, if `My::Child::Class` inherits from `My::Parent::Class`, which inherits from `My::Base::Class`, the module will:

- 1. Load `my-base-class.yml` (or .conf, .json, etc.) if it exists
- 2. Load `my-parent-class.yml` if it exists, overriding base settings
- 3. Load `my-child-class.yml`, overriding both parent and base settings

The configuration files should be named using lowercase versions of the class name with `::` replaced by hyphens (`-`).
For example, `My::Parent::Class` would use `my-parent-class.yml`.

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
All discovered configuration files are tracked in the `_config_files` array for hot reload support.

### UNIVERSAL CONFIGURATION

All Perl classes implicitly inherit from `UNIVERSAL`.
`Object::Configure` takes advantage of this to provide a mechanism for universal configuration settings
that apply to all classes by default.

If you create a configuration file named `universal.yml` (or `universal.conf`, `universal.json`, etc.)
in your configuration directory,
the settings in its `UNIVERSAL` section will be inherited by all classes that use `Object::Configure`,
unless explicitly overridden by class-specific configuration files.

This is particularly useful for setting application-wide defaults such as logging levels,
timeout values,
or other common parameters that should apply across all modules.

Example `~/.conf/universal.yml`:

    ---
    UNIVERSAL:
      timeout: 30
      retries: 3
      logger:
        level: info

With this universal configuration file in place,
all classes will inherit these default values.
Individual classes can override any of these settings in their own configuration files:

Example `~/.conf/my-special-class.yml`:

    ---
    My__Special__Class:
      timeout: 120
      # Inherits retries: 3 and logger.level: info from UNIVERSAL

The universal configuration is loaded first in the inheritance chain,
followed by parent class configurations,
and finally the specific class configuration,
with later configurations overriding earlier ones.

## CHANGING BEHAVIOUR AT RUN TIME

### USING A CONFIGURATION FILE

To control behavior at runtime, `Object::Configure` supports loading settings from a configuration file via [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction).

A minimal example of a config file (`~/.conf/local.conf`) might look like:

    [My__Module]
    logger.file = /var/log/mymodule.log

The `configure()` function will read this file,
overlay it onto your default parameters,
and initialize the logger accordingly.

If the file is not readable and no config\_dirs are provided,
the module will throw an error.
To be clear, in this case, inheritance is not followed.

This mechanism allows dynamic tuning of logging behavior (or other parameters you expose) without modifying code.

More details to be written.

### USING ENVIRONMENT VARIABLES

`Object::Configure` also supports runtime configuration via environment variables,
without requiring a configuration file.

Environment variables are read automatically when you use the `configure()` function,
thanks to its integration with [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction).
These variables should be prefixed with your class name, followed by a double colon.

For example, to enable syslog logging for your `My::Module` class,
you could set:

    export My__Module__logger__file=/var/log/mymodule.log

This would be equivalent to passing the following in your constructor:

     My::Module->new(logger => Log::Abstraction->new({ file => '/var/log/mymodule.log' });

All environment variables are read and merged into the default parameters under the section named after your class.
This allows centralized and temporary control of settings (e.g., for production diagnostics or ad hoc testing) without modifying code or files.

Note that environment variable settings take effect regardless of whether a configuration file is used,
and are applied during the call to `configure()`.

More details to be written.

## HOT RELOAD

Hot reload is not supported on Windows.

### Basic Hot Reload Setup

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

### Enable Hot Reload in Your Main Application

    # Enable hot reload with custom callback
    Object::Configure::enable_hot_reload(
        interval => 5,  # Check every 5 seconds
        callback => sub {
            print "Configuration files have been reloaded!\n";
        }
    );

    # Your application continues running...
    # Config changes will be automatically detected and applied

### Manual Reload

    # Manually trigger a reload
    my $count = Object::Configure::reload_config();
    print "Reloaded configuration for $count objects\n";

# SUBROUTINES/METHODS

## configure

Configure your class at runtime with hot reload support.

Takes arguments:

- `class`
- `params`

    A hashref containing default parameters to be used in the constructor.

- `carp_on_warn`

    If set to 1, call `Carp::carp` on `warn()`.
    This value is also read from the configuration file,
    which will take precedence.
    The default is 0.

- `croak_on_error`

    If set to 1, call `Carp::croak` on `error()`.
    This value is also read from the configuration file,
    which will take precedence.
    The default is 1.

- `logger`

    The logger to use.
    If none is given, an instatiation of [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) will be created, unless the logger is set to NULL.

- `schema`

    A [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict) compatible schema to validate the configuration file against.

Returns a hash ref containing the new values for the constructor.

Now you can set up a configuration file and environment variables to configure your object.

### API Specification

#### Input

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

#### Output

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

### Formal Specification

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

## instantiate($class,...)

Create and configure an object of a third-party class without modifying the class itself.

### Purpose

Provides a convenient way to make third-party classes (those you cannot modify) configurable
at runtime using Object::Configure. This is a wrapper that calls `configure` and then
instantiates the class.

### Arguments

Takes a hash or hashref with the following keys:

- `class` (Required)

    The fully-qualified class name to instantiate (e.g., `'LWP::UserAgent'`).

- Additional keys

    Any additional keys are passed through to `configure` and then to the class constructor.

### Returns

A blessed object of the specified class, configured according to the parameters and
configuration files.

### Side Effects

- Calls `configure` (see its side effects)
- Calls the `new` method on the specified class
- Registers the object for hot reload if a configuration file was used

### Notes

The specified class must have a `new` method that accepts a hashref of parameters.
This is a "quick and dirty" way to add configuration support to classes you don't control.

### Usage Example

    use Object::Configure;

    # Configure LWP::UserAgent from a config file
    my $ua = Object::Configure::instantiate(
        class => 'LWP::UserAgent',
        config_file => 'lwp.yml',
        config_dirs => ['/etc/myapp'],
        timeout => 30
    );

### API Specification

#### Input

    schema => {
        class => {
            type => 'string',
            required => 1,
            description => 'Class name to instantiate',
            can => 'new'
        }
    }

#### Output

    type => 'object',
    description => 'Instance of the specified class'

### Formal Specification

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

# HOT RELOAD FEATURES

## enable\_hot\_reload

Enable automatic hot reloading of configuration files when they are modified.

### Purpose

Starts a background process that monitors configuration files for changes and automatically
reloads them into registered objects. This allows runtime configuration updates without
restarting the application.

### Arguments

Takes a hash with the following optional keys:

- `interval` (Optional, default: 10)

    Number of seconds between configuration file checks. Lower values provide faster
    response to changes but consume more CPU.

- `callback` (Optional)

    A coderef to execute after configuration files are reloaded. Useful for logging
    or triggering application-specific reload behavior.

### Returns

The process ID (PID) of the background watcher process on success.
Returns immediately if hot reload is already enabled.

### Side Effects

- Forks a background process to monitor configuration files
- The background process sends SIGUSR1 to the parent when changes are detected
- Stores the watcher PID in `%_config_watchers`
- May throw an exception (via `croak`) if the fork fails

### Notes

Hot reload is not supported on Windows due to lack of SIGUSR1 signal support.
The background process runs indefinitely until `disable_hot_reload` is called.
Objects must be registered via `register_object` to receive configuration updates.

### Usage Example

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

### API Specification

#### Input

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

#### Output

    type => 'integer',
    description => 'PID of background watcher process',
    condition => 'value > 0'

### Formal Specification

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

## disable\_hot\_reload

Disable hot reloading and terminate the background watcher process.

### Purpose

Cleanly shuts down the hot reload system by terminating the background watcher
process and clearing internal state.

### Arguments

None.

### Returns

Nothing.

### Side Effects

- Sends SIGTERM to the background watcher process
- Waits for the watcher process to terminate
- Clears `%_config_watchers` state

### Notes

Safe to call even if hot reload is not currently enabled.
The function blocks until the watcher process has fully terminated.

### Usage Example

    use Object::Configure;

    # Enable hot reload
    Object::Configure::enable_hot_reload(interval => 5);

    # ... application runs ...

    # Clean shutdown
    Object::Configure::disable_hot_reload();

### API Specification

#### Input

    schema => {}

#### Output

    type => 'void'

### Formal Specification

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

## reload\_config

Manually trigger configuration reload for all registered objects.

### Purpose

Forces an immediate reload of configuration from files for all objects that have been
registered for hot reload. This is useful for testing or forcing a reload without
waiting for the automatic file monitoring to detect changes.

### Arguments

None.

### Returns

An integer count of how many objects had their configuration successfully reloaded.

### Side Effects

- Reads configuration files from disk
- Updates object properties with new configuration values
- Calls `_on_config_reload` hook on objects that implement it
- Cleans up dead weak references from `%_object_registry`
- May emit warnings if configuration reload fails for any object

### Notes

Only objects registered via `register_object` are reloaded.
Objects are updated in-place; their identity does not change.
Private properties (those starting with `_`) are not updated during reload.

### Usage Example

    use Object::Configure;

    # Create and register objects
    my $obj = My::Module->new(config_file => 'app.yml');

    # Manually edit app.yml...

    # Force immediate reload
    my $count = Object::Configure::reload_config();
    print "Reloaded configuration for $count objects\n";

### API Specification

#### Input

    schema => {}

#### Output

    type => 'integer',
    description => 'Number of objects successfully reloaded',
    condition => 'value >= 0'

### Formal Specification

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

## register\_object($class, $obj)

Register an object for hot reload monitoring.

### Purpose

Adds an object to the hot reload registry so it will receive automatic configuration
updates when files change. Uses weak references to prevent memory leaks.

### Arguments

- `class` (Required)

    The class name of the object, used for organizing the registry.

- `obj` (Required)

    The object instance to register. Must be a blessed reference.

### Returns

Nothing.

### Side Effects

- Adds a weak reference to the object in `%_object_registry`
- Sets up SIGUSR1 signal handler on first call (Unix-like systems only)
- Stores the original SIGUSR1 handler for later restoration

### Notes

Objects are stored using weak references, so they will be automatically
garbage collected when no other references exist.
The SIGUSR1 handler chains to any existing handler that was installed.
On Windows, the signal handler is not installed (SIGUSR1 does not exist).

### Usage Example

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

### API Specification

#### Input

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

#### Output

    type => 'void'

### Formal Specification

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

## restore\_signal\_handlers

Restore original signal handlers and disable hot reload integration.

### Purpose

Restores the signal handler that was in place before Object::Configure installed
its SIGUSR1 handler. This is useful for clean shutdown or when transferring
control to another hot reload system.

### Arguments

None.

### Returns

Nothing.

### Side Effects

- Restores `$SIG{USR1}` to its original value
- Clears `$_original_usr1_handler` internal state

### Notes

Safe to call even if Object::Configure never installed a signal handler.
On Windows, this function has no effect (SIGUSR1 does not exist).

### Usage Example

    use Object::Configure;

    # Objects are registered...

    # Clean shutdown
    Object::Configure::disable_hot_reload();
    Object::Configure::restore_signal_handlers();

### API Specification

#### Input

    schema => {}

#### Output

    type => 'void'

### Formal Specification

    restore_signal_handlers: () → ()

    State:
    - _original_usr1_handler: SignalHandler ∪ {∅}
    - $SIG{USR1}: SignalHandler

    Pre-condition:
    true

    Post-condition:
    $SIG{USR1}@post = _original_usr1_handler@pre ∧
    _original_usr1_handler@post = ∅

## get\_signal\_handler\_info

Get information about the current signal handler setup for debugging.

### Purpose

Returns diagnostic information about the signal handler state, useful for
debugging signal handler chains or verifying hot reload configuration.

### Arguments

None.

### Returns

A hashref containing the following keys:

- `original_usr1`

    The signal handler that was installed before Object::Configure's handler,
    or undef if no handler was present.

- `current_usr1`

    The currently installed SIGUSR1 handler.

- `hot_reload_active`

    Boolean indicating whether Object::Configure's hot reload handler is active.

- `watcher_pid`

    The PID of the background watcher process, or undef if not running.

### Side Effects

None.

### Notes

This is primarily a debugging aid and is not needed for normal operation.

### Usage Example

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

### API Specification

#### Input

    schema => {}

#### Output

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

### Formal Specification

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

# SEE ALSO

- [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction)
- [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction)
- [Test Dashboard](https://nigelhorne.github.io/Object-Configure/coverage/)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-object-configure at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Configure](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Configure).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Object::Configure

# LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to GPL2 licence terms.
If you use it,
please let me know.
