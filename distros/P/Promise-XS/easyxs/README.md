# EasyXS

This library is a toolbox that assists with creation & maintenance
of [Perl XS](https://perldoc.perl.org/perlxs) code.

# Usage

1. Make this repository a
[git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
of your own XS module.

2. Replace the standard XS includes (`EXTERN.h`, `perl.h`, and `XSUB.h`)
with just `#include "easyxs/easyxs.h"`.

… and that’s it! You now have a suite of tools that’ll make writing XS
easier and safer.

# Rationale

Perl’s C API makes lots of things _possible_ without making them
_easy_ (or _safe_).

This library attempts to provide shims around that API that make it easy
and safe (or, at least, safe-_er_!) to write XS code … maybe even *fun!* :-)

# Library Components

## Initialization

`init.h` includes the standard boilerplate code you normally stick at the
top of a `*.xs` file. It also includes a fix for the
[torrent of warnings that clang 12 throws](https://github.com/Perl/perl5/issues/18780)
in pre-5.36 perls. `easyxs.h` brings this in, but you can also
`#include "easyxs/init.h"` on its own.

`init.h` also includes a fairly up-to-date (as of this writing!) `ppport.h`.

## Calling Perl

### `void exs_call_sv_void(SV* callback, SV** args)`

Like the Perl API’s `call_sv()` but simplifies argument-passing.
`args` points to a NULL-terminated array of `SV*`s.
(It may itself also be NULL.)

The callback is called in void context, so nothing is returned.

**IMPORTANT CAVEATS:**

- This does _not_ trap exceptions. Ensure either that the callback won’t
throw, or that no corruption will happen in the event of an exception.

- This **mortalizes** each `args` member. That means Perl
will reduce each of those SVs’ reference counts at some point “soon” after.
This is often desirable, but not always; to counteract it, do `SvREFCNT_inc()`
around whichever arguments you want to be unaffected by the mortalization.
(They’ll still be mortalized, but the eventual reference-count reduction will
just have zero net effect.)

### `SV* exs_call_sv_scalar(SV* callback, SV** args)`

Like `exs_call_sv_void()` but calls the callback in scalar context.
The result is returned.

### `SV* exs_call_sv_scalar_trapped(SV* callback, SV** args, SV** error_svp)`

Like `exs_call_sv_scalar()` but traps exceptions. If one happens,
NULL is returned, and `*error_svp` will contain the error SV.
(This SV is a **copy** of Perl’s `$@` and so **must be freed**.)

### `void exs_call_sv_void_trapped(SV* callback, SV** args, SV** error_svp)`

Like `exs_call_sv_scalar_trapped()` but calls the Perl callback in void
context and doesn’t return anything.

### `void exs_call_method_void(SV* object, const char* methname, SV** args)`

Like `exs_call_sv_void()` but for calling object methods. See
the Perl API’s `call_method()` for more details.

### `SV* exs_call_method_scalar(SV* object, const char* methname, SV** args)`

Like `exs_call_method_void()` but calls the method in scalar context.
The result is returned.

### `SV** exs_call_sv_list(SV* callback, SV** args)`

Like `exs_call_sv_scalar` but calls the callback in list context.

The return is a pointer to a NUL-terminated array of `SV*`s. The pointer will
be freed automatically, but the SVs are non-mortals with reference count 1,
so you’ll need to dispose of those however is best for you.

### `SV** exs_call_sv_list_trapped(SV* callback, SV** args, SV** error_svp)`

Like both `exs_call_sv_list` and `exs_call_sv_scalar_trapped`. If the
callback throws, this behaves as `exs_call_sv_scalar_trapped` does;
otherwise, this behaves as `exs_call_sv_list` does.

## SV “Typing”

Perl scalars are supposed to be “untyped”, at least insofar as
strings/numbers. When conversing with other languages, though, or
serializing it’s usually helpful to break things down in greater
detail.

EasyXS defines an `exs_sv_type` macro that takes an SV as argument
and returns a member of `enum exs_sv_type_e` (typedef’d as just
`exs_sv_type_e`; see `easyxs_scalar.h` for values). The logic is compatible
with the serialization logic formulated during Perl 5.36’s development cycle.

## SV/Number Conversion

### `UV* exs_SvUV(SV* sv)`

Like `SvUV`, but if the SV’s content can’t be a UV
(e.g., the IV is negative, or the string has non-numeric characters)
an exception is thrown.

## SV/String Conversion

### `char* exs_SvPVbyte_nolen(SV* sv)`

Like the Perl API’s `SvPVbyte_nolen`, but if there are any NULs in the
string then an exception is thrown.

### `char* exs_SvPVutf8_nolen(SV* sv)`

Like `exs_SvPVbyte_nolen()` but returns the code points as UTF-8 rather
than Latin-1/bytes.

## Struct References

It’s common in XS code to need to persist a C struct via a Perl variable,
then free that struct once the Perl variable is garbage-collected. Perl’s
`sv_setref_pv` and similar APIs present one way to do this: store a pointer
to the struct in an SV, then pass around a blessed (Perl) reference to that
SV, freeing the struct when the referent SV gets DESTROYed.

EasyXS’s “struct references” are a slight simplification of this workflow:
use the referent SV’s PV to store the struct itself. Thus, Perl cleans up
the struct for you, and there’s no need for a DESTROY to free your struct.
(You may, of course, still need a DESTROY to free blocks to which your
struct refers.)

### `exs_new_structref(type, classname)`

Creates a new structref for the given (C) `type` and (Perl) `classname`.

### `exs_structref_ptr(svrv)`

Returns a pointer to `svrv`’s contained struct.

## Debugging

### `exs_debug_sv_summary(SV* sv)`

Writes a visual representation of the SV’s contents to `Perl_debug_log`.
**NO** trailing newline is written.

### `exs_debug_showstack(const char *pattern, ...)`

Writes a visual representation of Perl’s argument stack
to `Perl_debug_log`.

# Usage Notes

If you use GitHub Actions or similar, ensure that you grab the submodule
as part of your workflow’s checkout. If you use GitHub’s own
[checkout](https://github.com/actions/checkout) workflow, that’s:

    - with:
        submodules: true  # (or `recursive`)

Alternatively, run `git submodule init && git submodule update`
during the workflow’s repository setup.

# License & Copyright

Copyright 2022 by Gasper Software Consulting. All rights reserved.

This library is released under the terms of the
[MIT License](https://mitlicense.org/).
