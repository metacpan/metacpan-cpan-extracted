[![](https://github.com/CellBIS/mojo-collection-xs/workflows/linux/badge.svg)](https://github.com/CellBIS/mojo-collection-xs/actions) [![](https://github.com/CellBIS/mojo-collection-xs/workflows/macos/badge.svg)](https://github.com/CellBIS/mojo-collection-xs/actions) [![](https://github.com/CellBIS/mojo-collection-xs/workflows/windows/badge.svg)](https://github.com/CellBIS/mojo-collection-xs/actions)

**Mojo::Collection::XS** is a drop-in subclass of `Mojo::Collection` with hot
paths implemented in XS for better performance on large lists.

## Features

- Drop-in replacement for `Mojo::Collection` (inherits everything, overrides
  `each` and `while` to use the XS fast paths when a callback is provided)
- XS implementations of `each_fast`, `while_fast`, `while_pure_fast`,
  `map_fast`, `map_pure_fast`, and `grep_fast`
- Callbacks receive the element and a 1-based index; `$_` is set for
  `each_fast`, `while_fast`, `map_fast`, and `grep_fast`
- Callbacks must be code references (method-name strings are not supported)
- Convenience constructor helper `Mojo::Collection::XS::c(...)`

## Installation

```bash
perl Makefile.PL
make
make test
make install
```

Or install via cpanm:

```bash
curl -L https://cpanmin.us | perl - -M https://cpan.metacpan.org -n Mojo::Collection::XS
```

## Usage

```perl
use Mojo::Collection::XS qw/c/;

# Same API as Mojo::Collection
my $c = Mojo::Collection::XS->new(qw/foo bar baz/);

# Fast iteration (sets $_)
$c->each(sub ($e, $num) {
  say "$num: $e";
});

# Pure iteration without touching $_
$c->while_pure_fast(sub ($e, $num) {
  say "pure $num: $e";
});

# Mapping and filtering
my $upper   = $c->map_fast(sub ($e) { uc $e });
my $filtered = $c->grep_fast(sub ($e) { $e =~ /o/ });

# Convenience constructor
my $with_c = c(qw/foo bar/)->map_pure_fast(sub ($e) { "[$e]" });
```

## API quick reference

- `each` / `each_fast` — iterate with element and 1-based index (`$_` set)
- `while` / `while_fast` — like `each_fast` but returns same collection
- `while_pure_fast` — iterate without assigning to `$_`
- `map_fast` — list-context map into a new collection (`$_` set)
- `map_pure_fast` — scalar-context map into a new collection (does not set `$_`)
- `grep_fast` — filter into a new collection (`$_` set)
