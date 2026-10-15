## Name

Perl::Minify - Minify Perl source with the `minify.pl` command or from Perl
code.

## Description

Perl::Minify shrinks Perl source by stripping comments and POD, collapsing
non-essential whitespace, and optionally shortening lexical variable names and
wrapping lines.

Most users want the `minify.pl` command, which is installed with this
distribution. Give it a file and it prints the minified code to STDOUT. The
module API is only needed when your own Perl program has to minify source.

## Installation

```sh
perl Makefile.PL
make
make test
make install
```

Requires Perl v5.16 or later and the CPAN module `PPI` (`cpan PPI`).

## Command Line Usage

```
minify.pl FILE [--width N] [--sub NAME]
```

Reads `FILE` and prints the minified code to STDOUT. The input file is never
modified, so redirect STDOUT to save the result.

```sh
# Minify a whole file
minify.pl script.pl > script.min.pl

# Minify and word-wrap to 80 columns
minify.pl script.pl --width 80 > script.min.pl

# Emit only one named subroutine
minify.pl script.pl --sub color > color.min.pl
```

### Arguments

- `FILE`

    Path to the Perl source file (required). If the file is missing or
    unreadable, a usage message is printed and the script exits with an error.

- `--width N`

    Word-wrap the output to at most `N` columns. Without it, the output is a
    single unwrapped line.

- `--sub NAME`

    Minify only the subroutine `NAME`. It is printed as bare source with its
    name kept. If no such sub exists, the error is written to STDERR and the
    script exits 1.

### Behavior

`minify.pl` always enables `shorten_vars`, and it always uses the default
stripping behavior (comments, POD, whitespace, and semicolons are removed).
Those settings and `optimize` are not available as command line flags. If you
need different options, use the module API below.

If the source cannot be parsed, the error is written to STDERR and the script
exits 1.

## Module API

Use the module when your own code needs to minify Perl source. Nothing is
exported by default; import the functions you need.

```perl
use Perl::Minify qw(minify minify_sub);

# Minify a whole file's worth of code
my $min = minify($source_str);

# With options (all keys optional)
my $min = minify($source_str, { shorten_vars => 1, wrap => 100 });

# Extract and minify a single sub
my $sub = minify_sub($source_str, 'color', { wrap => 80 });
```

### minify($code, \\%opts?)

Minifies a string of Perl source. Returns the minified string, or `undef` on
PPI parse failure.

### minify\_sub($code, $sub\_name, \\%opts?)

Locates a named subroutine and minifies it alone. Returns the sub as bare
source text (no surrounding `use` header or file-scope code), or `undef` on
parse failure or if no sub named `$sub_name` is found. The sub keeps its name
by default; pass `keep_name => 0` to emit an anonymous `sub { ... }` instead.
A bare sub that depends on file-scope lexicals or `state` variables will not
compile on its own.

### minify\_error()

Returns the last error message from a failed `minify` or `minify_sub` call
(also available as `$Perl::Minify::ERROR`). Returns an empty string if the
most recent call succeeded.

## Options

Options are passed to the module functions as a hashref. All are optional, and
unknown keys are ignored. Defaults:

```perl
strip_comments    1   remove # line comments
strip_pod         1   remove POD blocks
strip_whitespace  1   collapse non-significant whitespace
strip_semicolons  1   remove safe terminators before } block delimiters
shorten_vars      0   rename lexicals to short names ($c, $d, ...)
wrap              0   if >0, word-wrap output to <=N columns
keep_name         1   preserve the sub name in minify_sub output
escape_newlines   1   write LF/TAB/CR in strings as \n \t \r escapes
optimize          0   EXPERIMENTAL: fold simple Number +/-/* chains
                      (e.g. 2 + 3 + 4 becomes 9)
```

## Limitations

### `shorten_vars`

Renaming is skipped for symbols that appear inside string quotes, regex
literals, `s///e` replacement blocks, heredocs, and interpolations. Symbolic
references are not renamed. The renamer uses one global per-document map, so
two distinct `my` declarations with the same name (in different scopes) share
a single short name.

### `wrap`

An overlong statement with no break point that is outside a string/regex
literal is emitted as a single line that may exceed the requested width. This
never breaks a string literal mid-character.

## Author

Scottchiefbaker - https://github.com/scottchiefbaker/

## License

Same terms as Perl itself.
