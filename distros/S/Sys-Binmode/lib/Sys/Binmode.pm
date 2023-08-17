package Sys::Binmode;

use strict;
use warnings;

our $VERSION = '0.05';

=encoding utf-8

=head1 NAME

Sys::Binmode - A fix for Perl’s system call character encoding

=begin html

<a href='https://coveralls.io/github/FGasper/p5-Sys-Binmode?branch=master'><img src='https://coveralls.io/repos/github/FGasper/p5-Sys-Binmode/badge.svg?branch=master' alt='Coverage Status' /></a>

=end html

=head1 SYNOPSIS

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

=head1 DESCRIPTION

tl;dr: Use this module in B<all> new code.

=head1 BACKGROUND

Ideally, a Perl application doesn’t need to know how the interpreter stores
a given string internally. Perl can thus store any Unicode code point while
still optimizing for size and speed when storing “bytes-compatible”
strings—i.e., strings whose code points all lie below 256. Perl’s
“optimized” string storage format is faster and less memory-hungry, but it
can only store code points 0-255. The “unoptimized” format, on the other
hand, can store any Unicode code point.

Of course, Perl doesn’t I<always> optimize “bytes-compatible” strings;
Perl can also, if
it wants, store such strings “unoptimized” (i.e., in Perl’s internal
“loose UTF-8” format), too. For code points 0-127 (ASCII printables,
controls, and DEL) there’s actually no
difference between the two forms, but for 128-255 the formats differ. (cf.
L<perlunicode/The "Unicode Bug">) This means that anything that reads
Perl’s internals B<MUST> differentiate between the two forms in order to
use the string correctly.

Alas, that differentiation doesn’t always happen. When it doesn’t, Perl
outputs code points 128-255 differently depending on whether the
containing string is “optimized” or not.

Remember, though: Perl applications I<should> I<not> I<care> about
Perl’s string storage internals like optimized/unoptimized. (This is why,
for example, the L<bytes>
pragma is discouraged.) The catch, though, is that without that knowledge,
B<the> B<application> B<can’t> B<know> B<what> B<it> B<actually> B<says>
B<to> B<the> B<outside> B<world!>

Thus, applications must either monitor Perl’s string-storage internals
or accept unpredictable behavior, both of which are categorically bad.

(Perl’s documentation calls the “unoptimized” format “upgraded”, while
it calls the “optimized” format “downgraded”. The rest of this document
will favor Perl’s terms.)

=head1 HOW THIS MODULE (PARTLY) FIXES THE PROBLEM

This module provides predictable behavior for Perl’s built-in functions by
downgrading all strings before giving them to the operating system. It’s
equivalent to—but faster than!—prefixing your system calls with
C<utf8::downgrade()> (cf. L<utf8>) on all arguments.

Predictable behavior is B<always> a good thing; ergo, you should
use this module in B<all> new code.

=head1 CAVEAT: CHARACTER ENCODING

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
that throws the error. This is what we should do I<anyway>;
Sys::Binmode just enforces that better.

=head2 Example: The L<utf8> Pragma

The widely-used L<utf8> pragma particularly exemplifies this problem.

If you have code like this:

    use utf8;

    mkdir "épée";

… then adding this module will change your program’s behavior in ways you’ll
probably dislike.

Consider the string C<épée>. Without the C<utf8> pragma (but assuming that
the code I<is> actually written in UTF-8) this is 6
characters because the two C<é>s are 2 bytes each (so 2 + 1 + 2 + 1),
and without the C<utf8> pragma each byte in a string constant becomes its own
character, even if multiple bytes make up a single UTF-8 character. Since
nothing I<probably> upgrades that string on its way to
C<mkdir()>, the OS will receive the intended 6 bytes and create a directory
with a UTF-8-encoded name.

I<With> C<utf8>, though, C<épée> is B<4> characters, not 6, because
this string is now UTF-8-decoded. Those 4 characters all lie beneath 256,
so the string is still bytes-compatible. Thus, if you C<print()> that string
you’ll get 4 bytes of Latin-1, which probably B<isn’t> what you want.

C<mkdir()>, though, I<probably> still creates a directory with a 6-byte (UTF-8)
name. This happens when Perl itself stores C<épée> in upgraded (i.e.,
“unoptimized”) form. If that’s the case, that means Perl’s I<internal> buffer
of C<épée> is still the 6 bytes of UTF-8, even though to the Perl
I<application> it’s a 4-character string. Perl’s C<mkdir()> doesn’t care
about characters, though; it just gives Perl’s internal buffer to the
OS’s create-directory function. So by violating its own abstraction, Perl
happens to achieve something that is I<sometimes> useful.

There are still two problems, though:

=over

=item * 1. Inconsistency: C<print()> sends 4 bytes to the OS while
C<mkdir()> (again, I<probably>) outputs 6.

=item * 2. Uncertainty: C<épée> I<could> be stored downgraded rather than
upgraded, which would cause C<mkdir()> to send 4 bytes instead.

=back

C<print()>’s outputting of 4 bytes here is actually the B<correct> behavior
because it doesn’t depend on whether Perl stores the string upgraded or
downgraded. Sys::Binmode extends that correct behavior to C<mkdir()> and
other such Perl commands.

Of course, in the end, we want C<mkdir()> to receive 6 bytes of UTF-8, not
4 bytes of Latin-1. To achieve that, just do as you normally do with
C<print()>: encode your string before you give it to the OS.

    use utf8;
    use Encode;

    mkdir encode("UTF-8", "épée");

This is what your code should look like, regardless of Sys::Binmode;
the omitted encoding step was a bug that Perl’s own abstraction-violation
bug I<might> have obscured for you. Sys::Binmode fixes Perl’s bug,
which makes you fix your own bug, too.

=head2 Non-POSIX Operating Systems (e.g., Windows)

In a POSIX operating system, an application’s communication with the
OS happens entirely through byte strings. Thus, treating all
OS-destined strings as byte strings is good and natural.

In Windows, though, things are weirder. For example, Windows
exposes multiple APIs for creating a directory, and the one Perl uses (as of
5.32, anyway) only accepts code points 0-255. In this context Sys::Binmode
doesn’t I<break> anything, but it does reinforce one of Perl’s unfortunate
limitations on Windows.

Sys::Binmode is a good idea anywhere that Perl sends byte strings to the OS.
For now, as far as I know, that’s everywhere that Perl runs. If that’s not
true, please file a bug.

=head1 WHERE ELSE THIS PROBLEM CAN APPEAR

The unpredictable-behavior problem that this module fixes in core Perl is
also common in L<CPAN|http://cpan.org>’s XS modules due to rampant
use of L<the SvPV macro|https://perldoc.perl.org/perlapi#SvPV> and
variants. SvPV is basically Perl’s L<bytes> pragma in C: it gives
you the string’s
internal bytes with no regard for what those bytes represent. This, of course,
is problematic for the same reason why the L<bytes> pragma is. XS authors
I<generally> should prefer
L<SvPVbyte|https://perldoc.perl.org/perlapi#SvPVbyte>
or L<SvPVutf8|https://perldoc.perl.org/perlapi#SvPVutf8> in lieu of
SvPV unless the C code in question handles Perl’s encoding abstraction.

Note in particular that, as of Perl 5.32, the default XS typemap converts
scalars to C C<char *> and C<const char *> via an SvPV variant. This means
that any module that uses that conversion logic also has this problem.
So XS authors should also avoid the default typemap for such conversions.
(Again, though, use of the default typemap in this context is regrettably
commonplace.)

Before Perl 5.18 this problem also affected %ENV. 5.18 introduced
an auto-downgrade when setting %ENV similar to what this module does.

=head1 LEXICAL SCOPING

If, for some reason, you I<want> Perl’s unpredictable default behavior,
you can disable this module for a given block via
C<no Sys::Binmode>, thus:

    use Sys::Binmode;

    system 'echo', $foo;        # predictable/sane/happy

    {

        # You should probably explain here why you’re doing this.
        no Sys::Binmode;

        system 'echo', $foo;    # nasal demons
    }

=head1 AFFECTED BUILT-INS

=over

=item * C<exec>, C<system>, and C<readpipe>

=item * C<do> and C<require>

=item * File tests (e.g., C<-e>) and the following:
C<chdir>, C<chmod>, C<chown>, C<chroot>, C<ioctl>,
C<link>, C<lstat>, C<mkdir>, C<open>, C<opendir>, C<readlink>, C<rename>,
C<rmdir>, C<stat>, C<symlink>, C<sysopen>, C<truncate>,
C<unlink>, C<utime>

=item * C<bind>, C<connect>, C<setsockopt>, and C<send> (last argument)

=item * C<syscall>

=back

=head2 Omissions

=over

=item * C<crypt> already does as Sys::Binmode would make it do.

=item * C<select> (the 4-argument one) has the bug that Sys::Binmode fixes,
but since it’s a performance-sensitive call where upgraded strings are
unlikely, this library doesn’t wrap it.

=back

=head1 KNOWN ISSUES

L<autodie> creates functions named, e.g., C<chmod> in the
namespace of the module that C<import()>s it. Those functions lack
the compiler “hint” that tells Sys::Binmode to do its work; thus,
L<autodie “clobbers” Sys::Binmode|https://github.com/pjf/autodie/issues/113>.
C<CORE::*> functions will still have Sys::Binmode, but of course they won’t
throw exceptions.

=head1 TODO

=over

=item * C<dbmopen> and the System V IPC functions aren’t covered here.
If you’d like them, ask.

=item * There’s room for optimization, if that’s gainful.

=item * Ideally this behavior should be in Perl’s core distribution.

=item * Even more ideally, Perl should adopt this behavior as I<default>.
Maybe someday!

=back

=cut

#----------------------------------------------------------------------

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub import {
    $^H{ _HINT_KEY() } = 1;

    return;
}

sub unimport {
    delete $^H{ _HINT_KEY() };
}

#----------------------------------------------------------------------

=head1 ACKNOWLEDGEMENTS

Thanks to Leon Timmermans (LEONT) and Paul Evans (PEVANS) for some
debugging and design help.

=head1 LICENSE & COPYRIGHT

Copyright 2021 Gasper Software Consulting. All rights reserved.

This library is licensed under the same license as Perl.

=cut

1;
