[![](https://github.com/CellBIS/mojo-collection-xs/workflows/linux/badge.svg)](https://github.com/CellBIS/mojo-collection-xs/actions) [![](https://github.com/CellBIS/mojo-collection-xs/workflows/macos/badge.svg)](https://github.com/CellBIS/mojo-collection-xs/actions) [![](https://github.com/CellBIS/mojo-collection-xs/workflows/windows/badge.svg)](https://github.com/CellBIS/mojo-collection-xs/actions)

**Mojo::Collection::XS** is a drop-in subclass of `Mojo::Collection` with hot
paths implemented in XS for better performance on large lists. The fast
helpers keep the same semantics as their `Mojo::Collection` counterparts while
being measurably quicker; the ultra helpers shave even more overhead by
avoiding `$_` altogether.

## Features

- Drop-in replacement for `Mojo::Collection` with additional XS helpers
- XS implementations of `each_fast`, `while_fast`, `while_ultra`,
  `map_fast`, `map_ultra`, and `grep_fast`
- Callbacks match `Mojo::Collection` semantics: `each`/`while` receive the
  element and a 1-based index; `map`/`grep` receive only the element. `$_` is
  set for `each_fast`, `while_fast`, `map_fast`, and `grep_fast`
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

# Fast iteration (aliases $_)
$c->while_fast(sub ($e, $num) {
  say "$num: $_";
});

# Ultra-fast iteration without touching $_
$c->while_ultra(sub ($e, $num) {
  say "pure $num: $e";
});

# Mapping and filtering
my $upper    = $c->map_fast(sub ($e) { uc $e });
my $filtered = $c->grep_fast(sub ($e) { $e =~ /o/ });

# Convenience constructor
my $with_c = c(qw/foo bar/)->map_ultra(sub ($e) { "[$e]" });

# Combine fast helpers
$c->map_fast(sub ($e) { uc $e })->while_fast(sub ($e, $num) {
  say "fast [$num] $e / $_";
});

$c->map_ultra(sub ($e) { length $e })->while_ultra(sub ($len, $num) {
  say "ultra [$num] len=$len";
});
```

### Callback cost matters

These helpers still call your Perl callbacks for every element. They cut some
stack and aliasing overhead, but the callback body dominates runtime. In code
that does real work (DB access, JSON, hash/object ops), `while_ultra` and
`map_ultra` can outperform their Mojo equivalents by avoiding `$_` and doing
less stack setup. In micro-benchmarks with trivial callbacks, the gap may be
small or even inverted because `call_sv` overhead overwhelms the savings.

## API quick reference

- `each` / `each_fast` — iterate with element and 1-based index (`$_` set)
- `while_fast` — like `each_fast` but returns same collection
- `while_ultra` — iterate without assigning to `$_`
- `map_fast` — list-context map into a new collection (`$_` set; args match `Mojo::Collection::map`)
- `map_ultra` — scalar-context map into a new collection (does not set `$_`)
- `grep_fast` — filter into a new collection (`$_` set; args match `Mojo::Collection::grep`)
