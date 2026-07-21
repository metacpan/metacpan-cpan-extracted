# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [OPTIONS](#options)
  * [Examples](#examples)
* [OPTION DETAILS](#option-details)
* [WHAT IS A DEPENDENCY?](#what-is-a-dependency)
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

    scandeps-static.pl [options] Module

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

# OPTIONS

    --add-version, -a        add version numbers to output
    --no-add-version         don't add version numbers to output
    --core                   include core modules (default)
    --no-core                don't include core modules
    --help, -h               help
    --include-require, -i    include 'require'd modules
    --no-include-require     don't include required modules
    --json, -j               output JSON formatted list
    --min-core-version, -m   minimum version of perl to consider core
    --raw, -r                raw output
    --separator, -s          separator for output (default: =>)
    --text, -t               output as text (default)
    --version, -v            version

## Examples

    scandeps-static.pl --no-core $(which scandeps-static.pl)

    scandeps-static.pl --json $(which scandeps-static.pl)

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

- --help, -h

    Show usage.

- --include-require, -i, --no-include-require

    Include statements that have `Require` in them but are not
    necessarily on the left edge of the code (possibly in tests).

    default: **--include-require**

- --json, -j

    Output the dependency list as a JSON encode string.

- --min-core-version, -m

    The minimum version of Perl that is considered core. Use this to
    consider some modules non-core if they did not appear until after the
    `min-core-version`.

    Core modules are identified using `Module::CoreList` and comparing
    the first release value of the module with the the minimum version of
    Perl considered as a baseline.  If you're using this module to
    identify the dependencies for your script **AND** you know you will be
    using a specific version of Perl, then set the `min-core-version` to
    that version of Perl.

    default: `5.8.9` (the `Module::ScanDeps::Static` constructor's
    `min_core_version` option defaults this to the running Perl's version
    instead)

- --separator, -s

    Use the specified sting to separate modules and version numbers in formatted output.

    default: ' => '

- --text, -t

    Output the dependency list as a simple text listing of module name and
    version in the same manner as `scandeps.pl`.

    default: **--text**

- --raw, -r

    Output the list with no quotes separated by a single whitespace
    character.

# WHAT IS A DEPENDENCY?

For the purposes of this module, dependencies are identified by
looking for Perl modules and other Perl artifacts declared using
`use`, `require`, `parent`, or `base`.

If the module contains a `require` statement, by default the
`require` must be flush up against the left edge of your script
without any whitespace between it and beginning of the line.  This is
the default behavior to avoid identifying `require` statements that
are embedded in `if` statements. If you want to include all of
the targets of `require` statements as dependencies, set the
`include-require` option to a true value.

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

## is\_core

    my $bool = $scanner->is_core($module);
    my $bool = $scanner->is_core("$module $version");

Returns true if `$module` is considered a core module. A module is
core when `Module::CoreList` reports its first release at or before
`min_core_version` (and, if it was later removed from core, only if it
was removed after that version).

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

This documentation refers to version 1.8.2

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
