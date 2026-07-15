# Syntax::Highlight::Basic

Basic syntax highlighting for Perl, Python, JavaScript, C, and more.

## Synopsis

```perl
use Syntax::Highlight::Basic;

my $shb = Syntax::Highlight::Basic->new();
my $html = $shb->highlight($code, 'perl', { format => 'pygments', wrap => 1 });
```

## Description

Syntax::Highlight::Basic is a pure Perl module that provides basic syntax
highlighting for source code. It supports multiple output formats:

- **Pygments** — HTML with Pygments-compatible CSS class names
- **HTML** — HTML with inline color styles
- **ANSI** — Terminal output with ANSI color codes

## Supported Languages

The module ships with `.shb` syntax files for over 80 languages, including:

Perl, Python, JavaScript, C, C++, Java, Ruby, Go, Rust, PHP, Shell (sh/bash/zsh),
SQL, HTML, CSS, YAML, JSON, XML, TypeScript, Swift, Kotlin, Scala, Lua, R, C#,
Dart, Haskell, Elm, Clojure, Elixir, Vim script, Make, Dockerfile, and many more.

See `share/syntax/languages.txt` for the full list.

## Installation

```bash
cpanm Syntax::Highlight::Basic
```

Or manually:

```bash
perl Makefile.PL
make
make test
make install
```

## Adding Custom Syntax Files

You can add syntax highlighting for languages not bundled with the module by
creating a `.shb` syntax definition file. See [`docs/syntax-format.md`](docs/syntax-format.md)
for the complete format reference.

```perl
my $shb = Syntax::Highlight::Basic->new(
    syntax_dirs => ['/path/to/my/syntax'],
);
my $html = $shb->highlight($code, 'mylang', { format => 'html' });
```

## Command-Line Tool

The distribution includes a `syntax-highlight-basic` CLI script:

```bash
# ANSI output to terminal
syntax-highlight-basic myscript.pl

# HTML output
syntax-highlight-basic --format html --language python app.py > app.html

# Pygments output with custom CSS class
syntax-highlight-basic --format pygments --wrap --css-class my-code script.js

# From stdin
echo 'print("hello")' | syntax-highlight-basic --language python --format ansi
```

See `syntax-highlight-basic --help` or `syntax-highlight-basic --man` for all options.

## Vim Syntax Converter

The `vim-syntax-to-shb` script converts Vim syntax files to `.shb` format:

```bash
vim-syntax-to-shb --output-dir ./my-syntax /usr/share/vim/vim91/syntax/ruby.vim
```

## License

This module is licensed under the same terms as Perl itself.