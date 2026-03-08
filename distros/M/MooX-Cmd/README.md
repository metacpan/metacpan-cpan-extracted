# MooX::Cmd

**Command-organized CLI apps with Moo**

MooX::Cmd makes it easy to build command-line applications with nested subcommands, all using the lightweight [Moo](https://metacpan.org/pod/Moo) OOP framework. Commands form a tree structure mirrored in your package hierarchy -- each command gets its own class, its own options, and its own `execute` method.

[![CPAN Version](https://img.shields.io/cpan/v/MooX-Cmd.svg)](https://metacpan.org/pod/MooX::Cmd)

## Quick Start

```perl
package MyApp;
use Moo;
use MooX::Cmd;

sub execute {
    my ($self, $args, $chain) = @_;
    say "Hello from MyApp!";
}

package MyApp::Cmd::greet;
use Moo;
use MooX::Cmd;

sub execute {
    my ($self, $args, $chain) = @_;
    say "Hello, @{$args}!";
}

package main;
MyApp->new_with_cmd;
```

```
$ myapp greet World
Hello, World!
```

## Features

- Nested subcommand trees (`myapp foo bar baz`)
- Command chain with full access to parent instances
- Integrates seamlessly with [MooX::Options](https://metacpan.org/pod/MooX::Options) for option parsing
- Optional [MooX::ConfigFromFile](https://metacpan.org/pod/MooX::ConfigFromFile) support
- Optional abbreviated commands via [Text::Abbrev](https://metacpan.org/pod/Text::Abbrev)
- Testing utilities via [MooX::Cmd::Tester](https://metacpan.org/pod/MooX::Cmd::Tester)

## How It Works

Commands are discovered via [Module::Pluggable](https://metacpan.org/pod/Module::Pluggable) under `YourApp::Cmd::*`. Subcommands nest further: `YourApp::Cmd::Foo::Cmd::Bar` handles `yourapp foo bar`.

Each command in the chain is instantiated. Only the most specific (deepest) command's `execute` is called, but all parent instances are available through the command chain.

## With MooX::Options

```perl
package MyApp;
use Moo;
use MooX::Cmd;
use MooX::Options;

option verbose => (is => 'ro', doc => 'Enable verbose output');

sub execute {
    my ($self, $args, $chain) = @_;
    say "Running in verbose mode" if $self->verbose;
}
```

```
$ myapp --verbose
Running in verbose mode
```

## Installation

```
cpanm MooX::Cmd
```

## Documentation

Full documentation is available on [MetaCPAN](https://metacpan.org/pod/MooX::Cmd).

## License

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
