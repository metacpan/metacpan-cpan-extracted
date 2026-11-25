# MooX-Cmd House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

An easy Moo-style way to build command-organized CLI apps. The module map, the import options
and the command contract live in skill `moox-cmd-core`.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `moox-cmd-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `moox-cmd-release-manager` |
| Read-only research, audit, gap analysis | `moox-cmd-worker` ("read-only, change nothing") |

Behavior-relevant = `lib/`, the tests, the tester, the roles. README and `Changes` wording
are not.

## Release

`prove -lr xt/` is fine anytime too, alongside the shared CPAN commands.

## The framework contract is the product — don't regress it silently

This distribution *is* the contract that an application builds on: what `use MooX::Cmd`
composes, the import options and the attributes they override, the `execute` signature, the
rule that only the deepest command of the chain executes, the discovery of command classes
below `command_base`, and the storage of the execute return value. A change to any of them is
visible in every application that uses the framework: it needs a `Changes` entry and a test
that pins it. The documented behaviour is the contract — no fallbacks for features that do
not exist. The optional roles belong to their external dependency — a `recommends`
dependency loaded at compile time is a bug. Full contract table: skill `moox-cmd-core`.

## Perl specifics — reference, don't restate

Perl conventions live in the force-loaded skills; the module map, the import options and the
command contract live in skill `moox-cmd-core`.
