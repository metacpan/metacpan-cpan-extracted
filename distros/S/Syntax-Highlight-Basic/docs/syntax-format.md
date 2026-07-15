# .shb Syntax File Format

## 1. Introduction

`.shb` files define syntax highlighting rules for a programming language. They are
simple text files that describe keywords, patterns, and regions (like strings and
comments) using a lightweight format understood by `Syntax::Highlight::Basic::Parser`.

The module ships with `.shb` files for many languages in `share/syntax/` (installed
via `File::ShareDir`). You can also create your own `.shb` files for languages not
bundled with the module, or override the built-in ones.

To use custom syntax files, pass the directory path to the parser:

```perl
my $parser = Syntax::Highlight::Basic::Parser->new(
    language    => 'mylang',
    syntax_dirs => ['/path/to/my/syntax'],
);
```

User-supplied directories are searched **before** the built-in ones, so you can
override any bundled syntax file by placing a file with the same name in your
custom directory.

## 2. File Naming

The filename must be `LANGUAGE.shb` where `LANGUAGE` is the lowercase language name:

- `perl.shb` — Perl
- `python.shb` — Python
- `javascript.shb` — JavaScript
- `mylang.shb` — a custom language

The language name in the filename must match what you pass to the parser:

```perl
Parser->new(language => 'perl')     # loads perl.shb
Parser->new(language => 'python')   # loads python.shb
```

## 3. File Structure Overview

A `.shb` file consists of header lines followed by sections. Comments start with `#`
and blank lines are ignored.

```shb
# This is a comment — ignored by the parser
# Blank lines are also ignored

# Required header lines (must appear before any sections)
language: mylang
extensions: ml myl

# Sections define syntax elements
[keyword:Statement]
if else while for return

[match:Comment]
pattern: #.*$

[region:String]
start: "
end: "
escape: \
```

## 4. Header Lines

### `language: NAME`

The canonical name of the language (lowercase, no spaces). Must match the filename.

```
language: javascript
```

### `extensions: EXT1 EXT2 ...`

Space-separated list of file extensions (without the dot) associated with this
language. Used by the CLI tool to auto-detect the language from a filename.

```
extensions: js mjs cjs
```

### `case: ignore` (optional)

If present, keyword matching is case-insensitive.

```
case: ignore
```

## 5. Section Types

### 5.1 Keyword Sections — `[keyword:GROUP]`

Used for exact word matches. The parser checks word boundaries automatically,
so a keyword `for` will match the word `for` but not `before` or `forth`.

`GROUP` is a Vim highlight group name (see Section 7 for the full list).
Keywords are listed on one or more lines after the section header, separated
by spaces. Keywords are case-sensitive by default.

```shb
# Keywords that map to the Statement highlight group
[keyword:Statement]
if else elsif unless while for foreach do until continue
return last next redo goto break

# Keywords that map to StorageClass (a sub-group of Type)
[keyword:StorageClass]
my our local state

# Keywords that map to Include (a sub-group of PreProc)
[keyword:Include]
use no require import
```

**What the parser produces:**

When the parser encounters `if` in source code, it matches the keyword in
`[keyword:Statement]` and produces:

```perl
{ class => 'Statement', sub_group => undef, text => 'if' }
```

When it encounters `my`, it matches `[keyword:StorageClass]`. Since
`StorageClass` is a sub-group of `Type`, the token becomes:

```perl
{ class => 'Type', sub_group => 'StorageClass', text => 'my' }
```

### 5.2 Match Sections — `[match:GROUP]`

Used for patterns that match a single token on one line. `GROUP` is a Vim
highlight group name. The `pattern:` line contains a Perl regular expression
(no delimiters, no flags). The parser matches at the current position; the
longest match wins.

```shb
# Single-line comments starting with #
[match:Comment]
pattern: #.*$

# Integer and floating-point numbers
[match:Number]
pattern: \b(?:0x[0-9a-fA-F]+|0b[01]+|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\b

# Variable names starting with $ @ or %
[match:Identifier]
pattern: [\$\@\%]\w+

# Operators and punctuation
[match:Operator]
pattern: [+\-*/%=<>!&|^~]+
```

**Important notes:**

- The pattern must be a valid Perl regex — test it with `perl -e 'qr/YOUR_PATTERN/'`
- Do **NOT** include regex delimiters: `pattern: foo` is correct, `pattern: /foo/` is wrong
- Do **NOT** include flags — the parser adds them automatically if `case: ignore` is set
- Use `(?:...)` for grouping instead of `(...)` to avoid unintended capturing
- The pattern is matched at the current position, so `^` means start-of-line only if
  the parser is at position 0; use `\b` for word boundaries

### 5.3 Region Sections — `[region:GROUP]`

Used for constructs that span from a start delimiter to an end delimiter.
Regions can span multiple lines (e.g., block comments, multi-line strings).
`GROUP` is a Vim highlight group name.

Required: `start:` and `end:` lines.
Optional: `escape:` line (a single character that escapes the end delimiter).

```shb
# Double-quoted strings (with backslash escaping)
[region:String]
start: "
end: "
escape: \

# Single-quoted strings (with backslash escaping)
[region:String]
start: '
end: '
escape: \

# C-style block comments
[region:Comment]
start: /*
end: */

# Python triple-quoted strings
[region:String]
start: """
end: """

[region:String]
start: '''
end: '''
```

**Important notes:**

- The `start:` and `end:` values are literal strings, not regex patterns
- The `escape:` value is a single character; when the parser sees `escape + end`,
  it does NOT treat it as the end of the region (e.g., `\"` inside `"..."`)
- Multiple `[region:GROUP]` sections with the same GROUP are allowed (e.g., both
  single and double-quoted strings map to `String`)
- Regions take priority over match patterns and keywords
- The escape character itself can be escaped (e.g., `\\` is handled automatically)

## 6. Complete Example: SimpleLang

Here is a complete, working `.shb` file for a fictional language called "simplelang":

```shb
# Syntax file for SimpleLang
language: simplelang
extensions: sl

# Control flow keywords
[keyword:Conditional]
if else elsif

[keyword:Repeat]
while for

[keyword:Statement]
return break continue

# Variable declarations
[keyword:StorageClass]
var let const

# Built-in functions
[keyword:Function]
print println input

# Single-line comments
[match:Comment]
pattern: //.*$

# Numbers (integer and float)
[match:Number]
pattern: \b\d+(?:\.\d+)?\b

# Identifiers (variable names)
[match:Identifier]
pattern: \b[a-zA-Z_]\w*\b

# Double-quoted strings
[region:String]
start: "
end: "
escape: \

# Single-quoted strings
[region:String]
start: '
end: '
escape: \

# Block comments
[region:Comment]
start: /*
end: */
```

Given this input:

```
// greet the user
var name = "Alice"
if name == "Alice" {
    println("Hello, " + name)
}
```

The parser produces (abbreviated):

```
Line 1: [{ class=>"Comment", text=>"// greet the user" }]
Line 2: [{ class=>"Type", sub_group=>"StorageClass", text=>"var" },
         { class=>"whitespace", text=>" " },
         { class=>"Identifier", text=>"name" },
         { class=>"whitespace", text=>" " },
         { class=>"text", text=>"=" },
         { class=>"whitespace", text=>" " },
         { class=>"Constant", sub_group=>"String", text=>'"Alice"' }]
Line 3: [{ class=>"Statement", sub_group=>"Conditional", text=>"if" },
         { class=>"whitespace", text=>" " },
         { class=>"Identifier", text=>"name" },
         ...]
...
```

## 7. Highlight Group Names

### Parent Groups

Use these when no sub-group applies:

| Group Name  | Typical Use                    |
|-------------|--------------------------------|
| `Comment`   | Comments                       |
| `Constant`  | Literal values (strings, numbers) |
| `Identifier`| Variable names, identifiers    |
| `Statement` | Keywords, control flow         |
| `PreProc`   | Preprocessor directives        |
| `Type`      | Type names, declarations       |
| `Special`   | Special characters, delimiters |
| `Underlined`| Underlined text                |
| `Error`     | Error markers                  |
| `Todo`      | TODO/FIXME markers             |

### Sub-Groups

More specific groups; automatically mapped to their parent group:

| Sub-Group        | Parent     | Typical Use                  |
|------------------|------------|------------------------------|
| `String`         | Constant   | String literals              |
| `Character`      | Constant   | Character literals           |
| `Number`         | Constant   | Numeric literals             |
| `Boolean`        | Constant   | Boolean literals (true/false)|
| `Float`          | Constant   | Floating-point literals      |
| `Function`       | Identifier | Function names               |
| `Conditional`    | Statement  | if/else/switch               |
| `Repeat`         | Statement  | for/while/loop               |
| `Label`          | Statement  | Labels                       |
| `Operator`       | Statement  | Operators                    |
| `Keyword`        | Statement  | General keywords             |
| `Exception`      | Statement  | try/catch/throw              |
| `Include`        | PreProc    | import/include/use           |
| `Define`         | PreProc    | #define, macros              |
| `Macro`          | PreProc    | Macro invocations            |
| `PreCondit`      | PreProc    | #ifdef, #if                  |
| `StorageClass`   | Type       | my/var/let/const             |
| `Structure`      | Type       | struct/class/enum            |
| `Typedef`        | Type       | typedef                      |
| `Tag`            | Special    | HTML/XML tags                |
| `SpecialChar`    | Special    | Escape sequences             |
| `Delimiter`      | Special    | Brackets, punctuation        |
| `SpecialComment` | Special    | Special comment markers      |
| `Debug`          | Special    | Debug markers                |

## 8. Tips and Common Patterns

### Tip 1: Test your regex patterns

```bash
perl -e 'qr/YOUR_PATTERN_HERE/ or die "invalid"'
```

### Tip 2: Order matters for match sections

The parser tries all match patterns and uses the **longest** match. If two
patterns could match at the same position, the longer match wins. Put more
specific patterns before more general ones.

### Tip 3: Keywords vs. match patterns for identifiers

Use `[keyword:GROUP]` for a fixed list of words. Use `[match:GROUP]` with a
pattern like `\b[a-zA-Z_]\w*\b` only if you want to highlight **all** identifiers.
Combining both is fine — keywords take priority over general identifier patterns
at word boundaries.

### Tip 4: Handling escape sequences in strings

The `escape:` option handles a single escape character. For languages where the
escape character can be escaped (e.g., `\\`), the parser handles this
automatically: `escape: \` means `\\` skips the next character, and `\"` does
NOT end the string.

### Tip 5: Use the converter for a starting point

If the language has a Vim syntax file, use `vim-syntax-to-shb` to generate an
initial `.shb` file, then review and edit it:

```bash
vim-syntax-to-shb --output-dir /my/syntax /usr/share/vim/vim91/syntax/ruby.vim
```

### Tip 6: Verifying your syntax file

After writing a `.shb` file, test it:

```bash
perl -MSyntax::Highlight::Basic::Parser -e '
my $p = Syntax::Highlight::Basic::Parser->new(
    language    => "mylang",
    syntax_dirs => ["/path/to/my/syntax"]
);
use Data::Dumper;
print Dumper($p->parse("your test code here"));
'
```

## 9. Troubleshooting

**"No syntax file found for language 'X'"**
Check that the filename is `x.shb` (lowercase) and that the directory is
passed via `syntax_dirs`.

**Keywords not recognized**
Check for typos; keywords are case-sensitive by default. Add `case: ignore`
if you need case-insensitive matching.

**Regex pattern causes errors**
Test with `perl -e 'qr/PATTERN/'`. Avoid capturing groups `(...)` —
use `(?:...)` instead. Ensure the pattern does not contain regex delimiters.

**Region never ends**
Check that the `end:` string exactly matches what appears in the source.
Remember it is a literal string, not a regex. Regions that start but never
end on a line will extend to the end of that line.
