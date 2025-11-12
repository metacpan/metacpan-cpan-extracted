[![Actions Status](https://github.com/hkoba/perl-MouseX-OO_Modulino/actions/workflows/test.yml/badge.svg)](https://github.com/hkoba/perl-MouseX-OO_Modulino/actions)
# NAME

MouseX::OO\_Modulino - Turn your Mouse class into JSON-aware Object-Oriented Modulino.

# SYNOPSIS

    #!/usr/bin/env perl
    package MyModule;
    use MouseX::OO_Modulino -as_base; # ← use Mouse;

    has foo => (is => 'ro', default => 'FOO');
    sub funcA { [shift->foo , "A", @_] }

    __PACKAGE__->cli_run(\@ARGV) unless caller; # ← Modulino!
    1;

Then you can do below from command-line:

    % ./MyModule.pm foo
    FOO
    % ./MyModule.pm --foo=BAR foo
    BAR
    %  ./MyModule.pm --foo='{"foo":3,"bar":8}' funcA '[3,4,5]'
    [{"foo":3,"bar":8},"A",[3,4,5]]

# DESCRIPTION

MouseX::OO\_Modulino is a base class to extend your Mouse class to be
an **OO Modulino(Object-Oriented Modulino)**. OO Modulino is an extension of [Modulino](https://perlmaven.com/modulino-both-script-and-module) that adds an initialization and
method dispatch mechanism, allowing any method to be invoked as a CLI
subcommand.

OO Modulino introduces a consistent set of conventions to the Modulino's CLI, inspired by CLI tools with subcommands like git:

    program [GLOBAL_OPTIONS] COMMAND [COMMAND_ARGS]

- `GLOBAL_OPTIONS`: Passed to constructor (`--key=value` format)
- `COMMAND`: Method name to invoke
- `COMMAND_ARGS`: Arguments to the method

By introducing this calling convention to the Modulino's CLI, it becomes possible to easily test any method of a module from the command line. This is an extremely valuable characteristic for both module developers and those who test the module later.

# METHODS

## `cli_run(\@ARGV, \%shortcuts)`

    __PACKAGE__->cli_run(\@ARGV) unless caller;

    # With option shortcuts
    __PACKAGE__->cli_run(\@ARGV, {h => 'help', v => 'verbose'}) unless caller;

Main entry point for CLI execution. Parses arguments, creates an instance,
and invokes the appropriate method. Options before the command become
constructor arguments, remaining arguments are passed to the method.

Option format: `--name` or `--name=value` (no space between name and value).

JSON values in options and arguments are automatically decoded:

    $ ./MyScript.pm --config='{"port":8080}' process '[1,2,3]'

# OPTIONS

These options control CLI behavior and are processed by `cli_run`:

- `--help`

    Show help message and exit

- `--quiet`

    Suppress normal output

- `--scalar`

    Evaluate methods in scalar context (default is list context)

- `--output=FORMAT`

    Output format: `jsonl` (default), `json`(alias of jsonl), `dump`

- `--undef_as=STRING`

    How to represent undef in TSV output (default: "null")

- `--no_exit_code`

    Don't set exit code based on results

- `--binary`

    Keep STDIN/STDOUT/STDERR in binary mode (no UTF-8 encoding)

# SEE ALSO

- [MOP4Import::Base::CLI\_JSON](https://metacpan.org/pod/MOP4Import%3A%3ABase%3A%3ACLI_JSON)
- [OO Modulino Pattern](https://github.com/hkoba/perl-mop4import-declare/blob/master/docs/OO_Modulino.md)

# LICENSE

Copyright (C) Kobayasi, Hiroaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kobayasi, Hiroaki <buribullet@gmail.com>
