package Object::Configure;

use strict;
use warnings;

use Carp;
use Config::Abstraction 0.38;
use File::Spec;
use Log::Abstraction 0.26;
use mro;
use Params::Get 0.13;
use Readonly;
use Return::Set;
use List::Util   qw(any);
use Scalar::Util qw(blessed weaken);
use Time::HiRes  qw(time);
use File::stat;
use POSIX qw(WNOHANG);

# Avoid magic literals scattered across hot paths and signal handlers.
# Centralising here makes global search-replace safe and self-documents intent.
Readonly my $OS_WINDOWS      => 'MSWin32';
Readonly my $LOGGER_NULL     => 'NULL';
Readonly my $SIG_DEFAULT     => 'DEFAULT';
Readonly my $SIG_IGNORE      => 'IGNORE';
Readonly my $POLL_SLEEP      => 0.1;   # seconds between waitpid polls in disable_hot_reload
Readonly my $KILL_TIMEOUT    => 5;     # seconds before SIGKILL escalation after SIGTERM
Readonly my $DEFAULT_INTERVAL => 10;   # default hot-reload poll interval in seconds

# Matches any path segment that is exactly ".." (anchored start, slash, or end).
# Catches: ../foo  foo/../bar  foo/..  and leading ../
# Used in two places; kept as a constant so both guards are always in sync.
Readonly my $RE_PATH_TRAVERSAL => qr{(?:\A|/)\.\.(?:/|\z)};

# Global registry — intentionally package-level so that the END block and
# signal handlers installed in one call site share state with all others.
# This is a deliberate singleton design; see LIMITATIONS for the trade-offs.
our %_object_registry   = ();
our %_config_watchers   = ();
our %_config_file_stats = ();

# Memoization caches — keyed by inputs; valid for the process lifetime because
# Perl @ISA hierarchies and filesystem layouts are stable after module load.
# Both caches include undef sentinels (use exists, not defined, to check hits).
our %_chain_cache = ();  # class         => [UNIVERSAL, ..., Class] (base-first)
our %_find_cache  = ();  # "\0"-joined key => file path or undef

# Saved before we install our SIGUSR1 handler so we can chain and restore it.
our $_original_usr1_handler;

=head1 NAME

Object::Configure - Runtime Configuration for an Object

=head1 VERSION

0.24

=cut

our $VERSION = 0.24;

=head1 DESCRIPTION

C<Object::Configure> injects runtime configuration and logging into Perl class
constructors.  It is a thin layer on top of L<Config::Abstraction> (reads config
files and environment variables) and L<Log::Abstraction> (logging).

Call C<configure($class, \%params)> at the start of your C<new()> method.  It:

=over 4

=item 1. Walks C<@ISA> and finds config files for every class in the inheritance chain.

=item 2. Merges those files, then overlays environment variables named C<ClassName__key>.

=item 3. Creates a L<Log::Abstraction> logger and stores it in C<$params-E<gt>{logger}>.

=item 4. Returns a hashref ready to pass to C<bless>.

=back

The module also provides optional hot-reload support: a background process watches
config files and sends C<SIGUSR1> to trigger an in-place update of registered objects
without restarting the application.

B<Hot reload is not supported on Windows> (C<SIGUSR1> does not exist there).

=head1 SYNOPSIS

=head2 Example 1: Add configurable logging to your own class

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

=head2 Example 2: Configure a third-party class you cannot modify

    use Object::Configure;

    # Wrap LWP::UserAgent so it reads its settings from a YAML file.
    my $ua = Object::Configure::instantiate(
        class       => 'LWP::UserAgent',
        config_file => '/etc/myapp/lwp.yml',
        timeout     => 30,      # fallback if the file has no timeout key
    );

    $ua->get('https://example.com');

=head2 Example 3: Multi-level inheritance -- config files merge automatically

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

=head2 Example 4: Hot reload -- objects update when the config file changes

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

=head2 Example 5: Override settings with environment variables (no file needed)

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

=head1 CONFIGURATION

=head2 Config file naming

The config file name is derived from the class name by lowercasing it and replacing
C<::> with hyphens (C<->):

    My::Parent::Class  =>  my-parent-class.yml

The file is searched for in the directory of the C<config_file> argument, then in
any directories listed in C<config_dirs>.

=head2 Section key naming inside the config file

Inside the YAML (or JSON or conf) file, the section key uses double underscores in
place of C<::>:

    # my-parent-class.yml
    ---
    My__Parent__Class:
      timeout: 30
      retries: 3

=head2 Configuration resolution order

The following sources are merged from I<lowest> to I<highest> priority.  A value
from a higher-priority source always wins over a lower-priority one.

=over 4

=item 1. B<Caller-supplied params> -- the hashref you pass to C<configure()>.  Despite
the name "defaults", these are the I<lowest> priority and are overridden by everything
else.

=item 2. B<UNIVERSAL section> -- the C<UNIVERSAL:> block in C<universal.yml> (or
C<universal.conf>, C<universal.json>) in your config directories, if the file exists.

=item 3. B<Ancestor class config files> -- walked base-first through C<@ISA> using
the class's Method Resolution Order (MRO).

=item 4. B<Primary config file> -- the file named by the C<config_file> argument.

=item 5. B<Environment variables> -- named C<ClassName__key=value>, where C<::> in
the class name is replaced by C<__>.  These are the I<highest> priority.

=back

=head2 UNIVERSAL configuration

If you create C<universal.yml> in your config directory with a C<UNIVERSAL:> section,
those settings apply to every class that uses C<Object::Configure> unless a
more-specific source overrides them:

    # ~/.conf/universal.yml
    ---
    UNIVERSAL:
      timeout: 30
      logger:
        level: warning

=head2 Logging

C<configure()> always sets C<$params-E<gt>{logger}> to a L<Log::Abstraction>
instance.  You can control it by passing a C<logger> key:

    # Arrayref: messages are captured into @log (protected from merge override)
    configure($class, { logger => \@log });

    # Hashref: options forwarded to Log::Abstraction::new()
    configure($class, { logger => { level => 'debug', file => '/var/log/app.log' } });

    # String 'NULL': disables all logging
    configure($class, { logger => 'NULL' });

    # Existing Log::Abstraction object: used as-is
    configure($class, { logger => $my_logger });

B<Note:> only arrayref loggers are stashed before the config merge and are guaranteed
to survive it.  C<'NULL'> and blessed logger objects can be overridden by a
C<UNIVERSAL:> section in C<universal.yml>.  See L</COMMON PITFALLS>.

=head2 Environment variable format

Environment variable names are constructed as:

    ClassName__key

where C<::> in the class name is replaced by two underscores.

    export My__Module__timeout=60
    export My__Module__logger__level=debug

=head1 HOT RELOAD

Hot reload lets you edit a config file and have all live objects update themselves
without restarting the program.

=head2 How it works

=over 4

=item 1. Your constructor calls C<register_object($class, $self)> to opt in.

=item 2. Your main program calls C<enable_hot_reload()> to fork a background watcher.

=item 3. The watcher polls config files every C<interval> seconds and sends
C<SIGUSR1> to the parent when it detects a change.

=item 4. The C<SIGUSR1> handler calls C<reload_config()>, which re-reads files and
updates every registered object in-place.

=item 5. Your main program calls C<disable_hot_reload()> on shutdown.

=back

Private keys (those whose names start with C<_>) are never overwritten during
reload, so internal bookkeeping is safe.

B<Hot reload is not supported on Windows.>

=head1 COMMON PITFALLS

=head2 Only arrayref loggers survive the config merge

If you pass C<logger =E<gt> 'NULL'> or C<logger =E<gt> $existing_logger>, the
C<UNIVERSAL:> section in C<universal.yml> (or a site-local config file) can
silently override your logger during the config merge.

Only arrayref loggers are stashed before the merge and are guaranteed to survive:

    # Protected -- will NOT be overridden by universal.yml
    configure($class, { logger => \@captured });

    # NOT protected -- universal.yml can override these
    configure($class, { logger => 'NULL' });
    configure($class, { logger => $existing_obj });

=head2 Caller-supplied keys are the LOWEST priority

Despite being called "defaults", keys you pass directly to C<configure()> are
overridden by config files and environment variables:

    # My__Module__timeout=60 is set in the shell.
    # $params->{timeout} will be 60, not 30.
    configure('My::Module', { timeout => 30 });

Use caller-supplied keys only as a last-resort fallback.

=head2 register_object() pushes; it does not replace

Calling C<register_object()> twice for the same class registers B<two> entries.
Both objects receive updates on every reload.  The second call does not remove the
first.

    Object::Configure::register_object('My::Class', $obj_a);
    Object::Configure::register_object('My::Class', $obj_b);
    # reload_config() now updates BOTH $obj_a and $obj_b

=head2 Private keys are never updated on hot reload

Any key whose name begins with C<_> is skipped during C<reload_config()>.
A config key named C<_my_setting> in your YAML file will be ignored at reload time.

=head2 The 'class' key appears on objects created by instantiate()

C<instantiate()> intentionally leaves the C<class> key in the hashref passed to
C<$class-E<gt>new()> as a debugging aid.  Your object will have a C<class>
attribute set to the class name:

    my $obj = Object::Configure::instantiate(class => 'My::Thing', ...);
    print $obj->{class};    # prints 'My::Thing'

=head2 Memoization caches are not invalidated during a run

C<_get_inheritance_chain()> and C<_find_class_config_file()> cache their results
for the lifetime of the process.  If you alter C<@ISA> or add config files after
the first C<configure()> call for a given class, the cache returns stale results.

=head2 disable_hot_reload() blocks for up to five seconds

It waits for the watcher process to exit (SIGTERM first, then SIGKILL).  Do not
call it from inside a signal handler or a timing-sensitive loop.

=head2 config_file must be developer-controlled

The C<config_file> path is validated against directory traversal (C<../>) but is
not otherwise restricted.  It must always be a developer-supplied path, never raw
user input.

=head1 SUBROUTINES/METHODS

=head2 configure($class, \%params)

Merge configuration for C<$class> from all available sources and return a hashref
ready to pass to C<bless>.  This is the core function; call it at the start of your
C<new()> method.

=head3 Arguments

=over 4

=item * C<$class> (Required, string)

The fully-qualified Perl class name to configure (e.g., C<'My::Module'>).  Must
start with a letter or underscore; each C<::>-separated component must also start
with a letter or underscore.  Digits, newlines, and shell metacharacters are rejected.

=item * C<\%params> (Optional, hashref; defaults to C<{}>)

Caller-supplied values.  These have the I<lowest> priority and are overridden by
config files and environment variables.  Recognized special keys:

=over 4

=item * C<config_file> (string, optional) -- path to the primary YAML/JSON/conf file.

=item * C<config_dirs> (arrayref of strings, optional) -- additional directories to
search when C<config_file> is a bare filename with no directory component.

=item * C<logger> (various, optional) -- see L</Logging>.

=item * C<carp_on_warn> (boolean, optional, default 0) -- if true, the logger uses
C<Carp::carp> instead of C<warn>.

=item * C<croak_on_error> (boolean, optional, default 1) -- if true, the logger uses
C<Carp::croak> instead of C<die>.

=back

=back

=head3 Returns

A hashref containing all merged configuration keys plus:

=over 4

=item * C<logger> -- a L<Log::Abstraction> instance, or the string C<'NULL'>.

=item * C<_config_file> -- path of the primary config file (only if one was loaded).

=item * C<_config_files> -- arrayref of every config file that was loaded (only if
at least one was loaded).

=back

=head3 Error messages

=over 4

=item * C<Object::Configure: configure: what class do you want to configure?> --
C<$class> was C<undef> or an empty string.  Pass C<ref($self)> or C<__PACKAGE__>.

=item * C<Object::Configure: configure: invalid class name (must be a valid Perl package name): CLASS> --
C<$class> contains characters not allowed in a Perl package name (for example, a
digit as the first character of a C<::>-component, a newline, or a semicolon).

=item * C<CLASS: config_file contains path traversal sequences: FILE> --
C<config_file> contains a C<..> segment (e.g., C<../../etc/passwd>).  The
C<config_file> argument must always be a developer-controlled path.

=item * C<CLASS: FILE: OS-ERROR> --
C<config_file> is not readable and no C<config_dirs> were supplied.  Check file
permissions or add C<config_dirs>.

=item * C<Warning: Can't load configuration from FILE: DETAIL> --
L<Config::Abstraction> rejected the file (typically a YAML/JSON syntax error).
This is a warning, not fatal; C<configure()> continues with an empty config.

=item * C<Object::Configure: config_path contains path traversal sequences: PATH> --
An environment variable set a C<config_path> value containing C<..>.

=back

=head3 API Specification

=head4 Input

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

=head4 Output

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

=cut

sub configure {
	my $class  = $_[0];
	my $params = $_[1] // {};	# caller's defaults; config file values override them
	my $array_logger;		# stash for an arrayref logger spec (Config::Abstraction rejects refs)

	croak(__PACKAGE__, ': configure: what class do you want to configure?')
		if !defined($class) || $class eq '';

	# SECURITY: validate $class is a syntactically valid Perl package name before
	# it propagates into env_prefix, croak messages, and %_chain_cache keys.
	# Exploit mechanism: a class name containing \n, ;, or shell metacharacters
	# can poison log lines, carp output, and env-variable lookups if not rejected here.
	# Under Perl taint mode (-T) an unvalidated external value would also fail the
	# taint check inside Config::Abstraction when used as an env_prefix substring.
	croak(__PACKAGE__, ': configure: invalid class name (must be a valid Perl package name): ', $class)
		unless $class =~ /\A[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*\z/;

	# Config::Abstraction, Log::Abstraction, and Return::Set all use eval internally
	# Protect the caller's $@ from being clobbered by our internal eval blocks.
	local $@;

	# Config::Abstraction treats unknown scalar values as config file paths and will
	# attempt to read them, corrupting coderefs and object references.
	# Stash them here and restore after merging so callers never need this pattern.
	my %stashed_values;
	foreach my $key (keys %$params) {
		next if $key eq 'logger';	# logger has its own path through _build_logger
		my $value = $params->{$key};
		if(ref($value) eq 'CODE' || blessed($value)) {
			$stashed_values{$key} = delete $params->{$key};
		}
	}

	if(exists($params->{'logger'}) && ref($params->{'logger'}) eq 'ARRAY') {
		$array_logger = delete $params->{'logger'};
	}

	my $original_class = $class;
	$class =~ s/::/__/g;

	my $config_file = $params->{'config_file'};
	my $config_dirs = $params->{'config_dirs'};

	# SECURITY (S1 — path traversal): reject config_file paths containing ".." segments
	# before they reach Config::Abstraction.  The pen-test suite confirmed C::A parses
	# /etc/passwd as a colon-delimited conf file, injecting every user account as a
	# config key.  The ".." guard blocks the traversal vector; direct absolute paths to
	# system files remain the caller's responsibility (document: config_file must be
	# developer-controlled, never raw user input).
	if(defined($config_file) && $config_file =~ $RE_PATH_TRAVERSAL) {
		croak("$class: config_file contains path traversal sequences: $config_file");
	}

	# _get_inheritance_chain returns [UNIVERSAL, ..., Base, Child] (base-first).
	# Reversing it below gives child-first for the discovery loop; the sort
	# that follows re-establishes base-first order for actual loading.
	my @inheritance_chain = _get_inheritance_chain($original_class);

	my @config_files_to_load = ();
	my %tracked_files        = ();

	if($config_file) {
		# Fail early so the error message carries the OS errno string while $!
		# is still fresh from the -r test, giving a locale-correct message.
		if(!$config_dirs && !-r $config_file) {
			croak("$class: ", $config_file, ": $!");
		}

		foreach my $ancestor_class (reverse @inheritance_chain) {
			my $ancestor_config_file = _find_class_config_file(
				$ancestor_class,
				$config_file,
				$config_dirs
			);

			# Primary file is added separately at the end (highest priority)
			next if $ancestor_config_file && $ancestor_config_file eq $config_file;

			if($ancestor_config_file && -r $ancestor_config_file && !$tracked_files{$ancestor_config_file}) {
				push @config_files_to_load, { file => $ancestor_config_file, class => $ancestor_class };
				$tracked_files{$ancestor_config_file} = 1;
				$_config_file_stats{$ancestor_config_file} = stat($ancestor_config_file)
					if -f $ancestor_config_file;
			}
		}

		# Premise: $config_file is true (we are inside if($config_file) above).
		if(!$tracked_files{$config_file} && -r $config_file) {
			push @config_files_to_load, { file => $config_file, class => $original_class };
			$tracked_files{$config_file} = 1;
			$_config_file_stats{$config_file} = stat($config_file)
				if -f $config_file;
		}

		if(!scalar(@config_files_to_load)) {
			foreach my $dir (@{$config_dirs}) {
				my $candidate = File::Spec->catfile($dir, $config_file);
				if(-r $candidate) {
					push @config_files_to_load, { file => $candidate, class => $original_class };
					last;	# stop at first readable hit; later dirs are lower priority
				}
			}
		}
	}

	if(@config_files_to_load) {
		# Sort so that base-class files are loaded before child files.
		# %class_order is keyed on the chain (UNIVERSAL=0, ..., Child=N).
		my %class_order;
		for my $i (0 .. $#inheritance_chain) {
			$class_order{ $inheritance_chain[$i] } = $i;
		}
		@config_files_to_load = sort {
			($class_order{ $a->{class} } // 999) <=> ($class_order{ $b->{class} } // 999)
		} @config_files_to_load;

		my $merged_params = { %$params };

		foreach my $config_info (@config_files_to_load) {
			my $cfg_file    = $config_info->{file};
			my $cfg_class   = $config_info->{class};
			my $section_name = $cfg_class;
			$section_name =~ s/::/__/g;

			# Load only the specific file; do not re-pass config_dirs to avoid
			# re-scanning directories and picking up the wrong file for this class.
			my $config = Config::Abstraction->new(
				config_file => $cfg_file,
				env_prefix  => "${section_name}__"
			);

			if($config) {
				my $this_config = $config->merge_defaults(
					defaults => {},
					section  => $section_name,
					merge    => 1,
					deep     => 1
				);
				$merged_params = _deep_merge($merged_params, $this_config);
			} elsif($@) {
				carp("Warning: Can't load configuration from $cfg_file: $@");
			}
		}

		$params = $merged_params;
	} elsif(my $config = Config::Abstraction->new(env_prefix => "${class}__")) {
		# No config file: honour environment variables across the full ancestor chain.
		my $merged_config = {};

		# Iterate base-first so that each more-specific class overrides the more
		# general one: UNIVERSAL → GrandParent → Parent → Child.
		foreach my $ancestor_class (@inheritance_chain) {
			my $section_name = $ancestor_class;
			$section_name =~ s/::/__/g;

			my $ancestor_env_config = Config::Abstraction->new(env_prefix => "${section_name}__");
			if($ancestor_env_config) {
				my $ancestor_config = $ancestor_env_config->merge_defaults(
					defaults => {},
					section  => $section_name,
					merge    => 1,
					deep     => 1
				);
				$merged_config = _deep_merge($merged_config, $ancestor_config);
			}
		}

		$params = $config->merge_defaults(
			defaults => $params,
			section  => $class,
			merge    => 1,
			deep     => 1
		);

		$params = _deep_merge($merged_config, $params);

		# SECURITY (S1 extension — config_path traversal + taint):
		# config_path arrives from Config::Abstraction, which reads %ENV.  Under
		# taint mode (-T) the value is tainted; any syscall with a tainted argument
		# is fatal.  Apply the same $RE_PATH_TRAVERSAL guard as config_file (line 491)
		# before any filesystem probe, so the two guards stay in sync.
		# Exploit: ClassName__config_path=../../etc/shadow causes the hot-reload watcher
		# to stat() and track an arbitrary system file, leaking mtime changes via SIGUSR1.
		if($params->{config_path}) {
			croak(__PACKAGE__, ': config_path contains path traversal sequences: ',
				$params->{config_path})
				if $params->{config_path} =~ $RE_PATH_TRAVERSAL;
			$_config_file_stats{ $params->{config_path} } = stat($params->{config_path})
				if -f $params->{config_path};
		}
	}

	my $croak_on_error = exists($params->{'croak_on_error'}) ? $params->{'croak_on_error'} : 1;
	my $carp_on_warn   = exists($params->{'carp_on_warn'})   ? $params->{'carp_on_warn'}   : 0;

	# User-supplied logger always wins over config-file logger.
	# $array_logger is defined when the caller passed an arrayref; it was deleted from
	# $params before config merging so the merge couldn't overwrite it.  Config-file logger
	# (a hashref from YAML) is only used when the caller gave no explicit logger at all.
	my $logger_spec = defined($array_logger) ? $array_logger : $params->{'logger'};
	$params->{'logger'} = _build_logger($logger_spec, $carp_on_warn);

	if(!exists($params->{_config_file})) {
		$params->{_config_file} = $config_file if defined $config_file;
	}
	if(!exists($params->{_config_files})) {
		$params->{_config_files} = [ map { $_->{file} } @config_files_to_load ]
			if @config_files_to_load;
	}

	# Re-attach stashed coderefs/objects via hash slice
	@{$params}{ keys %stashed_values } = values %stashed_values if %stashed_values;

	return Return::Set::set_return($params, { 'type' => 'hashref' });
}

=head2 instantiate(%params)

Configure and instantiate a third-party class without modifying the class itself.

C<instantiate> is a convenience wrapper: it calls C<configure>, passes the merged
hashref to C<$class-E<gt>new(...)>, and optionally registers the result for hot reload.
Use it when you need runtime configuration for a class whose source you cannot change.

=head3 Arguments

Takes a flat hash (not a hashref).  Recognized keys:

=over 4

=item * C<class> (Required, string)

The fully-qualified class name to instantiate (e.g., C<'LWP::UserAgent'>).  The class
must already be loaded and must have a C<new> method that accepts a hashref.

=item * All other keys

Passed through to C<configure()> as C<\%params>.  See L</configure($class, \%params)>
for the full list.

=back

=head3 Returns

A blessed object of type C<$class>.

B<Note:> The returned object's hash will contain a C<class> key holding the class name.
This is intentional -- it is left in the hash as a debugging aid so you can always
see which class an object came from.  Do not depend on its absence.

=head3 Side Effects

=over 4

=item * Calls C<configure($class, \%params)> -- see its side effects.

=item * Calls C<$class-E<gt>new(\%merged_params)>.

=item * If the config produced a C<_config_file>, calls C<register_object($class, $obj)>
so the object participates in hot reload.

=back

=head3 Error messages

Same as C<configure()>.  In addition:

=over 4

=item * Any exception thrown by C<$class-E<gt>new(...)> propagates unchanged.

=back

=head3 Usage Example

    use Object::Configure;

    my $ua = Object::Configure::instantiate(
        class       => 'LWP::UserAgent',
        config_file => 'lwp.yml',
        config_dirs => ['/etc/myapp'],
        timeout     => 30,
    );

=head3 API Specification

=head4 Input

    schema => {
        class => {
            type        => 'string',
            required    => 1,
            description => 'Fully-qualified class name; must respond to new(hashref)',
        },
        # all other keys forwarded to configure()
    }

=head4 Output

    type        => 'object',
    description => 'Blessed instance of $class, with class key present in hash',
    notes       => 'class key intentionally left in hash as a debugging aid',

=cut

sub instantiate
{
	my $params = Params::Get::get_params('class', @_);

	# 'class' is read into $class then left in $params,
	# 'class' propagates into configure() as a spurious config key and
	# ends up in the blessed object's hash, allowing the caller to see
	# that has come from what, helping debugging
	my $class = $params->{'class'};
	$params = configure($class, $params);

	my $obj = $class->new($params);

	register_object($class, $obj) if $params->{_config_file};

	return $obj;
}

=head1 HOT RELOAD FEATURES

=head2 enable_hot_reload(%opts)

Fork a background watcher that sends SIGUSR1 to the parent whenever a tracked
configuration file changes on disk.  Objects registered via C<register_object()>
then have their configuration reloaded automatically.

B<Unix only.>  On Windows this function is a silent no-op (SIGUSR1 does not exist).

=head3 Arguments

Takes a flat hash.  All keys are optional.

=over 4

=item * C<interval> (integer E<gt>= 1, default: 10)

Seconds between file-modification checks.  Lower values detect changes faster
but use more CPU.  Zero or negative values are silently replaced with the default.

=item * C<callback> (coderef, optional)

Called in the parent process after each successful config reload.  Useful for
logging or flushing caches.

=back

=head3 Returns

The PID of the watcher child process (integer E<gt> 0), or C<undef>/empty if hot
reload was already active (idempotent: a second call returns immediately without
forking again).

=head3 Side Effects

=over 4

=item * Forks a child process.

=item * The child polls C<%_config_file_stats> and sends C<SIGUSR1> to the parent
on mtime change.

=item * Stores C<{pid =E<gt> $pid, callback =E<gt> $cb}> in C<%_config_watchers>.

=back

=head3 Error messages

=over 4

=item * C<Object::Configure: fork failed: OS-ERROR> -- C<fork()> returned C<undef>.
Check system resource limits (C<ulimit -u>).

=back

=head3 Usage Example

    Object::Configure::enable_hot_reload(
        interval => 5,
        callback => sub { warn "Config reloaded at " . localtime . "\n" },
    );

    while (1) { sleep 1 }  # watcher runs in the background

=head3 API Specification

=head4 Input

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

=head4 Output

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

=cut

sub enable_hot_reload {
	my %params = @_;

	# SECURITY (S4): use defined-or (//) not truth-or (||) so that interval=>0
	# is not silently replaced.  Then guard: a zero or negative interval would make
	# the child busy-loop, consuming 100% CPU (internal DoS vector).
	my $interval = $params{interval} // $DEFAULT_INTERVAL;
	$interval    = $DEFAULT_INTERVAL unless $interval > 0;
	my $callback = $params{callback};

	return if %_config_watchers;	# already watching; avoid double-fork

	if(my $pid = fork()) {
		$_config_watchers{pid}      = $pid;
		$_config_watchers{callback} = $callback;
		return $pid;
	} elsif(defined $pid) {
		# Child: run forever, signal parent on change
		_run_config_watcher($interval, $callback);
		exit 0;
	} else {
		croak("Failed to fork config watcher: $!");
	}
}

=head2 disable_hot_reload()

Stop the background watcher and clear hot-reload state.

Safe to call when hot reload is not active (no-op).  After this call,
configuration files are no longer monitored and C<%_config_watchers> is empty.

=head3 Arguments

None.

=head3 Returns

Nothing (void).

=head3 Side Effects

=over 4

=item * Sends SIGTERM to the watcher child.

=item * Polls for up to C<$KILL_TIMEOUT> seconds (default: 5); escalates to SIGKILL
if the child has not exited by then.

=item * Calls C<waitpid> to reap the child.

=item * Clears C<%_config_watchers>.

=back

B<Blocking>: this function may take up to five seconds if the watcher ignores SIGTERM.

=head3 API Specification

=head4 Input

    schema => {}   # no arguments

=head4 Output

    type => 'void'

=cut

sub disable_hot_reload {
	## MUTANT_SKIP_BEGIN
	if(my $pid = $_config_watchers{pid}) {
		# SECURITY (S3 — PID safety):
		#   $pid > 1  excludes PID 0 (sends SIGTERM to whole process group — DoS)
		#             and PID 1 (init — catastrophic as root).
		#   $pid != $$ prevents self-signaling if %_config_watchers is corrupted.
		# Exploit mechanism: if global state is poisoned with pid=0 or pid=1,
		# kill('TERM', 0) signals every process in the group; kill('TERM', 1) kills
		# init as root.  Both are now rejected at the comparison level.
		if($pid =~ /\A[0-9]+\z/ && $pid > 1 && $pid != $$) {
			kill('TERM', $pid);

			# Poll up to KILL_TIMEOUT seconds; escalate to SIGKILL if SIGTERM is ignored.
			# SIGKILL cannot be caught or deferred so the subsequent waitpid is always safe.
			my $deadline = time() + $KILL_TIMEOUT;
			my $kid;
			do {
				$kid = waitpid($pid, WNOHANG);
				if($kid == 0 && time() < $deadline) {
					select undef, undef, undef, $POLL_SLEEP;
				}
			} while($kid == 0 && time() < $deadline);

			if($kid == 0) {
				kill('KILL', $pid);
				waitpid($pid, 0);
			}
		}
		%_config_watchers = ();
	}
	## MUTANT_SKIP_END
}

=head2 reload_config()

Immediately reload configuration from disk for every registered object.

Normally called automatically by the SIGUSR1 handler.  You may call it manually
to force a reload (e.g., in tests or on a custom signal).

=head3 Arguments

None.

=head3 Returns

An integer E<gt>= 0: the count of objects whose configuration was successfully
reloaded.

=head3 Side Effects

=over 4

=item * Reads config files from disk for each registered object.

=item * Updates non-private keys (those not starting with C<_>) in-place on
each live object.

=item * Prunes dead weak references from C<%_object_registry>.

=item * Emits a C<carp> warning (not a croak) if reload fails for any individual
object; other objects are still processed.

=back

=head3 API Specification

=head4 Input

    schema => {}   # no arguments

=head4 Output

    type        => 'integer',
    description => 'Count of objects successfully reloaded',
    condition   => 'value >= 0',

=cut

sub reload_config {
	my $reloaded_count = 0;

	foreach my $class_key (keys %_object_registry) {
		my $objects = $_object_registry{$class_key};

		@$objects = grep { defined $$_ } @$objects;	# prune garbage-collected weak refs (check referent, not the ref-to-scalar itself)

		foreach my $obj_ref (@$objects) {
			if(my $obj = $$obj_ref) {
				# Protect the caller's $@ from being clobbered by our internal eval blocks.
				local $@;
				eval {
					_reload_object_config($obj);
					$reloaded_count++;
				};
				if($@) {
					carp("Failed to reload config for object: $@");
				}
			}
		}

		delete $_object_registry{$class_key} unless @$objects;
	}

	return $reloaded_count;
}

=head2 register_object($class, $obj)

Register a blessed object so it receives configuration updates when files change.

B<Push semantics>: each call I<appends> a new entry to the registry for C<$class>.
It does not replace a previous entry.  Multiple objects of the same class are all
tracked and all reloaded.

=head3 Arguments

=over 4

=item * C<$class> (Required, string)

The class name used to organise the registry.  Typically C<ref($self)> or the
calling package name.

=item * C<$obj> (Required, blessed reference)

The object to register.  B<Must be a blessed reference.>  Passing an unblessed
hashref or any other unblessed value causes an immediate C<croak>.

=back

=head3 Returns

Nothing (void).

=head3 Side Effects

=over 4

=item * Pushes a weak reference to C<$obj> onto C<$_object_registry{$class}>.

=item * On the first call ever (for any class): saves the current C<$SIG{USR1}>
and installs Object::Configure's handler.  On Unix, the handler calls
C<reload_config()> then chains to the prior handler.  On Windows, signal
installation is skipped but C<$_original_usr1_handler> is still set.

=back

=head3 Error messages

=over 4

=item * C<Object::Configure::register_object: Usage ($class, $obj)> --
either C<$class> or C<$obj> was C<undef>.

=item * C<Object::Configure::register_object: $obj must be a blessed reference> --
C<$obj> was defined but not blessed.  This guard prevents DoS via registry flooding
(reloading thousands of unblessed entries on every SIGUSR1).

=back

=head3 Usage Example

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

=head3 API Specification

=head4 Input

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

=head4 Output

    type => 'void'

=cut

sub register_object
{
	my ($class, $obj) = @_;

	croak(__PACKAGE__, '::register_object: Usage ($class, $obj)')
		unless defined($class) && defined($obj);

	# SECURITY: enforce the API contract (POD: "$obj must be a blessed reference").
	# Accepting unblessed refs silently would allow DoS via registry flooding: an
	# adversary or buggy caller can push thousands of unblessed entries; reload_config()
	# iterates every entry on every SIGUSR1, degrading throughput proportionally.
	croak(__PACKAGE__, '::register_object: $obj must be a blessed reference')
		unless blessed($obj);

	my $obj_ref = \$obj;
	weaken($$obj_ref);
	push @{ $_object_registry{$class} }, $obj_ref;

	# Install SIGUSR1 handler exactly once.  We save the previous handler so
	# we can chain to it (another module may have installed one) and restore it
	# on shutdown.  On Windows SIGUSR1 does not exist so we skip the signal work
	# but still save $_original_usr1_handler so restore_signal_handlers is safe.
	if(!defined $_original_usr1_handler) {
		$_original_usr1_handler = $SIG{USR1} || $SIG_DEFAULT;

		return if $^O eq $OS_WINDOWS;

		$SIG{USR1} = sub {
			reload_config();
			$_config_watchers{callback}->() if $_config_watchers{callback};

			if(ref($_original_usr1_handler) eq 'CODE') {
				$_original_usr1_handler->();
			} elsif($_original_usr1_handler eq $SIG_DEFAULT
			     || $_original_usr1_handler eq $SIG_IGNORE) {
				# DEFAULT for USR1 is typically a no-op; IGNORE means discard
			} else {
				carp("Object::Configure: Cannot chain to non-code USR1 handler: $_original_usr1_handler");
			}
		};
	}

	return;
}

=head2 restore_signal_handlers()

Restore C<$SIG{USR1}> to the handler that was in place before
C<register_object()> installed the hot-reload handler, and clear
C<$_original_usr1_handler>.

Safe to call even when Object::Configure never installed a handler (no-op).
On Windows this function has no effect (SIGUSR1 does not exist there).

=head3 Arguments

None.

=head3 Returns

Nothing (void).

=head3 Side Effects

=over 4

=item * Sets C<$SIG{USR1}> back to its saved value (Unix only).

=item * Sets C<$_original_usr1_handler> to C<undef>.

=back

=head3 API Specification

=head4 Input

    schema => {}   # no arguments

=head4 Output

    type => 'void'

=cut

sub restore_signal_handlers
{
	if(defined $_original_usr1_handler) {
		$SIG{USR1} = $_original_usr1_handler unless $^O eq $OS_WINDOWS;
		$_original_usr1_handler = undef;
	}

	return;
}

=head2 get_signal_handler_info()

Return a snapshot of the current signal-handler and hot-reload state.
This is a debugging aid; normal application code does not need to call it.

=head3 Arguments

None.

=head3 Returns

A hashref with these keys:

=over 4

=item * C<original_usr1> -- the C<$SIG{USR1}> value that existed before
Object::Configure installed its handler, or C<undef> if no handler was saved yet.

=item * C<current_usr1> -- the currently installed C<$SIG{USR1}> handler (coderef,
C<'DEFAULT'>, C<'IGNORE'>, or C<undef>).

=item * C<hot_reload_active> -- C<1> if C<$_original_usr1_handler> is defined,
C<''> otherwise.

=item * C<watcher_pid> -- the PID of the background watcher child, or C<undef>
if C<enable_hot_reload()> has not been called (or the watcher has been stopped).

=back

=head3 Usage Example

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

=head3 API Specification

=head4 Input

    schema => {}   # no arguments

=head4 Output

    type        => 'hashref',
    description => 'Snapshot of signal-handler and watcher state',
    schema => {
        original_usr1     => { type => [qw(coderef string undef)] },
        current_usr1      => { type => [qw(coderef string undef)] },
        hot_reload_active => { type => 'boolean'                  },
        watcher_pid       => { type => [qw(integer undef)]        },
    }

=cut

sub get_signal_handler_info {
	return {
		original_usr1    => $_original_usr1_handler,
		current_usr1     => $SIG{USR1},
		hot_reload_active => defined $_original_usr1_handler,
		watcher_pid      => $_config_watchers{pid},
	};
}

# ----------------------------------------------------------------------------
# Private helpers
# All routines below are implementation details; callers must not rely on them.
# ----------------------------------------------------------------------------

# Purpose:   Consolidate all logger-creation paths into one place.
#            Called from configure() and _reconfigure_logger() to eliminate
#            the duplication that existed between the two.
# Entry:     $spec may be: undef (want default), the string 'NULL' (no logging),
#            an ARRAY ref (log-capture array), a HASH ref (options for Log::Abstraction),
#            a pre-built Log::Abstraction instance (pass through), or any other
#            scalar (treated as a logger name / file path).
#            $carp_on_warn is a boolean controlling Carp::carp integration.
# Exit:      Returns a Log::Abstraction instance, or the string 'NULL'.
# Side:      May allocate a new Log::Abstraction object.
sub _build_logger {
	my ($spec, $carp_on_warn) = @_;
	$carp_on_warn //= 0;

	return Log::Abstraction->new(carp_on_warn => $carp_on_warn)
		unless defined $spec;

	return $LOGGER_NULL
		if !ref($spec) && $spec eq $LOGGER_NULL;

	return $spec
		if blessed($spec) && $spec->isa('Log::Abstraction');

	if(ref($spec) eq 'ARRAY') {
		return Log::Abstraction->new(array => $spec, carp_on_warn => $carp_on_warn);
	}

	if(ref($spec) eq 'HASH') {
		return Log::Abstraction->new({ carp_on_warn => $carp_on_warn, %$spec });
	}

	# Scalar: a logger name, file path, or other string identifier passed to L::A
	return Log::Abstraction->new({ carp_on_warn => $carp_on_warn, logger => $spec });
}

# Purpose:   Build the ancestor chain needed for config-file discovery and env merging.
#            Uses the class's own MRO (DFS or C3) via mro::get_linear_isa, which is
#            more correct than a hardcoded DFS walk and handles diamond inheritance.
#            UNIVERSAL is added explicitly because mro::get_linear_isa does not include
#            it unless it appears in @ISA, yet Object::Configure supports universal.yml.
# Entry:     $class is a fully-qualified class name that has already been loaded.
# Exit:      Returns a list in base-first order: (UNIVERSAL, ..., GrandParent, Parent, Class).
#            Result is memoized in %_chain_cache; mro::get_linear_isa is not re-invoked
#            for classes already seen in this process.  The cache is valid for the process
#            lifetime because @ISA is stable after module load in normal Perl programs.
#            Algorithmic cost: O(N) first call; O(1) amortised on subsequent calls.
sub _get_inheritance_chain {
	my ($class) = @_;

	# Cache hit: return a copy of the stored list (caller may modify the returned list).
	return @{ $_chain_cache{$class} } if $_chain_cache{$class};

	my @mro = @{ mro::get_linear_isa($class) };

	# mro::get_linear_isa returns child-first; reverse to get base-first.
	# UNIVERSAL is implicit in Perl's type system but not always in the MRO list,
	# so append it when absent to ensure universal.yml is picked up.
	# List::Util::any is XS and short-circuits on first match -- faster than grep.
	push @mro, 'UNIVERSAL' unless any { $_ eq 'UNIVERSAL' } @mro;

	my @chain = reverse @mro;
	$_chain_cache{$class} = \@chain;   # store arrayref; return list copy below
	return @chain;
}

# Purpose:   Find a config file for a specific ancestor class using the same
#            naming convention as the primary config file (directory + extension).
# Entry:     $class is a fully-qualified class name.
#            $base_config_file is the primary config file path (provides dir and ext).
#            $config_dirs is an optional arrayref of additional search directories.
#            Does NOT modify elements of $config_dirs (trailing-slash removal uses a copy).
# Exit:      Returns a readable file path, or undef if nothing found.
#            Result (including undef for "not found") is memoized in %_find_cache, keyed
#            by (class, base_config_file, config_dirs-elements) joined with NUL bytes.
#            Subsequent calls with identical arguments skip all filesystem probes.
#            Algorithmic cost: O(extensions) syscalls first call; O(1) amortised.
sub _find_class_config_file {
	my ($class, $base_config_file, $config_dirs) = @_;

	# Build a NUL-separated cache key. NUL cannot appear in Linux file paths (the
	# pen-test suite confirms this: Perl's -r warns and returns undef for NUL paths).
	my $cache_key = join("\0", $class, $base_config_file,
		$config_dirs ? @$config_dirs : ());
	return $_find_cache{$cache_key} if exists $_find_cache{$cache_key};

	my $class_file = lc($class);
	$class_file =~ s/::/-/g;

	my ($base_vol, $base_dir_part, $base_name_ext) = File::Spec->splitpath($base_config_file);
	my (undef, $base_ext) = $base_name_ext =~ /^(.*?)(\.[^.]+)?$/;
	$base_ext //= '';
	my $base_dir = File::Spec->catpath($base_vol, $base_dir_part, '');

	# Single-exit-point via labeled block so the cache write happens unconditionally.
	my $found;
	SEARCH: {
		# Dedup: when $base_ext is already .yml/.conf/etc the first candidate would
		# be a duplicate of a later one, causing a redundant filesystem probe.
		my %_seen_pat;
		foreach my $pattern (grep { !$_seen_pat{$_}++ } (
			File::Spec->catfile($base_dir, "${class_file}${base_ext}"),
			File::Spec->catfile($base_dir, "${class_file}.conf"),
			File::Spec->catfile($base_dir, "${class_file}.yml"),
			File::Spec->catfile($base_dir, "${class_file}.yaml"),
			File::Spec->catfile($base_dir, "${class_file}.json"),
		)) {
			if(-r $pattern && -f $pattern) {
				$found = $pattern;
				last SEARCH;
			}
		}

		if($config_dirs && ref($config_dirs) eq 'ARRAY') {
			foreach my $dir (@$config_dirs) {
				# Use a copy so the caller's arrayref element is never mutated.
				(my $clean_dir = $dir) =~ s{/$}{};
				my %_seen_dir_pat;
				foreach my $pattern (grep { !$_seen_dir_pat{$_}++ } (
					"${clean_dir}/${class_file}${base_ext}",
					"${clean_dir}/${class_file}.conf",
					"${clean_dir}/${class_file}.yml",
					"${clean_dir}/${class_file}.yaml",
					"${clean_dir}/${class_file}.json",
				)) {
					if(-r $pattern && -f $pattern) {
						$found = $pattern;
						last SEARCH;
					}
				}
			}
		}
	}

	# Cache stores undef for "not found"; callers must use exists, not defined.
	return ($_find_cache{$cache_key} = $found);
}

# Purpose:   Run as the forked watcher child.  Polls %_config_file_stats and
#            sends SIGUSR1 to the parent when any file changes.
# Entry:     $interval >= 1 (seconds). $callback is unused in the child (it runs
#            in the parent's SIGUSR1 handler).
# Exit:      Never returns; terminates via SIGTERM/SIGINT handlers.
# Side:      Modifies %_config_file_stats entries in the child's address space only.
sub _run_config_watcher {
	my ($interval, $callback) = @_;

	# SECURITY (S5): re-validate $interval in the child process.
	# If the parent's fork() fires before enable_hot_reload() applies its own guard
	# (race) or state is corrupted between fork and here, sleep(0) or sleep(-1) would
	# cause a busy-loop that saturates the CPU.  int() also prevents floating-point
	# values like 0.001 from reaching the kernel as a near-zero sleep.
	$interval = int($interval // $DEFAULT_INTERVAL);
	$interval = $DEFAULT_INTERVAL unless $interval > 0;

	local $SIG{TERM} = sub { exit 0 };
	local $SIG{INT}  = sub { exit 0 };

	while(1) {
		sleep($interval);

		my $changes_detected = 0;

		foreach my $config_file (keys %_config_file_stats) {
			if(-f $config_file) {
				my $current_stat = stat($config_file);
				my $stored_stat  = $_config_file_stats{$config_file};

				if(!$stored_stat || $current_stat->mtime > $stored_stat->mtime) {
					$_config_file_stats{$config_file} = $current_stat;
					$changes_detected = 1;
				}
			} else {
				delete $_config_file_stats{$config_file};
				$changes_detected = 1;
			}
		}

		if($changes_detected && $^O ne $OS_WINDOWS) {
			if(my $parent_pid = getppid()) {
				kill('USR1', $parent_pid);
			}
		}
	}
}

# Purpose:   Reload a single object's configuration from disk and update its fields.
#            Private properties (prefix '_') are intentionally skipped to avoid
#            clobbering internal bookkeeping set at construction time.
# Entry:     $obj must be a blessed reference with a {_config_file} or {_config_files} key.
# Exit:      Returns nothing; updates $obj in-place.
# Side:      Reads from disk. Calls $obj->_on_config_reload if the method exists.
sub _reload_object_config {
	my $obj = $_[0];

	return unless blessed($obj);

	my $class          = ref($obj);
	my $original_class = $class;
	$class =~ s/::/__/g;

	# Prefer the most-specific (last) file from the full list; fall back to scalar key
	my $config_file;
	if($obj->{_config_files} && ref($obj->{_config_files}) eq 'ARRAY' && @{ $obj->{_config_files} }) {
		$config_file = $obj->{_config_files}[-1];
	} else {
		$config_file = $obj->{_config_file} || $obj->{config_file};
	}

	# SECURITY (S1 — path traversal): an attacker who modifies $obj->{_config_file}
	# (e.g., via a deserialization gadget or a malicious config merge) can redirect
	# hot-reload to read arbitrary system files.  Reject paths with ".." segments here
	# so that even a corrupted object cannot force a traversal read.
	# Must come BEFORE the -f check so traversal paths for non-existent files are also rejected.
	if($config_file && $config_file =~ $RE_PATH_TRAVERSAL) {
		carp(__PACKAGE__, ': _reload_object_config: refusing path with traversal sequences: ',
			$config_file);
		return;
	}

	return unless $config_file && -f $config_file;

	my $config = Config::Abstraction->new(
		config_file => $config_file,
		env_prefix  => "${class}__"
	);

	if($config) {
		my $new_params = $config->merge_defaults(
			defaults => {},
			section  => $class,
			merge    => 1,
			deep     => 1
		);

		foreach my $key (keys %$new_params) {
			next if $key =~ /^_/;

			if($key eq 'logger') {
				# Only the exact 'logger' key triggers logger reconstruction.
				# Keys like 'logger.file' are flat config values, not logger specs.
				# Guard: assign directly for undef (no logger) or literal 'NULL'.
				# Premise 1: _build_logger handles every other spec type.
				# Premise 2: undef/NULL need no construction. Conclusion: rebuild only otherwise.
				my $val = $new_params->{$key};
				if(!defined($val) || (!ref($val) && $val eq $LOGGER_NULL)) {
					$obj->{$key} = $val;
				} else {
					_reconfigure_logger($obj, $key, $val);
				}
			} else {
				$obj->{$key} = $new_params->{$key};
			}
		}

		$obj->_on_config_reload($new_params) if $obj->can('_on_config_reload');

		$obj->{logger}->info("Configuration reloaded for $original_class")
			if $obj->{logger} && $obj->{logger}->can('info');
	}

	return;
}

# Purpose:   Replace the logger on an already-constructed object with one
#            built from a new config value (typically a YAML hashref).
#            Delegates to _build_logger so logger-creation logic lives in one place.
# Entry:     $obj is a blessed hashref. $key is the hash key to update (usually 'logger').
#            $logger_config is the new spec from the config file.
# Exit:      Returns nothing; updates $obj->{$key} in-place.
# Side:      May allocate a new Log::Abstraction instance.
sub _reconfigure_logger
{
	my ($obj, $key, $logger_config) = @_;
	my $carp_on_warn = $obj->{carp_on_warn} || 0;
	$obj->{$key} = _build_logger($logger_config, $carp_on_warn);
	return;
}

# Purpose:   Right-precedence deep merge of two hash references.
#            Scalar/arrayref values in $overlay replace those in $base entirely;
#            nested hashrefs are merged recursively.
# Entry:     Both args should be hashrefs (or undef/non-ref, handled gracefully).
# Exit:      Returns a new hashref; neither input is modified.
sub _deep_merge {
	my ($base, $overlay) = @_;

	return $overlay unless ref($base)    eq 'HASH';
	return $overlay unless ref($overlay) eq 'HASH';

	my $result = { %$base };

	foreach my $key (keys %$overlay) {
		if(ref($overlay->{$key}) eq 'HASH' && ref($result->{$key}) eq 'HASH') {
			$result->{$key} = _deep_merge($result->{$key}, $overlay->{$key});
		} else {
			$result->{$key} = $overlay->{$key};
		}
	}

	return $result;
}

# Clean up the watcher child and restore signal state on interpreter exit.
END {
	disable_hot_reload();
	restore_signal_handlers();
}

=head1 SEE ALSO

=over 4

=item * L<Config::Abstraction>

=item * L<Log::Abstraction>

=item * L<Test Dashboard|https://nigelhorne.github.io/Object-Configure/coverage/>

=back

=head1 LIMITATIONS

=over 4

=item * B<Global singleton state.> C<%_object_registry>, C<%_config_watchers>, and
C<%_config_file_stats> are package globals.  Two independent subsystems in the same
process share one hot-reload registry and one SIGUSR1 handler.  There is no
instance-level isolation.  A proper fix would wrap state in an object and allow
multiple independent C<Object::Configure> instances, but that would break the
existing constructor-call API (C<configure($class, \%params)>).

=item * B<Hot reload is Unix-only.> SIGUSR1 does not exist on Windows.
All signal-related paths are guarded with C<$^O ne 'MSWin32'>, so the module
loads on Windows but silently skips hot-reload registration.

=item * B<configure() is a God function.> At ~120 lines it handles arg validation,
config-file discovery, MRO walking, multi-file merging, env-var merging, logger
creation, and hot-reload bookkeeping.  Future versions should decompose this into
smaller, independently testable units.

=item * B<_deep_merge reimplements CPAN.> L<Hash::Merge::Simple> or L<Hash::Merge>
provide tested, feature-complete deep merge.  The internal C<_deep_merge> is 15
lines and correct for the current use, but does not handle arrayrefs (they are
replaced wholesale, not merged).  If array-merge semantics are ever needed, switch
to a CPAN module.

=item * B<No encapsulation enforcement.> Private helpers (C<_build_logger>,
C<_get_inheritance_chain>, etc.) are accessible to any caller.  L<Sub::Private>
(enforce mode) would make accidental external use a compile-time error.  It is not
added here to avoid a smoker dependency on a less-common module.

=item * B<configure() signature is positional, instantiate() is named.>  The two
public constructors have inconsistent calling conventions.  Normalising them to named
args would require a deprecation cycle.

=item * B<mro::get_linear_isa and UNIVERSAL.>  Perl's C<mro::get_linear_isa> does
not include C<UNIVERSAL> in its output unless C<UNIVERSAL> appears explicitly in
C<@ISA>.  This module appends C<UNIVERSAL> manually so that C<universal.yml> is
always discovered.  If a future Perl version changes this behaviour the guard
(C<grep { $_ eq 'UNIVERSAL' }>) remains correct.

=back

=head1 Formal Specification

=head2 configure

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

=head2 instantiate

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

=head2 enable_hot_reload

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

=head2 disable_hot_reload

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

=head2 reload_config

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

=head2 register_object

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

=head2 restore_signal_handlers

    restore_signal_handlers: () -> ()

    State:
    - _original_usr1_handler: SignalHandler union {empty}
    - $SIG{USR1}: SignalHandler

    Pre-condition:
    true

    Post-condition:
    $SIG{USR1}@post = _original_usr1_handler@pre
    _original_usr1_handler@post = empty

=head2 get_signal_handler_info

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

=head1 SUPPORT

Please report bugs and feature requests at:

=over 4

=item * RT (CPAN bug tracker): L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Configure>

or by e-mail: C<bug-object-configure at rt.cpan.org>

=item * GitHub issues: L<https://github.com/nigelhorne/Object-Configure/issues>

=back

You will be notified automatically of progress on your report.

    perldoc Object::Configure

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to GPL2 licence terms.
If you use it, please let me know.

=cut

1;
