# NAME

Shell::GetEnv - extract the environment from a shell after executing commands

# SYNOPSIS

    use Shell::GetEnv;

    $env = Shell::GetEnv->new( $shell, $command );
    $status = $env->status;
    $envs = $env->envs( %opts )
    $env->import_envs( %opts );

# DESCRIPTION

**Shell::GetEnv** provides a facility for obtaining changes made to
environmental variables as the result of running shell scripts.  It
does this by causing a shell to invoke a series of user provided shell
commands (some of which might source scripts) and having the shell
process store its environment (using a short Perl script) into a
temporary file, which is parsed by **Shell::Getenv**.

Communications with the shell subprocess may be done via standard IPC
(via a pipe), or may be done via the Perl **Expect** module (necessary
if proper execution of the shell script requires the shell to be
attached to a "real" terminal).

The new environment may be imported into the current one, or may be
returned either as a hash or as a string suitable for use with the
\*NIX **env** command.

# METHODS

- new

        $env = Shell::GetEnv->new( $shell, @cmds, \%attrs );

    Start the shell specified by _$shell_, run the passed commands, and
    retrieve the environment.  Note that only shell built-in
    commands can actually change the shell's environment, so typically
    the commands source a startup file.  For example:

        $env = Shell::GetEnv->new( 'tcsh', 'source foo.csh' );

    The supported shells are:

        csh tcsh bash sh ksh zsh dash

    Attributes:

    - `startup` _boolean_

        If true, the user's shell startup files are invoked.  This flag is
        supported for `csh`, `tcsh`, and `bash`.  This is emulated under
        **ksh** using its **-p** flag, which isn't quite the same thing.

        There seems to be no clean means of turning off startup file
        processing under the other shells.

        This defaults to _true_.

    - `echo` _boolean_

        If true, put shell is put in echo mode.  This is only of use when the
        `stdout` attribute is used.  It defaults to _false_.

    - `interactive` _boolean_

        If true, put the shell in interactive mode. Some shells do not react
        well when put in interactive mode but not connected to terminals.
        Try using the `expect` option instead. This defaults to _false_.

    - `login` _boolean_

        If true, invoke the shell as a login shell.  Defaults to
        _false_.

        **tcsh** and **csh** will only honor this option if no other command
        line options are passed.  For these shells **Shell::GetEnv** will
        throw an exception if this option conflicts with another.

    - `redirect` _boolean_

        If true, redirect the output and error streams (see also the `STDERR`
        and `stdout` options).  Defaults to true.

    - `verbose` _boolean_

        If true, put the shell in verbose mode.  This is only of use when the
        `stdout` attribute is used.  It defaults to _false_.

    - `stderr` _filename_

        Normally output from the shells' standard error stream is discarded.
        This may be set to a file name to which the stream
        should be written.  See also the `redirect` option.

    - `stdout` _filename_

        Normally output from the shells' standard output stream is discarded.
        This may be set to a file name to which the stream
        should be written.  See also the `Redirect` option.

    - `expect` _boolean_

        If true, the Perl **Expect** module is used to communicate with the
        subshell.  This is useful if it is necessary to simulate connection
        with a terminal, which may be important when setting up some
        enviroments.

    - `timeout` _integer_

        The number of seconds to wait for a response from the shell when using
        **Expect**.  It defaults to 10 seconds.

    - `shellopts` _scalar_ or _arrayref_

        Arbitrary options to be passed to the shell.

- envs

        $env = $env->envs( [%opt] );

    Return the environment.  Typically the environment is returned as a
    hashref, but if the `envstr` option is true it will be returned as a
    string suitable for use with the \*NIX **env** command.  If no options
    are specified, the entire environment is returned.

    The following options are recognized:

    - `diffsonly` _boolean_

        If true, the returned environment contains only those variables which
        are new or which have changed from the current environment.  There is no way of
        indicating Variables which have been _deleted_.

    - `exclude` _array_ or _scalar_

        This specifies variables to exclude from the returned environment.  It
        may be either a single value or an array of values.

        A value may be a string (for an exact match of a variable name), a regular
        expression created with the **qr** operator, or a subroutine
        reference.  The subroutine will be passed two arguments, the variable
        name and its value, and should return true if the variable should be
        excluded, false otherwise.

    - `envstr` _boolean_

        If true, a string representation of the environment is returned,
        suitable for use with the \*NIX **env** command.  Appropriate quoting is
        done so that it is correclty parsed by shells.

        If the `zapdeleted` option is also specified (and is true) variables
        which are present in the current environment but _not_ in the new one
        are explicitly deleted by inserting `-u variablename` in the output
        string.  **Note**, however, that not all versions of **env** recognize the
        **-u** option (e.g. those in Solaris or OS X).  In those cases, to ensure the
        correct environment, use `diffsonly =` 0, zapdeleted => 0> and
        invoke **env** with the `-i` option.

- status

        $status = $env->status;

    Returns the invoked shell's status after executing the commands
    provided to the constructor.  See ["system" in perlfunc](https://metacpan.org/pod/perlfunc#system) for instructions
    on how to interpret the status.

- import\_envs

        $env->import_envs( %opt )

    Import the new environment into the current one.  The available
    options are:

    - `exclude` _array_ or _scalar_

        This specifies variables to exclude from the returned environment.  It
        may be either a single value or an array of values.

        A value may be a string (for an exact match of a variable name), a regular
        expression created with the **qr** operator, or a subroutine
        reference.  The subroutine will be passed two arguments, the variable
        name and its value, and should return true if the variable should be
        excluded, false otherwise.

    - `zapdeleted` _boolean_

        If true, variables which are present in the current environment but
        _not_ in the new one are deleted from the current environment.

## EXPORT

None by default.

# SEE ALSO

There are other similar modules on CPAN. [Shell::Source](https://metacpan.org/pod/Shell::Source) is simpler,
[Shell::EnvImporter](https://metacpan.org/pod/Shell::EnvImporter) is a little more heavyweight (requires Class::MethodMaker).

This module's unique features:

- can use Expect for the times you really need a terminal
- uses a tiny Perl program to get the environmental variables rather than parsing shell output
- allows the capturing of shell output
- more flexible means of submitting commands to the shell

# DEPENDENCIES

The **YAML::Tiny** module is preferred for saving the environment
(because of its smaller footprint); the **Data::Dumper** module
will be used if it is not available.

The **Expect** module is required only if the `expect` option is
specified.

# AUTHOR

Diab Jerius, <djerius@cpan.org>

# CONTRIBUTORS

- Marty O'Brien <mob@cpan.org>

# COPYRIGHT AND LICENSE

Copyright 2007 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

          http://www.gnu.org/licenses
