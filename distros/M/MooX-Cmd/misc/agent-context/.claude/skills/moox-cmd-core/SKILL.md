---
name: moox-cmd-core
description: "Load before editing MooX-Cmd — the Moo-based framework for command-organized CLI apps: module map, the import options and the attributes they override, the command discovery and chain rules, the execute and return-value contract, the tester semantics, and the rough edges of this repository."
---

# MooX::Cmd — core

MooX::Cmd is a **framework distribution**: it ships no application, it ships the
machinery that turns a Moo class tree into a command line application with nested
subcommands. Five modules, no binary, no runtime configuration. Everything else in
the repository is test scaffolding: the applications under `t/lib/` and their
fixtures under `etc/`.

| File | Role |
|---|---|
| `lib/MooX/Cmd.pm` | the importer: `use MooX::Cmd` composes the role into the caller, adds the creation method, applies the import options |
| `lib/MooX/Cmd/Role.pm` | the engine: the attributes, the `@ARGV` split, command discovery, chain construction, the execute call, the storage of its return value |
| `lib/MooX/Cmd/Tester.pm` | the test helper: `test_cmd` / `test_cmd_ok`, output capture, the result object |
| `lib/MooX/Cmd/Role/AbbrevCmds.pm` | optional role: any unambiguous prefix of a command name works |
| `lib/MooX/Cmd/Role/ConfigFromFile.pm` | optional role: per-command config file sections |

## The composition model

```perl
package MyApp;            use Moo; use MooX::Cmd;   # composes MooX::Cmd::Role
package MyApp::Cmd::Foo;  use Moo; use MooX::Cmd;   # a command class
```

`use MooX::Cmd` composes `MooX::Cmd::Role` into the calling class, adds the
creation method `new_with_cmd` to the caller's stash, adds an `execute_return`
accessor when the import option `execute_return_method_name` is given, and
installs `around` modifiers for every builder the import options name. The
importer **returns early for a role** — a role's `@ISA` is empty, so `use
MooX::Cmd` inside a role is a no-op. That is deliberate, not a bug.

## The import options

| Option | Overrides | Meaning |
|---|---|---|
| `base` | `_build_command_base` | the package prefix below which command classes are searched; default: the class name plus `::Cmd` |
| `execute_method_name` | `_build_command_execute_method_name` | the method that runs the command; default `execute` |
| `execute_return_method_name` | `_build_command_execute_return_method_name` | the attribute the execute return value is stored under; default `execute_return` |
| `creation_method_name` | `_build_command_creation_method_name` | the constructor the importer adds; default `new_with_cmd` |
| `creation_chain_methods` | `_build_command_creation_chain_methods` | the constructors tried in order; default `['new_with_options', 'new']` |
| `execute_from_new` | `_build_command_execute_from_new` | whether the constructor itself runs the command; default `1` in the importer, `0` in the role |
| `with_config_from_file` | — | also composes `MooX::ConfigFromFile::Role` and `MooX::Cmd::Role::ConfigFromFile` |
| `with_abbrev_cmds` | — | also composes `MooX::Cmd::Role::AbbrevCmds` |

An import option is a **constructor-time decision** — it decides which class is
built and how. A behavior change here is visible in every application that uses
the framework and needs a `Changes` entry and a test that pins it.

## The role attributes

`command_args` (ro) — the arguments left after the command words were consumed.
`command_chain` (ro) — the instantiated chain, application first, deepest command
last; `command_chain_end` (lazy) — its last element. `command_name` (ro) — the
name of the command that was matched. `command_commands` (lazy) — hashref of
command name → command package. `command_base` (lazy) — the search prefix for
command classes.
`command_execute_method_name` (lazy) — `execute`; `command_execute_return_method_name`
(lazy) — `execute_return`; `command_creation_method_name` (lazy) — `new_with_cmd`;
`command_creation_chain_methods` (lazy) — `['new_with_options', 'new']`;
`command_execute_from_new` (lazy) — whether the constructor runs the command.

## The command contract

**Discovery.** Below `command_base` every package is a command. The command name
is that package name with the base prefix stripped and the rest lowercased:
`MyApp::Cmd::Foo` → `foo`, `MyApp::Cmd::Foo::Cmd::Bar` → `bar` under its own base
`MyApp::Cmd::Foo::Cmd`. When two packages map to the same name, the framework
croaks `Can't compute unambiguous list of commands from …` — the tree is
ambiguous, and the app must resolve it, not the framework.

**The chain.** Only the **deepest** command of the chain executes. The parents
are instantiated and stay reachable through `command_chain`, but their `execute`
is not called. `myapp cmd sub` instantiates `MyApp`, `MyApp::Cmd::Cmd` and
`MyApp::Cmd::Cmd::Cmd::Sub`, and runs the last one.

**The execute signature and the return value.** `execute($self, $args_ref,
$chain_ref)` — the remaining arguments and the chain of instantiated commands;
the chain's last element is `$self`. What the executed command returns is stored
as an **arrayref** under `command_execute_return_method_name`, and
`execute_return` reads it back: a command that returns a list gives an arrayref
of that list, one that returns nothing gives an empty arrayref, never `undef`.

**The creation chain.** `command_creation_chain_methods` lists constructors in
priority order; the first one the class provides is used. `new_with_options`
before `new` is what makes `MooX::Options` work. When no listed constructor
exists, the framework croaks `Can't find a creation method on …`.

**`execute_from_new`.** `1` (the importer's default) runs the command inside the
constructor; `0` — the role's own default — only prepares the object, and the
caller runs `execute` itself. With `0`, `execute_return` stays `undef` until the
command ran.

## The tester

`MooX::Cmd::Tester` exports `test_cmd` and `test_cmd_ok`. Both take
`(AppClass => \@argv)` and return a result object with the accessors `app`, `cmd`,
`stdout`, `stderr`, `output` (stdout and stderr merged), `error`, `execute_rv`
and `exit_code`. The tester runs the app without a child process: it patches
`*CORE::GLOBAL::exit` in a `BEGIN` block, so `exit` inside the command becomes a
throwable `MooX::Cmd::Tester::Exited` object instead of ending the test process.
The exit code is `0` on success, the thrown code for an `Exited`, otherwise `$!`
or `-1`.

`test_cmd_ok` additionally asserts that the command was found; `test_cmd` only
reports the error. The tester already runs assertions of its own (the app class,
the command name, the chain length, `command_chain_end`) — those show up in the
output of every test that uses it.

## The two optional roles

`MooX::Cmd::Role::AbbrevCmds` wraps `_build_command_commands` and rewrites the
command map so that every unambiguous prefix of a command name also works. It
**requires** `Text::Abbrev`, which the cpanfile lists as `recommends`.

`MooX::Cmd::Role::ConfigFromFile` extends the config prefixes of
`MooX::ConfigFromFile::Role` with the command names of the current chain, so
every command level gets its own section in the config file. It **requires**
`config_prefixes` and `MooX::ConfigFromFile`, also only `recommends`. Both are
optional: an application that does not use them must not need their dependency.

## Rough edges

1. **`_initialize_from_cmd` has a sloppy parameter list**: `command_execute_method_name`
   is listed twice among the private init params and `command_creation_method_name`
   is missing from it.

## Vocabulary

**App class** — the top-level class the user starts; composes the role.
**Command class** — a package below `command_base`; provides `execute`.
**Base** — the package prefix searched for command classes.
**Chain** — the instantiated classes from app to deepest command; the **deepest
command** is the only one whose `execute` runs.
**Creation chain** — the list of constructors tried in order.
**Plugin** — one entry of `command_commands`: a name → package pair; an
**abbreviation** is an unambiguous prefix that also selects a command.
**Config prefix** — a section name in the config file, one per chain level.

## Tests

`t/` holds eight files: `00-load.t` (the modules load), `01-simple.t` (the chain
and the execute contract), `02-moox-options.t` (the creation chain with
`MooX::Options`), `03-params.t`, `04-moox-configfromfile.t`, `05-text-abbrev.t`,
`06-abbrev-configfromfile.t` and `07-optional-deps.t`. The applications live under `t/lib/`, the
config fixtures under `etc/`. `prove -lr t/` runs the suite, `prove -lr xt/` the
author tests (perlcritic, pod coverage, changes, kwalitee, perltidy). The tests of
the optional roles skip when their dependency is absent; a skip is a hole in the
coverage, not a pass. CI runs both on Perl 5.30, 5.38 and 5.40.
