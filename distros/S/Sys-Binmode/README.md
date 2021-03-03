# NAME

Sys::Binmode - Fix Perl’s system call character encoding.

<div>
    <a href='https://coveralls.io/github/FGasper/p5-Sys-Binmode?branch=master'><img src='https://coveralls.io/repos/github/FGasper/p5-Sys-Binmode/badge.svg?branch=master' alt='Coverage Status' /></a>
</div>

# SYNOPSIS

    use Sys::Binmode;

    my $foo = "é";
    $foo .= "\x{100}";
    chop $foo;

    # Prints “é”:
    print $foo, $/;

    # In Perl 5.32 this may print mojibake,
    # but with Sys::Binmode it always prints “é”:
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
“loose UTF-8” format), too. For code points 0-127 there’s actually no
difference between the two forms, but for 128-255 the formats differ. (cf.
["The "Unicode Bug"" in perlunicode](https://metacpan.org/pod/perlunicode#The-Unicode-Bug)) This means that anything that reads
Perl’s internals **MUST** differentiate between the two forms in order to
use the string correctly.

Alas, that differentiation doesn’t always happen. Thus, Perl can
output a string that stores one or more 128-255 code points
differently depending on whether Perl has “optimized” that string or not.

Remember, though: Perl applications _should_ _not_ _care_ about
Perl’s string storage internals. (This is why, for example, the [bytes](https://metacpan.org/pod/bytes)
pragma is discouraged.) The catch, though, is that without that knowledge,
**the** **application** **can’t** **know** **what** **it** **actually** **says**
**to** **the** **outside** **world!**

Thus, applications must either monitor Perl’s string-storage internals
or accept unpredictable behaviour, both of which are categorically bad.

# HOW THIS MODULE (PARTLY) FIXES THE PROBLEM

This module provides predictable behaviour for Perl’s built-in functions by
downgrading all strings before giving them to the operating system. It’s
equivalent to—but faster than!—prefixing your system calls with
`utf8::downgrade()` (cf. [utf8](https://metacpan.org/pod/utf8)) on all arguments.

Predictable behaviour is **always** a good thing; ergo, you should
use this module in **all** new code.

# CAVEAT: CHARACTER ENCODING

If you apply this module injudiciously to existing code you may see
exceptions thrown where previously things worked just fine. This can
happen if you’ve neglected to encode one or more strings before
sending them to the OS; if Perl has such a string stored upgraded then
Perl will, under default behaviour, send a UTF-8-encoded
version of that string to the OS. In essence, it’s an implicit
UTF-8 auto-encode.

The fix is to apply an explicit UTF-8 encode prior to the system call
that throws the error. This is what we should do _anyway_;
Sys::Binmode just enforces that better.

## Windows (et alia)

NTFS, Windows’s primary filesystem, expects filenames to be encoded in
little-endian UTF-16. To create a file named `épée`, then, on NTFS
you have to do something like:

    my $windows_filename = Encode::Simple::encode( 'UTF-16LE', $filename );

… where `$filename` is a character (i.e., decoded) string.

Other OSes and filesystems may have their own quirks; regardless, this
module gives you a saner point of departure to address those
than Perl’s default behaviour provides.

# WHERE ELSE THIS PROBLEM CAN APPEAR

The unpredictable-behaviour problem that this module fixes in core Perl is
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

If, for some reason, you _want_ Perl’s unpredictable default behaviour,
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
- Ideally this behaviour should be in Perl’s core distribution.
- Even more ideally, Perl should adopt this behaviour as _default_.
Maybe someday!

# ACKNOWLEDGEMENTS

Thanks to Leon Timmermans (LEONT) and Paul Evans (PEVANS) for some
debugging and design help.

# LICENSE & COPYRIGHT

Copyright 2021 Gasper Software Consulting. All rights reserved.

This library is licensed under the same license as Perl.
