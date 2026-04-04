[![testsuite](https://github.com/cpan-authors/Razor2-Client-Agent/actions/workflows/testsuite.yml/badge.svg)](https://github.com/cpan-authors/Razor2-Client-Agent/actions/workflows/testsuite.yml)

# NAME

Razor2::Client::Agent - Command-line interface for Vipul's Razor spam detection

# SYNOPSIS

    use Razor2::Client::Agent;

    my $agent = Razor2::Client::Agent->new('razor-check');
    $agent->read_options() or $agent->raise_error;
    $agent->do_conf()      or $agent->raise_error;
    my $rc = $agent->doit({});
    exit $rc;

# DESCRIPTION

Razor2::Client::Agent provides the user interface layer for Vipul's Razor,
a distributed, collaborative spam detection and filtering network.  It
implements the command-line tools **razor-check**, **razor-report**,
**razor-revoke**, and **razor-admin**.

This module inherits from [Razor2::Client::Core](https://metacpan.org/pod/Razor2%3A%3AClient%3A%3ACore) (network protocol),
[Razor2::Client::Config](https://metacpan.org/pod/Razor2%3A%3AClient%3A%3AConfig) (configuration management), [Razor2::Logger](https://metacpan.org/pod/Razor2%3A%3ALogger)
(logging), and [Razor2::String](https://metacpan.org/pod/Razor2%3A%3AString) (utility functions).

Typical usage is through the command-line programs rather than calling
this module directly.  See [razor-check(1)](http://man.he.net/man1/razor-check), [razor-report(1)](http://man.he.net/man1/razor-report),
[razor-revoke(1)](http://man.he.net/man1/razor-revoke), and [razor-admin(1)](http://man.he.net/man1/razor-admin).

# METHODS

- **new($breed)**

    Constructor.  `$breed` is the full program name, which must end with one
    of `razor-check`, `razor-report`, `razor-revoke`, or `razor-admin`.
    The breed determines which operations are available.

    Deletes `$ENV{PATH}` and `$ENV{BASH_ENV}` for taint safety.

- **read\_options($agent)**

    Parses command-line options via [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong).  Returns true on success,
    false on error (error message available via `errstr()`).

- **do\_conf()**

    Processes configuration: resolves razorhome, reads the config file, sets up
    logging, and creates the home directory if `-create` was specified.
    Must be called after `read_options()`.

- **doit($args)**

    Main dispatcher.  Calls the appropriate handler based on the breed:
    `checkit()` for check, `adminit()` for admin, `reportit()` for report
    and revoke.

    Returns 0 for match (spam), 1 for no match (not spam), or 2 for error.

- **checkit($args)**

    Checks mail against the Razor catalogue servers.  Accepts input as
    filenames, mbox files, signatures on the command line, or a filehandle
    in `$args`.

    Return values: 0 = spam detected, 1 = not spam, 2 = error.

- **reportit($args)**

    Reports mail as spam (or revokes a previous report).  Requires a valid
    Razor identity; attempts automatic registration if none is found.
    Backgrounds itself unless `-f` (foreground) is specified.

    Return values: 0 = success, 2 = error.

- **adminit($args)**

    Handles administrative tasks: creating razorhome (`-create`), server
    discovery (`-discover`), and identity registration (`-register`).

    Return values: 0 = success, 2 = error.

- **parse\_mbox($args)**

    Parses input into individual mail messages.  Supports mbox format
    (splitting on `^From ` lines), single RFC 822 messages, filehandle
    input (via `$args->{fh}`), and array reference input (via
    `$args->{aref}`).

    Returns an array reference of scalar references to mail content.

- **local\_check($obj)**

    Performs local whitelist and mailing-list checks.  Returns true if the
    mail should be skipped (not checked against the server).

- **read\_whitelist()**

    Loads the whitelist file specified in the configuration.  The whitelist
    maps header names to patterns; matching mail is skipped.

- **get\_server\_info()**

    Reads server lists, loads cached server configurations, and resolves the
    next server to connect to.  Called before network operations.

- **raise\_error($errstr)**

    Prints a fatal error message and exits with the Razor error code extracted
    from the message, or 255 if no code is found.

- **log($level, $msg)**

    Logs a message at the given debug level.  Uses the [Razor2::Logger](https://metacpan.org/pod/Razor2%3A%3ALogger)
    instance if available, otherwise prints to STDOUT in debug mode.

- **logll($loglevel)**

    Returns true if the current debug level is at or above `$loglevel`.
    Use this to guard expensive log message construction.

# CONFIGURATION

See [razor-agent.conf(5)](http://man.he.net/man5/razor-agent.conf) for configuration file format and options.

The razorhome directory (default `~/.razor/`, system-wide `/etc/razor/`)
stores configuration files, server lists, identity files, and logs.

# SEE ALSO

[razor-check(1)](http://man.he.net/man1/razor-check), [razor-report(1)](http://man.he.net/man1/razor-report), [razor-revoke(1)](http://man.he.net/man1/razor-revoke),
[razor-admin(1)](http://man.he.net/man1/razor-admin), [razor-agent.conf(5)](http://man.he.net/man5/razor-agent.conf), [razor-whitelist(5)](http://man.he.net/man5/razor-whitelist),
[Razor2::Client::Core](https://metacpan.org/pod/Razor2%3A%3AClient%3A%3ACore), [Razor2::Client::Config](https://metacpan.org/pod/Razor2%3A%3AClient%3A%3AConfig)

# AUTHORS

Vipul Ved Prakash, <mail@vipul.net>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
