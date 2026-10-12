# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
  * [Comparison to Other Scanners](#comparison-to-other-scanners)
* [OPTIONS](#options)
  * [Examples](#examples)
* [OPTION DETAILS](#option-details)
* [WHAT IS A DEPENDENCY?](#what-is-a-dependency)
  * [Dependency Tiers](#dependency-tiers)
  * [Structural Classification](#structural-classification)
  * [The `## scandeps:` Annotation](#the-##-scandeps-annotation)
  * [Conflicting Classifications](#conflicting-classifications)
  * [Self-Referential Modules](#self-referential-modules)
  * [Dynamic Module Loading](#dynamic-module-loading)
* [MINOR IMPROVEMENTS TO `perl.req`](#minor-improvements-to-perlreq)
* [CAVEATS](#caveats)
* [METHODS AND SUBROUTINES](#methods-and-subroutines)
  * [new](#new)
    * [Options](#options)
  * [get\_require](#get\require)
  * [get\_perlreq](#get\perlreq)
  * [parse](#parse)
  * [get\_dependencies](#get\dependencies)
  * [format\_text](#format\text)
  * [format\_json](#format\json)
  * [format\_cpanfile](#format\cpanfile)
  * [is\_core](#is\core)
  * [min\_core\_version](#min\core\version)
  * [get\_module\_version](#get\module\version)
  * [add\_require](#add\require)
  * [to\_rpm](#to\rpm)
* [VERSION](#version)
* [AUTHOR](#author)
* [LICENSE](#license)
# NAME

Module::ScanDeps::Static - a cleanup of rpmbuild's perl.req

# SYNOPSIS

    scandeps-static [options] Module

If "Module" is not provided, the script will read from STDIN.

    my $scanner = Module::ScanDeps::Static->new({ path => 'myfile.pl' });
    $scanner->parse;
    print $scanner->format_text;

# DESCRIPTION

This module is a mashup (and cleanup) of the `/usr/lib/rpm/perl.req`
file found in the rpm build tools library (see ["LICENSE"](#license)) below.

Successful identification of the required Perl modules for a module or
script is the subject of more than one project on CPAN. While each
approach has its pros and cons I have yet to find a better scanner
than the simple parser that Ken Estes wrote for the rpm build tools
package.

`Module::ScanDeps::Static` is a simple static scanner that
essentially uses regular expressions to locate `use`, `require`,
`parent`, and `base` in all of their disguised forms inside your
Perl script or module.  It's not perfect and the regular expressions
could use some polishing, but it works on a broad enough set of
situations as to be useful.

_Only direct dependencies are returned by this module. If you
want a recursive search for dependencies, use `find-requires`
included in this distribution._

## Comparison to Other Scanners

Two other CPAN scanners cover similar ground:
[Perl::PrereqScanner](https://metacpan.org/pod/Perl%3A%3APrereqScanner), built on [PPI](https://metacpan.org/pod/PPI), and
[Perl::PrereqScanner::NotQuiteLite](https://metacpan.org/pod/Perl%3A%3APrereqScanner%3A%3ANotQuiteLite) (here, "NQLite"), which uses its
own lexer. The comparison below reflects hands-on testing against
both, not just a reading of their documentation.

**Speed.** This module is regex/line-based rather than a true
tokenizer, and that's a deliberate trade-off, not an oversight - it's
the source of most of the speed difference. On a representative
414-line file, this module scans in roughly 1.7ms; NQLite takes
roughly 6ms; PPI-based `Perl::PrereqScanner` takes roughly 45ms.
PPI's own documentation acknowledges this cost directly, describing
itself as "painful... with very large files." The trade-off cuts the
other way too: a real tokenizer is structurally immune to a class of
edge case (an unbalanced brace inside a string or heredoc, for
example) that this module's regex approach can, in principle, still
be fooled by, even though no such failure has been found in testing
against real-world code.

**Dependency classification.** All three tools distinguish a hard
requirement from something merely conditional or optional, but this
module is alone in giving the developer an explicit way to state that
judgment rather than have it inferred. NQLite decides `recommends`
vs. `suggests` purely from code structure - specifically, whether
the call is a bare `eval` or one of two specific, by-name-recognized
CPAN modules ([Module::Runtime](https://metacpan.org/pod/Module%3A%3ARuntime) and [Class::Load](https://metacpan.org/pod/Class%3A%3ALoad)) - with no way
for a developer to say "no, that one's actually important" short of
restructuring their code to match what the scanner looks for. This
module instead classifies a guarded dependency as `suggests` by
default (or `recommends` project-wide via `eval_recommends`), and
lets a `## scandeps: recommends` or `## scandeps: suggests` comment
immediately after the guarding statement override that default
per-instance. Neither other tool has an equivalent escape hatch.

This module also warns - rather than silently picking a winner - when
a module is both a hard requirement in one place and merely
recommended or suggested in another, since that's a real contradiction
in the source worth surfacing to the developer, not something a
scanner should resolve on its own.

**Version numbers.** Both `Perl::PrereqScanner` and NQLite report
every dependency's version as a fixed `0` placeholder - not "unknown",
literally the string `0` regardless of what's actually installed or
required. This module performs a real version lookup (see
`--add-version`) and reports what it actually finds.

Reporting a version number or `0` both have their advantages and
disadvantages. Users of these scanners can always edit the output and
modify the version number requirements, however this scanner opted to
choose the currently installed version. This assumes you are
developing your module against a known environment, and the idea is
that while other versions of a module might work, the version in your
working environment is known to work with your module. Selecting
`0` means any version will do - but consider a module like
`List::Util` running under Perl 5.10. While `List::Util` has been in
core since 5.7.3, its feature list has grown significantly. You may be
using features that were not present in that version of `List::Util`.
Shipping with the minimum version of `List::Util` set to `0` is
almost certainly going to fail on earlier versions of Perl.

The true minimum - the exact release in which every feature your code
actually relies on first appeared - would in principle be the most
accurate answer. But determining that reliably would mean downgrading
each dependency in turn and re-running your test suite against every
prior release, which presumes you have test coverage specifically
exercising the features you're relying on, for every dependency you
use. That's not a reasonable expectation in practice - reporting the
currently installed version is a deliberate trade-off in favor of a
version **known** to work over one merely presumed to.

**Self-referential modules.** Scanning a whole project can turn a
sibling module into a false positive - file A's `use` of file B's
`package` isn't an external dependency at all. NQLite handles this
with `--private`, a manually maintained list of module names to
exclude. This module's `--filter` does the same job automatically,
by detecting `package` declarations across the batch being scanned,
at the cost of only working when the sibling file is actually part of
the same scan.

**What this module doesn't attempt.** NQLite can infer a minimum Perl
version from newer syntax (signatures, `say`, and similar) appearing
in the source without an explicit `use v5.x` declaration; this module
does not attempt that. NQLite also has an opt-in `CPAN::Common::Index`
integration that can deduplicate module names belonging to the same
distribution - deliberately not pursued here, since it requires a
network round-trip (or a locally maintained mirror) per module found
at scan time, in exchange for a purely cosmetic shortening of the
output that changes nothing about what actually gets installed.
Finally, no static scanner - this one included - can discover a
dependency loaded through a genuinely dynamic mechanism (a module name
computed at runtime and passed to something like [Module::Load](https://metacpan.org/pod/Module%3A%3ALoad));
that's a fundamental limit of static analysis, not a gap specific to
any one tool. See ["Dynamic Module Loading"](#dynamic-module-loading) below.

# OPTIONS

    --add-version, -a        add version numbers to output
    --no-add-version         don't add version numbers to output
    --core                   include core modules (default)
    --no-core                don't include core modules
    --cpanfile-file PATH     write a cpanfile combining all three tiers to PATH
    --eval-recommends        classify unannotated eval-wrapped deps as recommends, not suggests
    --file-list, -L PATH     scan a batch of files listed one per line in PATH
    --filter, -f             exclude modules that are this project's own packages
    --help, -h               help
    --include-require, -i    include 'require'd modules
    --no-include-require     don't include required modules
    --json, -j               output JSON formatted list
    --min-core-version, -m   minimum version of perl to consider core
    --path, -p PATH          file to scan (alternative to the positional argument)
    --raw, -r                raw output
    --recommend-require, -R  classify indented (non-eval) conditional requires as recommends
    --recommends-file PATH   write the recommends tier to PATH
    --requires-file PATH     write the requires tier to PATH
    --separator, -s          separator for output (default: =>)
    --suggests-file PATH     write the suggests tier to PATH
    --text, -t               output as text (default)
    --version, -v            version

## Examples

    scandeps-static --no-core lib/Some/Module.pm

    scandeps-static --json lib/Some/Module.pm

_Use the `find-requires` script included in this distribution to
recurse directories and create dependency files like `cpanfile`_.

# OPTION DETAILS

- --add-version, -a, --no-add-version

    Add the version number to the dependency list by inspecting the version of
    the module in your @INC path.

    default: **--add-version**

- --core, -c, --no-core

    Include or exclude core modules. See --min-core-version for
    description of how core modules are identified.

    default: **--core**

- --eval-recommends

    Controls how an `eval`-wrapped `require`/`use` is classified when
    it carries no explicit `## scandeps:` annotation (see
    ["Dependency Tiers"](#dependency-tiers) below). By default such a dependency is
    classified as `suggests`; setting this option flips the
    project-wide default to `recommends` instead. An explicit
    annotation always overrides this default regardless of its setting.

    default: **--no-eval-recommends** (unannotated evals classify as
    `suggests`)

- --file-list, -L PATH

    Scan a batch of files in a single process instead of one file per
    invocation. `PATH` is a file containing one source file path per
    line (relative or absolute); each listed file is scanned in turn and
    the results are aggregated. There is currently no way to supply the
    list via `STDIN` - `PATH` must be a real file.

    Batching this way avoids paying Perl's own process-startup cost and
    the `Module::CoreList` module-load cost (non-trivial - loading
    `Module::CoreList` alone is roughly an order of magnitude slower
    than a bare `perl` startup) once per file scanned, which matters a
    great deal once a project has more than a handful of source files.

    Because more than one JSON document cannot be safely concatenated
    into a single valid JSON result, `--json` is silently ignored
    whenever `--file-list` resolves to more than one file - output is
    always text in that case. If the list happens to contain exactly one
    file, `--json` is honored normally.

- --help, -h

    Show usage.

- --filter, -f

    Exclude modules from the output that are themselves `package`
    declarations found somewhere in the files being scanned. Useful with
    `--file-list` to keep a project's own sibling modules from being
    reported as external dependencies of each other.

    There is no single right default independent of context: a single
    file scanned on its own has no sibling in the batch to worry about,
    but when `--file-list` is in use, a same-batch sibling should never
    count as an external dependency of another file in the same batch.
    So this defaults to **off** for a single file and **on** whenever
    `--file-list` is given - but only when `--filter`/`--no-filter`
    isn't explicitly set; an explicit setting always wins over this
    context-dependent default, in either direction.

- --requires-file PATH
- --recommends-file PATH
- --suggests-file PATH

    Write the `requires`, `recommends`, or `suggests` tier
    respectively to `PATH`, in the same format `--text` would produce
    (regardless of whether `--json` or `--raw` is also in effect - each
    of these is always plain "module version" text, one per line). Any
    or all of the three may be given together; each is independent, and
    omitting all three changes nothing about existing STDOUT/JSON output.
    With `--file-list`, all files in the batch are scanned once and the
    three tiers are populated together from that single pass, rather than
    needing a separate scan per tier.

- --cpanfile-file PATH

    Write a single `cpanfile` to `PATH`, combining all three tiers in
    native [cpanfile](https://metacpan.org/pod/Module%3A%3ACPANfile) DSL syntax:

        requires 'Module::Name';
        requires 'Module::Name', 'X.YZ';
        recommends 'Module::Name', 'X.YZ';
        suggests 'Module::Name', 'X.YZ';

    A module's version is included only when one was actually detected
    (see `--add-version`) - otherwise the unversioned form is written,
    matching `cpanfile`'s own convention for "any version is acceptable".
    A minimum Perl version, if one was declared in the scanned source, is
    written the same way any other `requires` entry would be:
    `requires 'perl', 'X.YZ';` - this is standard `cpanfile` syntax, not
    a special case.

    This applies the same filtering as every other output (`--core` /
    `--no-core`, `--filter`) uniformly across all three tiers, and
    verified to round-trip correctly through [Module::CPANfile](https://metacpan.org/pod/Module%3A%3ACPANfile) itself.
    Independent of `--requires-file` / `--recommends-file` /
    `--suggests-file` - any combination of these four file-output options
    may be given together in a single scan.

- --include-require, -i, --no-include-require

    Include statements that have `Require` in them but are not
    necessarily on the left edge of the code (possibly in tests).

    default: **--include-require**

- --json, -j

    Output the dependency list as a JSON encode string. Silently ignored
    in favor of text output when combined with `--file-list` and more
    than one file is being scanned - see ["--file-list, -L PATH"](#file-list-l-path).

- --min-core-version, -m

    The minimum version of Perl that is considered core. Use this to
    consider some modules non-core if they did not appear until after the
    `min-core-version`.

    Core modules are identified using `Module::CoreList` and comparing
    the first release value of the module with the minimum version of
    Perl considered as a baseline.  If you're using this module to
    identify the dependencies for your script **AND** you know you will be
    using a specific version of Perl, then set the `min-core-version` to
    that version of Perl.

    Note: this only governs the "not yet in core as of my baseline" case.
    A module that was core at some point but has since been **removed**
    from core is always treated as non-core, regardless of
    `min-core-version` - there is no way to know which specific Perl an
    end user actually has installed, so the only safe answer once a
    module has ever been removed is to require it explicitly. See
    ["is\_core"](#is_core) for details.

    default: `5.8.9` (the `Module::ScanDeps::Static` constructor's
    `min_core_version` option defaults this to the running Perl's version
    instead)

- --path, -p PATH

    Path to the file to scan. Equivalent to supplying the path as a bare
    positional argument; provided as a named option for clarity in
    scripts that build up the command line programmatically. Ignored if
    `--file-list` is also given.

- --separator, -s

    Use the specified string to separate modules and version numbers in formatted output.

    default: ' => '

- --text, -t

    Output the dependency list as a simple text listing of module name and
    version in the same manner as `scandeps.pl`.

    default: **--text**

- --raw, -r

    Output the list with no quotes separated by a single whitespace
    character.

- --recommend-require

    By default, an indented (not left-flushed) `require` statement that
    is not wrapped in `eval` is either treated as a hard requirement or
    dropped entirely, depending on `--include-require` - see
    ["--include-require, -i, --no-include-require"](#include-require-i-no-include-require). Setting this option
    instead routes it to the `recommends` tier (see
    ["Dependency Tiers"](#dependency-tiers)), regardless of `--include-require`'s setting.
    Off by default - every existing case behaves exactly as it did before
    this option existed.

    default: **--no-recommend-require**

# WHAT IS A DEPENDENCY?

For the purposes of this module, dependencies are identified by
looking for Perl modules and other Perl artifacts declared using
`use`, `require`, `parent`, or `base`. The script will also
consider Moo/Role::Tiny modules included using `with`, and Moose
inheritance declared using `extends` - both are treated identically
to `use parent`/`use base`.

If the module contains a `require` statement, by default the
`require` must be flush up against the left edge of your script
without any whitespace between it and beginning of the line.  This is
the default behavior to avoid identifying `require` statements that
are embedded in `if` statements. If you want to include all of
the targets of `require` statements as dependencies, set the
`include-require` option to a true value.

## Dependency Tiers

Every dependency found is classified into one of three tiers,
matching the `requires`/`recommends`/`suggests` relationship types
defined by [CPAN::Meta::Spec](https://metacpan.org/pod/CPAN%3A%3AMeta%3A%3ASpec):

- requires

    A bare, unconditional `use` or `require`, or a `with`/`extends`/
    `parent`/`base` declaration. Nothing in the surrounding code
    suggests the author considered this module might be absent.

- recommends

    A dependency the author explicitly guarded against being absent (see
    ["Structural Classification"](#structural-classification) below), where the author's own
    annotation or this module's default judges the guard to matter more
    than a mere enhancement - see ["The `## scandeps:` Annotation"](#the-scandeps-annotation).

- suggests

    The weaker of the two soft tiers - a guarded dependency judged to be
    a genuine enhancement rather than something most users would need.

This module makes **no attempt** to infer which of `recommends` or
`suggests` is correct by analyzing what a guarded dependency's
failure path actually does (for example, whether it `die`s or
degrades gracefully). That was a deliberate decision, not an
oversight: whether a dependency is merely nice-to-have or genuinely
important is a judgment about a project's own design, not a fact
recoverable from code structure - the same code shape (`eval {
require Foo }`) is written identically by an author who considers
`Foo` essential and one who considers it optional. Guessing at that
judgment and presenting the guess as if it were derived from parsing
would be dishonest about what static analysis can actually know. Use
the annotation below to state it explicitly instead.

## Structural Classification

Only a genuinely unconditional `use`/`require` is ever classified
as `requires`. Anything the author has structurally guarded is
pulled into one of the soft tiers:

- `eval { require/use Foo }` or `eval "require/use Foo"`, in
any form - single-line, multi-line, with or without a trailing
`or die`/`or do { }` - is classified as `suggests` by default, or
`recommends` if `--eval-recommends` is set (see
["--eval-recommends"](#eval-recommends)). Either default can be overridden per-instance
with an explicit annotation - see below.
- An indented (not left-flushed), non-`eval` `require` - for
example inside a bare `if` block - is treated as a hard requirement
by default (or dropped entirely if `--include-require` is off), the
same as it always has been. Set `--recommend-require` to instead
route these to `recommends`. See
["--recommend-require"](#recommend-require).

## The `## scandeps:` Annotation

Because the `recommends` vs. `suggests` distinction is a judgment
call this module deliberately does not try to infer (see
["Dependency Tiers"](#dependency-tiers)), an author can state that judgment explicitly
with a comment:

    eval { require Foo::Bar; };  ## scandeps: recommends

    eval { require Foo::Bar; 1; } or die $@;  ## scandeps: suggests

    eval {
        require Foo::Bar;
        1;
    } or do {
        warn "Foo::Bar unavailable, continuing without it\n";
    };  ## scandeps: recommends

The annotation must appear immediately after the semicolon that ends
the whole statement - not the eval block's own closing brace, but
wherever the statement as a whole actually terminates, which may be
after a trailing `or die ...;` or `or do { ... };`. An explicit
annotation always overrides both this module's structural default and
the `--eval-recommends` setting.

This annotation is only recognized on the brace form of `eval`
(`eval { ... }`). It is not supported on the string form
(`eval "..."`) - anyone still writing string `eval` for this
purpose is not expected to participate in this feature.

## Conflicting Classifications

A single module can legitimately be a hard requirement in one file
and guarded in another - both facts can be true of the same project
at once. When that happens, this module does not silently pick a
winner: it emits a warning to `STDERR` naming the conflicting
module, and leaves `require`, `recommends`, and `suggests` exactly
as found. Resolving the contradiction belongs in the project's own
source, not in this tool - either the guarded usage no longer needs
to hedge, since the module is guaranteed to be present anyway because
of the other, unconditional usage, or the unconditional usage should
really be conditional too.

The same warning fires if a module appears in both `recommends` and
`suggests` at once.

## Self-Referential Modules

When scanning a whole project (typically via `--file-list`), a
module in one file may `use` a sibling module declared with
`package` in another file in the same project - not a real external
dependency at all. `--filter` excludes any module name that appears
anywhere in the batch as a `package` declaration; see
["--filter, -f"](#filter-f) for its (context-dependent) default.

## Dynamic Module Loading

This module performs _static_ analysis: it reads source as text and
looks for recognizable patterns. It cannot execute your code, and so
cannot know the value of a variable at runtime. A module loaded via a
computed name - for example `Module::Load::load($module)` where
`$module` is a variable - is invisible to this scanner and will
never appear in `require`, `recommends`, or `suggests`, no matter
how the code is structured.

This is a real and legitimate use case for modules like
[Module::Load](https://metacpan.org/pod/Module%3A%3ALoad), [Module::Runtime](https://metacpan.org/pod/Module%3A%3ARuntime), and [Class::Load](https://metacpan.org/pod/Class%3A%3ALoad): loading a
plugin or driver whose name genuinely isn't known until the program
runs. For that use case, invisibility to any static scanner is an
unavoidable trade-off, not a defect in this module.

It becomes an antipattern, though, when one of these modules is
called with a name that _is_ known at write time:

    Module::Load::load('Term::ANSIColor');

The module name here is a literal string, not runtime data - a plain

    eval { require Term::ANSIColor; };

would behave identically at runtime, while remaining visible to this
scanner and annotatable with `## scandeps:`. Reach for
`Module::Load` and similar modules only when the module name is
genuinely computed at runtime - for loading plugins or other modules
that are already known to be part of your project's own architecture
\- not as a general-purpose substitute for `require`.

Do not expect this scanner to understand dynamic module loading. If a
project genuinely depends on a module that can only be discovered at
runtime, that dependency needs to be declared by hand (for example, in
a `cpanfile` or `buildspec.yml`) - this module cannot discover it.

# MINOR IMPROVEMENTS TO `perl.req`

- Allow detection of `require` not at beginning of line.

    Use the `--include-require` to expand the definition of a dependency
    to any module or Perl script that is the argument of the `require`
    statement.

- Allow detection of the `parent`, `base` statements use of curly braces.

    The regular expression and algorithm in `parse` has been enhanced to
    detect the use of curly braces in `use` or `parent` declarations.

- Exclude core modules.

    Use the `--no-core` option to ignore core modules.

- Add the current version of an installed module if the version
is not explicitly specified.

# CAVEATS

There are still many situations (including multi-line statements) that
may prevent this module from properly identifying a dependency. As
always, YMMV.

# METHODS AND SUBROUTINES

## new

    new(options)

Returns a `Module::ScanDeps::Static` object.

### Options

- path

    Path to a file to scan. When set, `parse()` opens this file and reads
    from it.

    default: **none** (if neither `path` nor `handle` is given, `parse()`
    reads from `STDIN`)

- handle

    An open filehandle (or any `IO::Handle`-like object) to read from
    instead of a file. Ignored when `path` is set.

    default: **none**

- core

    Boolean value that determines whether to include core modules as part
    of the dependency listing.

    default: **true**

- include\_require

    Boolean value that determines whether to consider `require`
    statements that are not left-aligned to be considered dependencies.

    default: **false** (the `scandeps-static.pl` CLI defaults this to true)

- add\_version

    Boolean value that determines whether to include the version of the
    module currently installed if there is no version specified.

    default: **true**

- min\_core\_version

    The minimum version of Perl which will be used to decide if a module
    is included in Perl core. See `is_core` and the `--min-core-version`
    option for details.

    default: **the running Perl's version** (`$PERL_VERSION`). The
    `scandeps-static.pl` CLI defaults this to `5.8.9`.

- json

    Boolean value that indicates output should be in JSON format.

    default: **false**

- text

    Boolean value that indicates output should be in the same format as
    `scandeps.pl`. This is the default output format for `get_dependencies`
    when neither `json` nor `raw` is set.

    default: **true**

- raw

    Boolean value that indicates output should be in raw format
    (module version).

    default: **false**

- separator

    Character string used to separate the module name from the version in
    text output.

    default: **none** from the constructor; `format_text` falls back to a
    single space. The `scandeps-static.pl` CLI sets this to ` =` >.

## get\_require

After calling the `parse()` method, call this method to retrieve a
hash containing the dependencies and (potentially) their version
numbers.

    $scanner->parse;
    my $requires = $scanner->get_require;

## get\_perlreq

Returns a hash ref of Perl version requirements discovered while
parsing (keyed by `'perl'`). Populated for `use 5.010;` /
`require 5.010;` style statements. Pair with `get_require`.

    $scanner->parse;
    my $perlreq = $scanner->get_perlreq;  # { perl => '5.010', ... }

## parse

- parse a file

        my @dependencies = Module::ScanDeps::Static->new({ path => $path })->parse;

- parse from file handle

        my @dependencies = Module::ScanDeps::Static->new({ handle => $path })->parse;

- parse STDIN

        my @dependencies = Module::ScanDeps::Static->new->parse(\$script);

- parse string

        my @dependencies = parse(\$script);

Scans the specified input and returns a list of Perl module dependencies.

Use the `get_dependencies` method to retrieve the dependencies as a
formatted string or as a list of dependency objects. Use the
`get_require` and `get_perlreq` methods to retrieve dependencies as
a list of hash refs.

    my $scanner = Module::ScanDeps::Static->new({ path => 'my-script.pl' });
    my @dependencies = $scanner->parse;

## get\_dependencies

Returns a formatted list of dependencies or a list of dependency objects.

As JSON:

    print $scanner->get_dependencies( format => 'json' )

    [
      {
       "name" : "Module::Name",
       "version" : "version"
      },
      ...
    ]

..or as text:

    print $scanner->get_dependencies( format => 'text' )

    Module::Name => version
    ...

In scalar context in the absence of an argument returns a JSON
formatted string. In list context will return a list of hashes that
contain the keys "name" and "version" for each dependency.

Note: this context-sensitivity only applies when none of `json`,
`text`, or `raw` is set (or when `format => 'json'` /
`format => 'text'` is passed explicitly). If the `json` option is
true, `get_dependencies` always returns a scalar JSON string, even
when called in list context.

## format\_text

    $scanner->parse;
    print $scanner->format_text;

Returns the dependency list as a formatted text string, one module per
line, honoring the `separator` and `raw` options. Core modules are
omitted when `core` is false.

## format\_json

    my $json     = $scanner->format_json;   # scalar context
    my @requires = $scanner->format_json;   # list context

In scalar context returns a pretty-printed JSON string; in list context
returns a list of hash refs of the form `{ name => ..., version =>
... }`. Core modules are omitted when `core` is false. Any arguments
are treated as a seed list and prepended to the results.

## format\_cpanfile

    $scanner->parse;
    print $scanner->format_cpanfile;

Returns a single `cpanfile` (see [Module::CPANfile](https://metacpan.org/pod/Module%3A%3ACPANfile)) combining all
three tiers, using native `requires`/`recommends`/`suggests` DSL
syntax. Versions are included only where actually detected (see
`add_version`); otherwise the unversioned form is written. Applies
the same `core`/`filter` filtering as `format_json`, since it's
built on top of it rather than duplicating that logic.

## is\_core

    my $bool = $scanner->is_core($module);
    my $bool = $scanner->is_core("$module $version");

Returns true if `$module` is considered core. A module is core when
`Module::CoreList` reports its first release at or before
`min_core_version` **and** the module has never been removed from
core at any point in its history.

A module that was core at some earlier Perl but has since been
removed is always treated as non-core, regardless of how
`min_core_version` compares to the version it was removed at. There
is no way to know which Perl an end user actually has installed - a
version comparison against a single reference point only protects
against removals that happen to fall on one particular side of it, so
the only safe answer once a module has ever been removed is to always
require it explicitly.

## min\_core\_version

    my $numified = $scanner->min_core_version;

Returns the `min_core_version` option numified via `version` (e.g.
`5.008009`) for comparison inside `is_core`. Note this is distinct
from the generated `get_min_core_version` accessor, which returns the
raw stored value.

## get\_module\_version

    my $info = $scanner->get_module_version($module, @include_path);

Returns a hash ref describing `$module`:

    { module => ..., version => ..., path => ..., file => ... }

Searches `@include_path` (defaulting to `@INC`) for the module and
extracts its version via `ExtUtils::MM-`parse\_version>. If `$module`
already carries a version (`"Foo::Bar 1.23"`), that version is returned
without a filesystem lookup.

## add\_require

    $scanner->add_require($module);
    $scanner->add_require($module, $version);

Registers `$module` as a dependency, optionally with `$version`. When
no version is supplied and the `add_version` option is true, the
installed version is looked up. Retains the higher of two versions if
the module is added more than once. Returns `$self`.

## to\_rpm

    my $deps = $scanner->to_rpm;

Returns the dependency list as RPM-style requirement expressions
(`perl(Module) >= version`, plus `perl >= version` for any
Perl version requirement). Core modules are omitted when `core` is
false.

# VERSION

This documentation refers to version 1.9.5

# AUTHOR

This module is largely a lift and drop of Ken Este's `perl.req` script
lifted from rpm build tools.

Ken Estes Mail.com kestes@staff.mail.com

The method `parse` is a cleaned up version of `process_file` from the
same script.

Rob Lauer - <bigfoot@cpan.org>

# LICENSE

This statement was lifted directly from `perl.req`...

> _The entire code base may be distributed under the terms of the
> GNU General Public License (GPL), which appears immediately below.
> Alternatively, all of the source code in the lib subdirectory of the
> RPM source code distribution as well as any code derived from that
> code may instead be distributed under the GNU Library General Public
> License (LGPL), at the choice of the distributor. The complete text of
> the LGPL appears at the bottom of this file._
>
> _This alternatively is allowed to enable applications to be linked
> against the RPM library (commonly called librpm) without forcing
> such applications to be distributed under the GPL._
>
> _Any questions regarding the licensing of RPM should be addressed to
> Erik Troan &lt;ewt@redhat.com_.>
