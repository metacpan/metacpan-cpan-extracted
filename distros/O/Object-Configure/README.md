# NAME

Object::Configure - Runtime Configuration for an Object

# VERSION

0.24

# DESCRIPTION

`Object::Configure` injects runtime configuration and logging into Perl class
constructors.  It is a thin layer on top of [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction) (reads config
files and environment variables) and [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) (logging).

Call `configure($class, \%params)` at the start of your `new()` method.  It:

- 1. Walks `@ISA` and finds config files for every class in the inheritance chain.
- 2. Merges those files, then overlays environment variables named `ClassName__key`.
- 3. Creates a [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) logger and stores it in `$params->{logger}`.
- 4. Returns a hashref ready to pass to `bless`.

The module also provides optional hot-reload support: a background process watches
config files and sends `SIGUSR1` to trigger an in-place update of registered objects
without restarting the application.

**Hot reload is not supported on Windows** (`SIGUSR1` does not exist there).

# SYNOPSIS

## Example 1: Add configurable logging to your own class

    package My::Module;
    use Object::Configure;

    sub new {
        my ($class, %args) = @_;

        # configure() reads config files + env vars, sets up a logger,
        # and returns a hashref ready to bless.
        my $params = Object::Configure::configure($class, \%args);

        return bless $params, $class;
    }

    sub do_work {
        my $self = shift;
        $self->{logger}->info('Starting do_work');
        # ...
    }

    # Usage -- reads ~/.conf/my-module.yml if it exists:
    my $obj = My::Module->new(config_file => '/etc/myapp/my-module.yml');
    $obj->do_work;

## Example 2: Configure a third-party class you cannot modify

    use Object::Configure;

    # Wrap LWP::UserAgent so it reads its settings from a YAML file.
    my $ua = Object::Configure::instantiate(
        class       => 'LWP::UserAgent',
        config_file => '/etc/myapp/lwp.yml',
        timeout     => 30,      # fallback if the file has no timeout key
    );

    $ua->get('https://example.com');

## Example 3: Multi-level inheritance -- config files merge automatically

    # ~/.conf/my-base-class.yml
    # My__Base__Class:
    #   timeout: 30
    #   retries: 3

    # ~/.conf/my-child-class.yml
    # My__Child__Class:
    #   timeout: 60   # overrides base; retries:3 is inherited

    package My::Child::Class;
    our @ISA = ('My::Base::Class');
    use Object::Configure;

    sub new {
        my ($class, %args) = @_;
        # Walks @ISA, merges base config then child config.
        # Result: timeout=60, retries=3
        my $params = Object::Configure::configure($class, \%args);
        return bless $params, $class;
    }

## Example 4: Hot reload -- objects update when the config file changes

    package My::Service;
    use Object::Configure;

    sub new {
        my ($class, %args) = @_;
        my $params = Object::Configure::configure($class, \%args);
        my $self   = bless $params, $class;

        # Register so reload_config() updates $self in-place on file change.
        Object::Configure::register_object($class, $self)
            if $params->{_config_file};

        return $self;
    }

    package main;

    my $svc = My::Service->new(config_file => '/etc/myapp/service.yml');

    # Fork a background watcher; it sends SIGUSR1 when the file changes.
    Object::Configure::enable_hot_reload(
        interval => 5,
        callback => sub { print "Config reloaded at ", scalar localtime, "\n" },
    );

    while (1) { sleep 1 }          # event loop

    Object::Configure::disable_hot_reload();    # clean shutdown

## Example 5: Override settings with environment variables (no file needed)

    # Shell:
    #   export My__Module__log_level=debug
    #   export My__Module__timeout=120

    package My::Module;
    use Object::Configure;

    sub new {
        my ($class, %args) = @_;
        # configure() picks up My__Module__* env vars automatically.
        my $params = Object::Configure::configure($class, \%args);
        return bless $params, $class;
    }

    my $obj = My::Module->new;
    # $obj->{log_level} eq 'debug'   $obj->{timeout} == 120

# CONFIGURATION

## Config file naming

The config file name is derived from the class name by lowercasing it and replacing
`::` with hyphens (`-`):

    My::Parent::Class  =>  my-parent-class.yml

The file is searched for in the directory of the `config_file` argument, then in
any directories listed in `config_dirs`.

## Section key naming inside the config file

Inside the YAML (or JSON or conf) file, the section key uses double underscores in
place of `::`:

    # my-parent-class.yml
    ---
    My__Parent__Class:
      timeout: 30
      retries: 3

## Configuration resolution order

The following sources are merged from _lowest_ to _highest_ priority.  A value
from a higher-priority source always wins over a lower-priority one.

- 1. **Caller-supplied params** -- the hashref you pass to `configure()`.  Despite
the name "defaults", these are the _lowest_ priority and are overridden by everything
else.
- 2. **UNIVERSAL section** -- the `UNIVERSAL:` block in `universal.yml` (or
`universal.conf`, `universal.json`) in your config directories, if the file exists.
- 3. **Ancestor class config files** -- walked base-first through `@ISA` using
the class's Method Resolution Order (MRO).
- 4. **Primary config file** -- the file named by the `config_file` argument.
- 5. **Environment variables** -- named `ClassName__key=value`, where `::` in
the class name is replaced by `__`.  These are the _highest_ priority.

## UNIVERSAL configuration

If you create `universal.yml` in your config directory with a `UNIVERSAL:` section,
those settings apply to every class that uses `Object::Configure` unless a
more-specific source overrides them:

    # ~/.conf/universal.yml
    ---
    UNIVERSAL:
      timeout: 30
      logger:
        level: warning

## Logging

`configure()` always sets `$params->{logger}` to a [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction)
instance.  You can control it by passing a `logger` key:

    # Arrayref: messages are captured into @log (protected from merge override)
    configure($class, { logger => \@log });

    # Hashref: options forwarded to Log::Abstraction::new()
    configure($class, { logger => { level => 'debug', file => '/var/log/app.log' } });

    # String 'NULL': disables all logging
    configure($class, { logger => 'NULL' });

    # Existing Log::Abstraction object: used as-is
    configure($class, { logger => $my_logger });

**Note:** only arrayref loggers are stashed before the config merge and are guaranteed
to survive it.  `'NULL'` and blessed logger objects can be overridden by a
`UNIVERSAL:` section in `universal.yml`.  See ["COMMON PITFALLS"](#common-pitfalls).

## Environment variable format

Environment variable names are constructed as:

    ClassName__key

where `::` in the class name is replaced by two underscores.

    export My__Module__timeout=60
    export My__Module__logger__level=debug

# HOT RELOAD

Hot reload lets you edit a config file and have all live objects update themselves
without restarting the program.

## How it works

- 1. Your constructor calls `register_object($class, $self)` to opt in.
- 2. Your main program calls `enable_hot_reload()` to fork a background watcher.
- 3. The watcher polls config files every `interval` seconds and sends
`SIGUSR1` to the parent when it detects a change.
- 4. The `SIGUSR1` handler calls `reload_config()`, which re-reads files and
updates every registered object in-place.
- 5. Your main program calls `disable_hot_reload()` on shutdown.

Private keys (those whose names start with `_`) are never overwritten during
reload, so internal bookkeeping is safe.

**Hot reload is not supported on Windows.**

# COMMON PITFALLS

## Only arrayref loggers survive the config merge

If you pass `logger => 'NULL'` or `logger => $existing_logger`, the
`UNIVERSAL:` section in `universal.yml` (or a site-local config file) can
silently override your logger during the config merge.

Only arrayref loggers are stashed before the merge and are guaranteed to survive:

    # Protected -- will NOT be overridden by universal.yml
    configure($class, { logger => \@captured });

    # NOT protected -- universal.yml can override these
    configure($class, { logger => 'NULL' });
    configure($class, { logger => $existing_obj });

## Caller-supplied keys are the LOWEST priority

Despite being called "defaults", keys you pass directly to `configure()` are
overridden by config files and environment variables:

    # My__Module__timeout=60 is set in the shell.
    # $params->{timeout} will be 60, not 30.
    configure('My::Module', { timeout => 30 });

Use caller-supplied keys only as a last-resort fallback.

## register\_object() pushes; it does not replace

Calling `register_object()` twice for the same class registers **two** entries.
Both objects receive updates on every reload.  The second call does not remove the
first.

    Object::Configure::register_object('My::Class', $obj_a);
    Object::Configure::register_object('My::Class', $obj_b);
    # reload_config() now updates BOTH $obj_a and $obj_b

## Private keys are never updated on hot reload

Any key whose name begins with `_` is skipped during `reload_config()`.
A config key named `_my_setting` in your YAML file will be ignored at reload time.

## The 'class' key appears on objects created by instantiate()

`instantiate()` intentionally leaves the `class` key in the hashref passed to
`$class->new()` as a debugging aid.  Your object will have a `class`
attribute set to the class name:

    my $obj = Object::Configure::instantiate(class => 'My::Thing', ...);
    print $obj->{class};    # prints 'My::Thing'

## Memoization caches are not invalidated during a run

`_get_inheritance_chain()` and `_find_class_config_file()` cache their results
for the lifetime of the process.  If you alter `@ISA` or add config files after
the first `configure()` call for a given class, the cache returns stale results.

## disable\_hot\_reload() blocks for up to five seconds

It waits for the watcher process to exit (SIGTERM first, then SIGKILL).  Do not
call it from inside a signal handler or a timing-sensitive loop.

## config\_file must be developer-controlled

The `config_file` path is validated against directory traversal (`../`) but is
not otherwise restricted.  It must always be a developer-supplied path, never raw
user input.

# SUBROUTINES/METHODS

## configure($class, \\%params)

Merge configuration for `$class` from all available sources and return a hashref
ready to pass to `bless`.  This is the core function; call it at the start of your
`new()` method.

### Arguments

- `$class` (Required, string)

    The fully-qualified Perl class name to configure (e.g., `'My::Module'`).  Must
    start with a letter or underscore; each `::`-separated component must also start
    with a letter or underscore.  Digits, newlines, and shell metacharacters are rejected.

- `\%params` (Optional, hashref; defaults to `{}`)

    Caller-supplied values.  These have the _lowest_ priority and are overridden by
    config files and environment variables.  Recognized special keys:

    - `config_file` (string, optional) -- path to the primary YAML/JSON/conf file.
    - `config_dirs` (arrayref of strings, optional) -- additional directories to
    search when `config_file` is a bare filename with no directory component.
    - `logger` (various, optional) -- see ["Logging"](#logging).
    - `carp_on_warn` (boolean, optional, default 0) -- if true, the logger uses
    `Carp::carp` instead of `warn`.
    - `croak_on_error` (boolean, optional, default 1) -- if true, the logger uses
    `Carp::croak` instead of `die`.

### Returns

A hashref containing all merged configuration keys plus:

- `logger` -- a [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) instance, or the string `'NULL'`.
- `_config_file` -- path of the primary config file (only if one was loaded).
- `_config_files` -- arrayref of every config file that was loaded (only if
at least one was loaded).

### Error messages

- `Object::Configure: configure: what class do you want to configure?` --
`$class` was `undef` or an empty string.  Pass `ref($self)` or `__PACKAGE__`.
- `Object::Configure: configure: invalid class name (must be a valid Perl package name): CLASS` --
`$class` contains characters not allowed in a Perl package name (for example, a
digit as the first character of a `::`-component, a newline, or a semicolon).
- `CLASS: config_file contains path traversal sequences: FILE` --
`config_file` contains a `..` segment (e.g., `../../etc/passwd`).  The
`config_file` argument must always be a developer-controlled path.
- `CLASS: FILE: OS-ERROR` --
`config_file` is not readable and no `config_dirs` were supplied.  Check file
permissions or add `config_dirs`.
- `Warning: Can't load configuration from FILE: DETAIL` --
[Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction) rejected the file (typically a YAML/JSON syntax error).
This is a warning, not fatal; `configure()` continues with an empty config.
- `Object::Configure: config_path contains path traversal sequences: PATH` --
An environment variable set a `config_path` value containing `..`.

### API Specification

#### Input

    schema => {
        class => {
            type        => 'string',
            required    => 1,
            description => 'Fully-qualified Perl class name',
            pattern     => qr/\A[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*\z/,
        },
        params => {
            type        => 'hashref',
            optional    => 1,
            default     => {},
            description => 'Caller-supplied defaults (lowest priority)',
            schema => {
                config_file => {
                    type        => 'string',
                    optional    => 1,
                    description => 'Primary config file path',
                },
                config_dirs => {
                    type        => 'arrayref',
                    optional    => 1,
                    description => 'Extra directories to search for config files',
                },
                logger => {
                    type        => [qw(undef string arrayref hashref object)],
                    optional    => 1,
                    description => 'Logger spec -- see CONFIGURATION/Logging',
                },
                carp_on_warn => {
                    type        => 'boolean',
                    optional    => 1,
                    default     => 0,
                    description => 'Use Carp::carp for logger warnings',
                },
                croak_on_error => {
                    type        => 'boolean',
                    optional    => 1,
                    default     => 1,
                    description => 'Use Carp::croak for logger errors',
                },
            },
        },
    }

#### Output

    type        => 'hashref',
    description => 'Merged configuration hashref, ready to bless',
    schema => {
        logger => {
            type        => [qw(object string)],
            description => 'Log::Abstraction instance or the string "NULL"',
        },
        _config_file => {
            type        => 'string',
            optional    => 1,
            description => 'Path of the primary config file that was loaded',
        },
        _config_files => {
            type        => 'arrayref',
            optional    => 1,
            description => 'All config file paths that were loaded, in load order',
        },
    }

## instantiate(%params)

Configure and instantiate a third-party class without modifying the class itself.

`instantiate` is a convenience wrapper: it calls `configure`, passes the merged
hashref to `$class->new(...)`, and optionally registers the result for hot reload.
Use it when you need runtime configuration for a class whose source you cannot change.

### Arguments

Takes a flat hash (not a hashref).  Recognized keys:

- `class` (Required, string)

    The fully-qualified class name to instantiate (e.g., `'LWP::UserAgent'`).  The class
    must already be loaded and must have a `new` method that accepts a hashref.

- All other keys

    Passed through to `configure()` as `\%params`.  See ["configure($class, \\%params)"](#configure-class-params)
    for the full list.

### Returns

A blessed object of type `$class`.

**Note:** The returned object's hash will contain a `class` key holding the class name.
This is intentional -- it is left in the hash as a debugging aid so you can always
see which class an object came from.  Do not depend on its absence.

### Side Effects

- Calls `configure($class, \%params)` -- see its side effects.
- Calls `$class->new(\%merged_params)`.
- If the config produced a `_config_file`, calls `register_object($class, $obj)`
so the object participates in hot reload.

### Error messages

Same as `configure()`.  In addition:

- Any exception thrown by `$class->new(...)` propagates unchanged.

### Usage Example

    use Object::Configure;

    my $ua = Object::Configure::instantiate(
        class       => 'LWP::UserAgent',
        config_file => 'lwp.yml',
        config_dirs => ['/etc/myapp'],
        timeout     => 30,
    );

### API Specification

#### Input

    schema => {
        class => {
            type        => 'string',
            required    => 1,
            description => 'Fully-qualified class name; must respond to new(hashref)',
        },
        # all other keys forwarded to configure()
    }

#### Output

    type        => 'object',
    description => 'Blessed instance of $class, with class key present in hash',
    notes       => 'class key intentionally left in hash as a debugging aid',

# HOT RELOAD FEATURES

## enable\_hot\_reload(%opts)

Fork a background watcher that sends SIGUSR1 to the parent whenever a tracked
configuration file changes on disk.  Objects registered via `register_object()`
then have their configuration reloaded automatically.

**Unix only.**  On Windows this function is a silent no-op (SIGUSR1 does not exist).

### Arguments

Takes a flat hash.  All keys are optional.

- `interval` (integer >= 1, default: 10)

    Seconds between file-modification checks.  Lower values detect changes faster
    but use more CPU.  Zero or negative values are silently replaced with the default.

- `callback` (coderef, optional)

    Called in the parent process after each successful config reload.  Useful for
    logging or flushing caches.

### Returns

The PID of the watcher child process (integer > 0), or `undef`/empty if hot
reload was already active (idempotent: a second call returns immediately without
forking again).

### Side Effects

- Forks a child process.
- The child polls `%_config_file_stats` and sends `SIGUSR1` to the parent
on mtime change.
- Stores `{pid => $pid, callback => $cb}` in `%_config_watchers`.

### Error messages

- `Object::Configure: fork failed: OS-ERROR` -- `fork()` returned `undef`.
Check system resource limits (`ulimit -u`).

### Usage Example

    Object::Configure::enable_hot_reload(
        interval => 5,
        callback => sub { warn "Config reloaded at " . localtime . "\n" },
    );

    while (1) { sleep 1 }  # watcher runs in the background

### API Specification

#### Input

    schema => {
        interval => {
            type        => 'integer',
            optional    => 1,
            default     => 10,
            minimum     => 1,
            description => 'Poll interval in seconds',
        },
        callback => {
            type        => 'coderef',
            optional    => 1,
            description => 'Called in parent after each reload',
        },
    }

#### Output

    type        => [qw(integer undef)],
    description => 'PID of watcher child; undef/empty if already active',
    condition   => 'value > 0 when defined',

    enable_hot_reload : Interval x Callback -> PID | empty

    Pre:
      interval >= 1   (enforced: negative/zero replaced with DEFAULT_INTERVAL)
      _config_watchers = {}

    Post:
      _config_watchers.pid = result
      _config_watchers.callback = callback
      (forall t: t mod interval = 0 =>
          (exists f in _config_file_stats: mtime(f) changed =>
              send_signal(SIGUSR1, parent_pid)))

## disable\_hot\_reload()

Stop the background watcher and clear hot-reload state.

Safe to call when hot reload is not active (no-op).  After this call,
configuration files are no longer monitored and `%_config_watchers` is empty.

### Arguments

None.

### Returns

Nothing (void).

### Side Effects

- Sends SIGTERM to the watcher child.
- Polls for up to `$KILL_TIMEOUT` seconds (default: 5); escalates to SIGKILL
if the child has not exited by then.
- Calls `waitpid` to reap the child.
- Clears `%_config_watchers`.

**Blocking**: this function may take up to five seconds if the watcher ignores SIGTERM.

### API Specification

#### Input

    schema => {}   # no arguments

#### Output

    type => 'void'

## reload\_config()

Immediately reload configuration from disk for every registered object.

Normally called automatically by the SIGUSR1 handler.  You may call it manually
to force a reload (e.g., in tests or on a custom signal).

### Arguments

None.

### Returns

An integer >= 0: the count of objects whose configuration was successfully
reloaded.

### Side Effects

- Reads config files from disk for each registered object.
- Updates non-private keys (those not starting with `_`) in-place on
each live object.
- Prunes dead weak references from `%_object_registry`.
- Emits a `carp` warning (not a croak) if reload fails for any individual
object; other objects are still processed.

### API Specification

#### Input

    schema => {}   # no arguments

#### Output

    type        => 'integer',
    description => 'Count of objects successfully reloaded',
    condition   => 'value >= 0',

## register\_object($class, $obj)

Register a blessed object so it receives configuration updates when files change.

**Push semantics**: each call _appends_ a new entry to the registry for `$class`.
It does not replace a previous entry.  Multiple objects of the same class are all
tracked and all reloaded.

### Arguments

- `$class` (Required, string)

    The class name used to organise the registry.  Typically `ref($self)` or the
    calling package name.

- `$obj` (Required, blessed reference)

    The object to register.  **Must be a blessed reference.**  Passing an unblessed
    hashref or any other unblessed value causes an immediate `croak`.

### Returns

Nothing (void).

### Side Effects

- Pushes a weak reference to `$obj` onto `$_object_registry{$class}`.
- On the first call ever (for any class): saves the current `$SIG{USR1}`
and installs Object::Configure's handler.  On Unix, the handler calls
`reload_config()` then chains to the prior handler.  On Windows, signal
installation is skipped but `$_original_usr1_handler` is still set.

### Error messages

- `Object::Configure::register_object: Usage ($class, $obj)` --
either `$class` or `$obj` was `undef`.
- `Object::Configure::register_object: $obj must be a blessed reference` --
`$obj` was defined but not blessed.  This guard prevents DoS via registry flooding
(reloading thousands of unblessed entries on every SIGUSR1).

### Usage Example

    package My::Module;
    use Object::Configure;

    sub new {
        my ($class, %args) = @_;
        my $params = Object::Configure::configure($class, \%args);
        my $self   = bless $params, $class;
        Object::Configure::register_object($class, $self)
            if $self->{_config_file};
        return $self;
    }

### API Specification

#### Input

    schema => {
        class => {
            type        => 'string',
            required    => 1,
            description => 'Class name for registry key',
        },
        obj => {
            type        => 'object',
            required    => 1,
            description => 'Blessed object to register; unblessed refs are rejected',
            blessed     => 1,
        },
    }

#### Output

    type => 'void'

## restore\_signal\_handlers()

Restore `$SIG{USR1}` to the handler that was in place before
`register_object()` installed the hot-reload handler, and clear
`$_original_usr1_handler`.

Safe to call even when Object::Configure never installed a handler (no-op).
On Windows this function has no effect (SIGUSR1 does not exist there).

### Arguments

None.

### Returns

Nothing (void).

### Side Effects

- Sets `$SIG{USR1}` back to its saved value (Unix only).
- Sets `$_original_usr1_handler` to `undef`.

### API Specification

#### Input

    schema => {}   # no arguments

#### Output

    type => 'void'

## get\_signal\_handler\_info()

Return a snapshot of the current signal-handler and hot-reload state.
This is a debugging aid; normal application code does not need to call it.

### Arguments

None.

### Returns

A hashref with these keys:

- `original_usr1` -- the `$SIG{USR1}` value that existed before
Object::Configure installed its handler, or `undef` if no handler was saved yet.
- `current_usr1` -- the currently installed `$SIG{USR1}` handler (coderef,
`'DEFAULT'`, `'IGNORE'`, or `undef`).
- `hot_reload_active` -- `1` if `$_original_usr1_handler` is defined,
`''` otherwise.
- `watcher_pid` -- the PID of the background watcher child, or `undef`
if `enable_hot_reload()` has not been called (or the watcher has been stopped).

### Usage Example

    use Object::Configure;
    use Data::Dumper;

    Object::Configure::enable_hot_reload();
    print Dumper(Object::Configure::get_signal_handler_info());
    # {
    #   original_usr1    => 'DEFAULT',
    #   current_usr1     => sub { ... },
    #   hot_reload_active => 1,
    #   watcher_pid       => 12345,
    # }

### API Specification

#### Input

    schema => {}   # no arguments

#### Output

    type        => 'hashref',
    description => 'Snapshot of signal-handler and watcher state',
    schema => {
        original_usr1     => { type => [qw(coderef string undef)] },
        current_usr1      => { type => [qw(coderef string undef)] },
        hot_reload_active => { type => 'boolean'                  },
        watcher_pid       => { type => [qw(integer undef)]        },
    }

# SEE ALSO

- [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction)
- [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction)
- [Test Dashboard](https://nigelhorne.github.io/Object-Configure/coverage/)

# LIMITATIONS

- **Global singleton state.** `%_object_registry`, `%_config_watchers`, and
`%_config_file_stats` are package globals.  Two independent subsystems in the same
process share one hot-reload registry and one SIGUSR1 handler.  There is no
instance-level isolation.  A proper fix would wrap state in an object and allow
multiple independent `Object::Configure` instances, but that would break the
existing constructor-call API (`configure($class, \%params)`).
- **Hot reload is Unix-only.** SIGUSR1 does not exist on Windows.
All signal-related paths are guarded with `$^O ne 'MSWin32'`, so the module
loads on Windows but silently skips hot-reload registration.
- **configure() is a God function.** At ~120 lines it handles arg validation,
config-file discovery, MRO walking, multi-file merging, env-var merging, logger
creation, and hot-reload bookkeeping.  Future versions should decompose this into
smaller, independently testable units.
- **\_deep\_merge reimplements CPAN.** [Hash::Merge::Simple](https://metacpan.org/pod/Hash%3A%3AMerge%3A%3ASimple) or [Hash::Merge](https://metacpan.org/pod/Hash%3A%3AMerge)
provide tested, feature-complete deep merge.  The internal `_deep_merge` is 15
lines and correct for the current use, but does not handle arrayrefs (they are
replaced wholesale, not merged).  If array-merge semantics are ever needed, switch
to a CPAN module.
- **No encapsulation enforcement.** Private helpers (`_build_logger`,
`_get_inheritance_chain`, etc.) are accessible to any caller.  [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate)
(enforce mode) would make accidental external use a compile-time error.  It is not
added here to avoid a smoker dependency on a less-common module.
- **configure() signature is positional, instantiate() is named.**  The two
public constructors have inconsistent calling conventions.  Normalising them to named
args would require a deprecation cycle.
- **mro::get\_linear\_isa and UNIVERSAL.**  Perl's `mro::get_linear_isa` does
not include `UNIVERSAL` in its output unless `UNIVERSAL` appears explicitly in
`@ISA`.  This module appends `UNIVERSAL` manually so that `universal.yml` is
always discovered.  If a future Perl version changes this behaviour the guard
(`grep { $_ eq 'UNIVERSAL' }`) remains correct.

# Formal Specification

## configure

    configure: Class x Params -> ConfigHash

    Given:
    - C: set of all class names
    - P: set of all parameter hashes
    - F: set of all file paths
    - H: set of all configuration hashes

    State:
    - ConfigFiles: F -> H (maps file paths to configuration content)
    - EnvVars: String -> String (environment variables)
    - InheritanceChain: C -> seq C (ordered sequence of ancestor classes)

    Pre-condition:
    forall class in C, params in P:
        class != empty
        (params.config_file != empty =>
            (exists dir in params.config_dirs: readable(dir/params.config_file))
            OR readable(params.config_file))

    Post-condition:
    forall result in H:
        result = params
                 (+) (merge f in InheritanceConfigFiles(class): ConfigFiles(f))
                 (+) (merge v in RelevantEnvVars(class): v)
        result.logger in Log::Abstraction
        (forall k in dom params:
            (params(k) in CodeRef OR blessed(params(k))) => result(k) = params(k))

    where (+) denotes hash merge with right-precedence

## instantiate

    instantiate: Params -> Object

    Given:
    - P: set of all parameter hashes
    - C: set of all class names
    - O: set of all objects

    Pre-condition:
    forall params in P:
        params.class in C
        params.class.can('new')

    Post-condition:
    forall result in O:
        exists config in H:
            config = configure(params.class, params)
            result = params.class.new(config)
            blessed(result) = params.class
            (config._config_file != empty =>
                result in _object_registry(params.class))

## enable\_hot\_reload

    enable_hot_reload: Interval x Callback -> PID

    Given:
    - I: set of positive integers (intervals in seconds)
    - CB: set of code references
    - PID: set of process identifiers

    State:
    - _config_watchers: {pid: PID, callback: CB}
    - _config_file_stats: F -> Stat

    Pre-condition:
    forall interval in I, callback in CB union {empty}:
        interval >= 1
        _config_watchers = empty
        OS != 'MSWin32'

    Post-condition:
    forall result in PID:
        result > 0
        _config_watchers.pid = result
        _config_watchers.callback = callback
        (forall t in Time:
            (t mod interval = 0) =>
                (exists f in dom _config_file_stats:
                    mtime(f) > _config_file_stats(f).mtime =>
                        send_signal(SIGUSR1, parent_process)))

## disable\_hot\_reload

    disable_hot_reload: () -> ()

    State:
    - _config_watchers: {pid: PID, callback: CB}

    Pre-condition:
    true

    Post-condition:
    _config_watchers = empty
    (forall p in PID:
        p = _config_watchers.pid@pre =>
            NOT alive(p))

## reload\_config

    reload_config: () -> N

    State:
    - _object_registry: C -> seq ObjectRef
    - ConfigFiles: F -> H

    Pre-condition:
    true

    Post-condition:
    forall result in N:
        result = |{obj in flatten(ran _object_registry) |
                   obj != empty
                   obj._config_file in dom ConfigFiles}|
        (forall obj in flatten(ran _object_registry):
            obj != empty AND obj._config_file in dom ConfigFiles =>
                (forall k in dom ConfigFiles(obj._config_file):
                    k NOT in PrivateKeys =>
                        obj(k)@post = ConfigFiles(obj._config_file)(k)))

    where PrivateKeys = {k | k starts with '_'}

## register\_object

    register_object: C x O -> ()

    Given:
    - C: set of class names
    - O: set of blessed objects
    - OR: C -> seq WeakRef(O) (object registry)

    State:
    - _object_registry: OR
    - _original_usr1_handler: SignalHandler union {empty}
    - $SIG{USR1}: SignalHandler

    Pre-condition:
    forall class in C, obj in O:
        class != empty
        obj != empty
        blessed(obj) != empty

    Post-condition:
    forall class in C, obj in O:
        exists ref in _object_registry(class):
            weak(ref) = obj
        (_original_usr1_handler = empty@pre =>
            (_original_usr1_handler@post = $SIG{USR1}@pre
             $SIG{USR1}@post = reload_config_handler))

## restore\_signal\_handlers

    restore_signal_handlers: () -> ()

    State:
    - _original_usr1_handler: SignalHandler union {empty}
    - $SIG{USR1}: SignalHandler

    Pre-condition:
    true

    Post-condition:
    $SIG{USR1}@post = _original_usr1_handler@pre
    _original_usr1_handler@post = empty

## get\_signal\_handler\_info

    get_signal_handler_info: () -> InfoHash

    Given:
    - IH: set of all info hashes

    State:
    - _original_usr1_handler: SignalHandler union {empty}
    - $SIG{USR1}: SignalHandler union {empty}
    - _config_watchers: {pid: PID, callback: CB}

    Pre-condition:
    true

    Post-condition:
    forall result in IH:
        result.original_usr1 = _original_usr1_handler
        result.current_usr1 = $SIG{USR1}
        result.hot_reload_active = (_original_usr1_handler != empty)
        result.watcher_pid = _config_watchers.pid

# SUPPORT

Please report bugs and feature requests at:

- RT (CPAN bug tracker): [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Configure](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Configure)

    or by e-mail: `bug-object-configure at rt.cpan.org`

- GitHub issues: [https://github.com/nigelhorne/Object-Configure/issues](https://github.com/nigelhorne/Object-Configure/issues)

You will be notified automatically of progress on your report.

    perldoc Object::Configure

# LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to GPL2 licence terms.
If you use it, please let me know.
