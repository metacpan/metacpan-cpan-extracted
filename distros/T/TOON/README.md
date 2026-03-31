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
- numbers (integer and floating-point, including scientific notation)
- quoted strings with JSON-style escapes (including `\uXXXX` unicode escapes)
- arrays: `[1, 2, 3]`
- objects: `{name: "Dave", count: 3}`
- bareword object keys matching `[A-Za-z_][A-Za-z0-9_-]*`; other keys must be quoted
- tabular sections: `name[count]{field1,field2,...}:` followed by CSV rows

## Example

```perl
use TOON qw(encode_toon decode_toon);
# Aliases: to_toon / from_toon are also available

my $text = encode_toon({
  name   => 'Dave',
  active => 1,
  tags   => ['perl', 'toon'],
}, canonical => 1);

my $data = decode_toon($text);
```

## Tabular syntax

Top-level hashes whose values are arrays of uniform hashes are automatically
encoded in the compact tabular format:

```
users[2]{id,name,role}:
  1,Alice,admin
  2,Bob,user
```

This format is also accepted on decode.

## OO interface

```perl
use TOON;

my $toon = TOON->new->pretty->canonical;
my $text = $toon->encode({ answer => 42 });
my $data = $toon->decode($text);
```
