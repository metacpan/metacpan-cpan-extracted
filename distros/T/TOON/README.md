# TOON

A small starter CPAN-style distribution for a `TOON` module with a familiar
interface inspired by `JSON`.

## Status

This is an intentionally basic implementation. It is suitable as a starting
point for further development, but it is **not** yet a complete or authoritative
implementation of any external TOON specification.

## Supported syntax

- `null`
- `true` / `false`
- numbers
- quoted strings with JSON-style escapes
- arrays: `[1, 2, 3]`
- objects: `{name: "Dave", count: 3}`
- quoted object keys when needed

## Example

```perl
use TOON qw(encode_toon decode_toon);

my $text = encode_toon({
  name   => 'Dave',
  active => 1,
  tags   => ['perl', 'toon'],
}, canonical => 1);

my $data = decode_toon($text);
```

## OO interface

```perl
use TOON;

my $toon = TOON->new->pretty->canonical;
my $text = $toon->encode({ answer => 42 });
my $data = $toon->decode($text);
```
