# XS Helper

This library is a toolbox that assists with creation & maintenance
of Perl XS code.

# Why?

Perl’s C API is powerful, but its focus is on making things _possible_
rather than making them _easy_ (or _safe_).

This library attempts to fill that latter gap: make it _easy_ (and safe!)
to write XS code … and maybe even *fun!* :-)

# Sections

Library routines fall into these categories:

## 1. Conversion

Convert Perl values to C values, with “sensible” validation.

### Design Notes

Interfaces can take either of 2 basic approaches to validation:

1. “Sanitize” invalid inputs into valid ones. (Often happens without
giving the caller any indication.) Sometimes called “Do What I Mean”
(DWIM).

2. “Fail early; fail often”: reject anything invalid, and consider as many
variants as possible to be “invalid”.

Perl’s C API’s conversion tools generally take approach #1. They’re
not alone; standard C functions like L<strtol(3)> do likewise.

Approach #2 is what languages
like L<TypeScript|https://www.typescriptlang.org/> and
L<Rust|https://www.rust-lang.org/> privilege; it’s also the ideal behind
this library’s conversion tools.

## 2. Perl Callers

Call Perl from C, I<much> more simply than the examples in L<perlcall>.
