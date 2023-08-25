# NAME

Net::CLI::Interact - Toolkit for CLI Automation

# PURPOSE

This module exists to support developers of applications and libraries which
must interact with a command line interface.

# SYNOPSIS

    use Net::CLI::Interact;
    
    my $s = Net::CLI::Interact->new({
       personality => 'cisco',
       transport   => 'Telnet',
       connect_options => { host => '192.0.2.1' },
    });
    
    # respond to a usename/password prompt
    $s->macro('to_user_exec', {
        params => ['my_username', 'my_password'],
    });
    
    my $interfaces = $s->cmd('show ip interfaces brief');
    
    $s->macro('to_priv_exec', {
        params => ['my_password'],
    });
    # matched prompt is updated automatically
    
    # paged output is slurped into one response
    $s->macro('show_run');
    my $config = $s->last_response;

# DESCRIPTION

Automating command line interface (CLI) interactions is not a new idea, but
can be tricky to implement. This module aims to provide a simple and
manageable interface to CLI interactions, supporting:

- SSH, Telnet and Serial-Line connections
- Unix and Windows support
- Reuseable device command phrasebooks

If you're a new user, please read the
[Tutorial](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3AManual%3A%3ATutorial). There's also a
[Cookbook](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3AManual%3A%3ACookbook) and a [Phrasebook
Listing](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3AManual%3A%3APhrasebook). For a more complete worked
example check out the [Net::Appliance::Session](https://metacpan.org/pod/Net%3A%3AAppliance%3A%3ASession) distribution, for which this
module was written.

# INTERFACE

## new( \\%options )

Prepares a new session for you, but will not connect to any device. On
Windows platforms, you **must** download the `plink.exe` program, and pass
its location to the `app` parameter. Other options are:

- `personality => $name` (required)

    The family of device command phrasebooks to load. There is a built-in library
    within this module, or you can provide a search path to other libraries. See
    [Net::CLI::Interact::Manual::Phrasebook](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3AManual%3A%3APhrasebook) for further details.

- `transport => $backend` (required)

    The name of the transport backend used for the session, which may be one of
    [Telnet](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3ATransport%3A%3ATelnet),
    [SSH](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3ATransport%3A%3ASSH), or
    [Serial](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3ATransport%3A%3ASerial).

- `connect_options => \%options`

    If the transport backend can take any options (for example the target
    hostname), then pass those options in this value as a hash ref. See the
    respective manual pages for each transport backend for further details.

- `log_at => $log_level`

    To make using the `logger` somewhat easier, you can pass this argument the
    name of a log _level_ (such as `debug`, `info`, etc) and all logging in the
    library will be enabled at that level. Use `debug` to learn about how the
    library is working internally. See [Net::CLI::Interact::Logger](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3ALogger) for a list of
    the valid level names.

- `timeout => $seconds`

    Configures a default timeout value, in seconds, for interaction with the
    remote device. The default is 10 seconds. You can also set timeout on a
    per-command or per-macro call (see below).

    Note that this does not (currently) apply to the initial connection.

## cmd( $command )

Execute a single command statement on the connected device, and consume output
until there is a match with the current _prompt_. The statement is executed
verbatim on the device, with a newline appended.

In scalar context the `last_response` is returned (see below). In list
context the gathered response is returned as a list of lines. In both cases
your local platform's newline character will end all lines.

## macro( $name, \\%options? )

Execute the commands contained within the named Macro, which must be loaded
from a Phrasebook. Options to control the output, including variables for
substitution into the Macro, are passed in the `%options` hash reference.

In scalar context the `last_response` is returned (see below). In list
context the gathered response is returned as a list of lines. In both cases
your local platform's newline character will end all lines.

## last\_response

Returns the gathered output after the most recent `cmd` or `macro`. In
scalar context all data is returned. In list context the gathered response is
returned as a list of lines. In both cases your local platform's newline
character will end all lines.

## transport

Returns the [Transport](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3ATransport) backend which was
loaded based on the `transport` option to `new`. See the
[Telnet](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3ATransport%3A%3ATelnet),
[SSH](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3ATransport%3A%3ASSH), or
[Serial](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3ATransport%3A%3ASerial) documentation for further
details.

## phrasebook

Returns the Phrasebook object which was loaded based on the `personality`
option given to `new`. See [Net::CLI::Interact::Phrasebook](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3APhrasebook) for further
details.

## set\_phrasebook( \\%options )

Allows you to (re-)configure the loaded phrasebook, perhaps changing the
personality or library, or other properties. The `%options` Hash ref should
be any parameters from the [Phrasebook](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3APhrasebook)
module, but at a minimum must include a `personality`.

## set\_default\_contination( $macro\_name )

Briefly, a Continuation handles the slurping of paged output from commands.
See the [Net::CLI::Interact::Phrasebook](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3APhrasebook) documentation for further details.

Pass in the name of a defined Contination (Macro) to enable paging handling as
a default for all sent commands. This is an alternative to describing the
Continuation format in each Macro.

To unset the default Continuation, call the `clear_default_continuation`
method.

## logger

This is the application's [Logger](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3ALogger) object. A
powerful logging subsystem is available to your application, built upon the
[Log::Dispatch](https://metacpan.org/pod/Log%3A%3ADispatch) distribution. You can enable logging of this module's
processes at various levels, or add your own logging statements.

## set\_global\_log\_at( $level )

To make using the `logger` somewhat easier, you can pass this method the
name of a log _level_ (such as `debug`, `info`, etc) and all logging in the
library will be enabled at that level. Use `debug` to learn about how the
library is working internally. See [Net::CLI::Interact::Logger](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3ALogger) for a list of
the valid level names.

# FUTHER READING

## Prompt Matching

Whenever a command statement is issued, output is slurped until a matching
prompt is seen in that output. Control of the Prompts is shared between the
definitions in [Net::CLI::Interact::Phrasebook](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3APhrasebook) dictionaries, and methods of
the [Net::CLI::Interact::Role::Prompt](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3ARole%3A%3APrompt) core component. See that module's
documentation for further details.

## Actions and ActionSets

All commands and macros are composed from their phrasebook definitions into
[Actions](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3AAction) and
[ActionSets](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3AActionSet) (iterable sequences of Actions).
See those modules' documentation for further details, in case you wish to
introspect their structures.

# COMPOSITION

See the following for further interface details:

- [Net::CLI::Interact::Role::Engine](https://metacpan.org/pod/Net%3A%3ACLI%3A%3AInteract%3A%3ARole%3A%3AEngine)

# AUTHOR

Oliver Gorwits <oliver@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Oliver Gorwits.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
