# NAME

Sys::Binmode - A fix for Perl’s system call character encoding

<div>
    <a href='https://coveralls.io/github/FGasper/p5-Sys-Binmode?branch=master'><img src='https://coveralls.io/repos/github/FGasper/p5-Sys-Binmode/badge.svg?branch=master' alt='Coverage Status' /></a>
</div>

# SYNOPSIS

    use Sys::Binmode;

    my $foo = "\xff";
    $foo .= "\x{100}";
    chop $foo;

    # Prints a single octet (0xFF) and a newline:
    print $foo, $/;

    # In Perl 5.32 this may print the same single octet, or it may
    # print UTF-8-encoded U+00FF. With Sys::Binmode, though, it always
    # gives the single octet, just like print:
    exec 'echo', $foo;

# DESCRIPTION

tl;dr: Use this module in **all** new code.

# BACKGROUND

Ideally, a Perl application doesn’t need to know how the interpreter stores
a given string internally. Perl can thus store any Unicode code point while
still optimizing for size and speed when storing “bytes-compatible”
strings—i.e., strings whose code points all lie below 256. Perl’s
“optimized” string storage format is faster and less memory-hungry, but it
can only store code points 0-255. The “unoptimized” format, on the other
hand, can store any Unicode code point.

Of course, Perl doesn’t _always_ optimize “bytes-compatible” strings;
Perl can also, if
it wants, store such strings “unoptimized” (i.e., in Perl’s internal
“loose UTF-8” format), too. For code points 0-127 (ASCII printables,
controls, and DEL) there’s actually no
difference between the two forms, but for 128-255 the formats differ. (cf.
["The "Unicode Bug"" in perlunicode](https://metacpan.org/pod/perlunicode#The-Unicode-Bug)) This means that anything that reads
Perl’s internals **MUST** differentiate between the two forms in order to
use the string correctly.

Alas, that differentiation doesn’t always happen. When it doesn’t, Perl
outputs code points 128-255 differently depending on whether the
containing string is “optimized” or not.

Remember, though: Perl applications _should_ _not_ _care_ about
Perl’s string storage internals like optimized/unoptimized. (This is why,
for example, the [bytes](https://metacpan.org/pod/bytes)
pragma is discouraged.) The catch, though, is that without that knowledge,
**the** **application** **can’t** **know** **what** **it** **actually** **says**
**to** **the** **outside** **world!**

Thus, applications must either monitor Perl’s string-storage internals
or accept unpredictable behavior, both of which are categorically bad.

(Perl’s documentation calls the “unoptimized” format “upgraded”, while
it calls the “optimized” format “downgraded”. The rest of this document
will favor Perl’s terms.)

# HOW THIS MODULE (PARTLY) FIXES THE PROBLEM

This module provides predictable behavior for Perl’s built-in functions by
downgrading all strings before giving them to the operating system. It’s
equivalent to—but faster than!—prefixing your system calls with
`utf8::downgrade()` (cf. [utf8](https://metacpan.org/pod/utf8)) on all arguments.

Predictable behavior is **always** a good thing; ergo, you should
use this module in **all** new code.

# CAVEAT: CHARACTER ENCODING

If you apply this module injudiciously to existing code you may see
exceptions or character corruption where previously things worked fine.

This can
happen if you’ve neglected to encode one or more strings before
sending them to the OS. Without Sys::Binmode, Perl sends upgraded
strings to the OS in UTF-8 encoding. In essence, it’s an implicit
UTF-8 auto-encode, which is kind of nice, except that it depends on
Perl’s internals, which are unpredictable. Sys::Binmode removes
that implicit UTF-8 auto-encode, which of course will break things
that need it.

The fix is to apply an explicit UTF-8 encode prior to the system call
that throws the error. This is what we should do _anyway_;
Sys::Binmode just enforces that better.

## Example: The [utf8](https://metacpan.org/pod/utf8) Pragma

The widely-used [utf8](https://metacpan.org/pod/utf8) pragma particularly exemplifies this problem.

If you have code like this:

    use utf8;

    mkdir "épée";

… then adding this module will change your program’s behavior in ways you’ll
probably dislike.

Consider the string `épée`. Without the `utf8` pragma (but assuming that
the code _is_ actually written in UTF-8) this is 6
characters because the two `é`s are 2 bytes each (so 2 + 1 + 2 + 1),
and without the `utf8` pragma each byte in a string constant becomes its own
character, even if multiple bytes make up a single UTF-8 character. Since
nothing _probably_ upgrades that string on its way to
`mkdir()`, the OS will receive the intended 6 bytes and create a directory
with a UTF-8-encoded name.

_With_ `utf8`, though, `épée` is **4** characters, not 6, because
this string is now UTF-8-decoded. Those 4 characters all lie beneath 256,
so the string is still bytes-compatible. Thus, if you `print()` that string
you’ll get 4 bytes of Latin-1, which probably **isn’t** what you want.

`mkdir()`, though, _probably_ still creates a directory with a 6-byte (UTF-8)
name. This happens when Perl itself stores `épée` in upgraded (i.e.,
“unoptimized”) form. If that’s the case, that means Perl’s _internal_ buffer
of `épée` is still the 6 bytes of UTF-8, even though to the Perl
_application_ it’s a 4-character string. Perl’s `mkdir()` doesn’t care
about characters, though; it just gives Perl’s internal buffer to the
OS’s create-directory function. So by violating its own abstraction, Perl
happens to achieve something that is _sometimes_ useful.

There are still two problems, though:

- 1. Inconsistency: `print()` sends 4 bytes to the OS while
`mkdir()` (again, _probably_) outputs 6.
- 2. Uncertainty: `épée` _could_ be stored downgraded rather than
upgraded, which would cause `mkdir()` to send 4 bytes instead.

`print()`’s outputting of 4 bytes here is actually the **correct** behavior
because it doesn’t depend on whether Perl stores the string upgraded or
downgraded. Sys::Binmode extends that correct behavior to `mkdir()` and
other such Perl commands.

To get what you want, just encode your string for output before you give it
to the OS (as you should do anyway):

    use utf8;
    use Encode;

    mkdir encode_utf8("épée");

Now adding Sys::Binmode to your module will change nothing. It _will_,
though, make any future omitted-encoding bugs more apparent.

## Non-POSIX Operating Systems (e.g., Windows)

In a POSIX operating system, an application’s communication with the
OS happens entirely through byte strings. Thus, treating all
OS-destined strings as byte strings is good and natural.

In Windows, though, things are weirder. For example, Windows
exposes multiple APIs for creating a directory, and the one Perl uses (as of
5.32, anyway) only accepts code points 0-255. In this context Sys::Binmode
doesn’t _break_ anything, but it does reinforce one of Perl’s unfortunate
limitations on Windows.

Sys::Binmode is a good idea anywhere that Perl sends byte strings to the OS.
As far as I know, that’s everywhere that Perl runs. If that’s not true,
please file a bug.

# WHERE ELSE THIS PROBLEM CAN APPEAR

The unpredictable-behavior problem that this module fixes in core Perl is
also common in XS modules due to rampant
use of [the SvPV macro](https://perldoc.perl.org/perlapi#SvPV) and
variants. SvPV is like the [bytes](https://metacpan.org/pod/bytes) pragma in C: it gives you the string’s
internal bytes with no regard for what those bytes represent. XS authors
_generally_ should prefer
[SvPVbyte](https://perldoc.perl.org/perlapi#SvPVbyte)
or [SvPVutf8](https://perldoc.perl.org/perlapi#SvPVutf8) in lieu of
SvPV unless the C code in question deals with Perl’s encoding abstraction.

Note in particular that, as of Perl 5.32, the default XS typemap converts
scalars to C `char *` and `const char *` via an SvPV variant. This means
that any module that uses that conversion logic also has this problem.
So XS authors should also avoid the default typemap for such conversions.

# LEXICAL SCOPING

If, for some reason, you _want_ Perl’s unpredictable default behavior,
you can disable this module for a given block via
`no Sys::Binmode`, thus:

    use Sys::Binmode;

    system 'echo', $foo;        # predictable/sane/happy

    {

        # You should probably explain here why you’re doing this.
        no Sys::Binmode;

        system 'echo', $foo;    # nasal demons
    }

# AFFECTED BUILT-INS

- `exec` and `system`
- `do` and `require`
- File tests (e.g., `-e`) and the following:
`chdir`, `chmod`, `chown`, `chroot`,
`link`, `lstat`, `mkdir`, `open`, `opendir`, `readlink`, `rename`,
`rmdir`, `stat`, `symlink`, `sysopen`, `truncate`,
`unlink`, `utime`
- `bind`, `connect`, and `setsockopt`
- `syscall`

# TODO

- `dbmopen` and the System V IPC functions aren’t covered here.
If you’d like them, ask.
- There’s room for optimization, if that’s gainful.
- Ideally this behavior should be in Perl’s core distribution.
- Even more ideally, Perl should adopt this behavior as _default_.
Maybe someday!

# ACKNOWLEDGEMENTS

Thanks to Leon Timmermans (LEONT) and Paul Evans (PEVANS) for some
debugging and design help.

# LICENSE & COPYRIGHT

Copyright 2021 Gasper Software Consulting. All rights reserved.

This library is licensed under the same license as Perl.
