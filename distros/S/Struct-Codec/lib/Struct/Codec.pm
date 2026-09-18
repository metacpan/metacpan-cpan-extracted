package Struct::Codec;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.04';

our $Eval = 1;

require XSLoader;
XSLoader::load('Struct::Codec', $VERSION);

1;

__END__

=encoding utf8

=head1 NAME

Struct::Codec - a Perl structure to bytes and back, with nothing lost

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    use Struct::Codec qw(struct_encode struct_decode);

    my $bytes = struct_encode({ user => 'ada', roles => ['admin'], n => 3 });
    my $data  = struct_decode($bytes);

    # or without importing anything
    my $bytes = Struct::Codec::struct_encode($data);
    my $data  = Struct::Codec::struct_decode($bytes);

=head1 DESCRIPTION

A cache holds bytes and a program holds structures, and on a small value the
codec in between is most of the cost: L<Storable> takes 1.7 microseconds to
freeze and thaw a five-key hash, and JSON gets there three times faster by
giving things up. This gives nothing up and gets there three times faster
anyway, and it publishes a C interface so another XS module can encode a value
straight into memory it owns and decode one straight out, with no Perl call
in between. 

=head2 What comes back the same

C<decode(encode($v))> is C<$v>:

=over 4

=item * A string is a string and a number is a number, whichever it was. C<"007">
comes back C<"007">, and C<5> comes back C<5> even after it has been printed.
Integers, including the full range of an unsigned one, and floats each come
back as what they were.

=item * The UTF-8 flag survives on strings and on hash keys, so a character
string and a byte string that happen to hold the same bytes come back as two
different strings.

=item * On perl 5.36 and later a boolean comes back a boolean.

=item * A blessed referent comes back blessed into the same class. Nothing is
called on it: no C<FREEZE>, no C<THAW>, and no C<DESTROY> on anything half
built.

=item * References that were shared are shared again, a cycle is a cycle again,
and two array elements that were one scalar are one scalar again. A change
made through one shows through the other, as it did before.

=back

=head2 What changes

=over 4

=item * A weak reference comes back strong. It is still shared with whatever it
was shared with.

=item * A dualvar keeps its string.

=item * On a perl before 5.36 a boolean comes back as C<1> or the empty string.

=item * Two array elements or hash values that held the same I<reference>
come back as two references to one referent, which is what a reader of the
structure saw anyway.

=back

=head2 What else comes back

The kinds that are not data are carried too, each as what perl already knows
about it, and none of them is read through on the way in.

=over 4

=item * A B<regexp> is its pattern and its flags, compiled again on decode,
and it comes back a C<Regexp>, or whatever class it was blessed into. Nothing
is evaluated: a pattern with a C<(?{ })> block is refused by the regexp engine
on decode, as one interpolated from a variable is, unless the code decoding
has C<use re 'eval'> in force.

=item * A B<tied> hash, array or scalar is the object behind the tie, and
comes back tied to that object again. Its contents are not stored: they are
whatever the object answers, on both sides. Decoding calls nothing, not even
C<TIEHASH>; the first read through the tie does what it always did. This is
what L<Storable> does.

=item * A B<named sub> is its fully-qualified name, and comes back as that
very sub: C<\&main::foo> decodes to C<\&main::foo>, not a copy. A name that
finds no sub is an error, and nothing is created for it.

=item * An B<anonymous sub> is its source, as L<B::Deparse> writes it, which
is slow to encode and the only way there is. Decoding it means running code
out of the stream; set C<$Struct::Codec::Eval> to false to refuse that, or to
a code reference to do it your own way: see L</$Struct::Codec::Eval>. A sub that captured a lexical is
B<refused on encode>, because its source without that lexical is a different
sub that would run without complaint. Storable's C<Deparse> path hands that
sub back silently wrong; this names it instead.

=item * A B<glob> with a name comes back as that glob, C<\*STDOUT> as
C<\*STDOUT>, and so does a glob copied into a slot. A B<format> likewise, by
the name of the glob it lives in; one that is not defined on decode is an
error.

=item * A B<filehandle> that no name finds - a lexical C<open my $fh>, an
C<IO::Handle> - is its file descriptor and mode, and an C<IO> the same. Decode
reopens the descriptor with a C<dup>, so the handle that comes back is its
own, and closing it leaves the original open. B<A descriptor means something
only in the process that encoded it, or a child that inherited it.> Anywhere
else the number names whatever happens to be open under it there, or nothing,
which is an error. This is the one kind in the format that is not portable,
and it is here for the fork-shared caches that are the format's reason to
exist.

=back

=head2 What is refused

A closure, an anonymous XSUB, and a glob with no name and nothing open. Each
is refused with an error that names it:

    Struct::Codec: cannot encode a closure: it captured a lexical that would not come with it

rather than being turned into a string or a sub that runs but does something
else, because either is a bug that nobody finds until they read it back. A
refusal leaves nothing behind; the next call is unaffected.

=head2 Trusted contents

A class name in the stream is blessed into, and the package is created if it
does not exist; a glob's name is created likewise. A tie object's class runs
when the tied value is first read, as any object's methods do. So decode only
what your own program encoded, exactly as with L<Storable>. A sub by source
is compiled on decode; a program that decodes bytes it did not write sets
C<$Struct::Codec::Eval> to false first, and then such a sub is an error rather
than code that runs. This is a property of the contents, not of corrupt bytes:
see the next section.

=head2 Corrupt input is an error, never a crash

A truncated stream, a flipped bit, a length that runs past the end, a
reference to a value that does not exist, a nesting deeper than 4096, a
duplicate hash key, bytes after the value: every one is an error naming the
reason and the byte it was found at,

    Struct::Codec: truncated input at byte 17

and the interpreter is intact afterwards, with nothing half built and nothing
leaked. The test suite drives every truncation and every single-bit flip of
its fixtures, and tens of thousands of random streams, through the decoder in
a child process and asserts the child lived.

=head2 The bytes are portable

Nothing in the stream depends on the machine that wrote it. Integers are
variable-length, strings are bytes with a flag, and a float is an IEEE-754
double in little-endian order, swapped on a big-endian host. So a stream can be
written to a file or sent to another machine and decoded there, by any perl with
this module. One caveat is left of L<Storable>'s C<nfreeze> caveats:

=over 4

=item * A perl with 32-bit integers refuses an integer wider than that with an
error, rather than truncating it.

=back

A float keeps every digit it had, including on a perl built C<-Duselongdouble>
or C<-Dusequadmath>. Where such a perl holds a number the 8-byte form cannot,
the float goes out as its decimal digits instead, at the precision that reads
back as the same number. A perl whose NV is a double never writes that form, so
its streams are unchanged.

Between perls of different NV widths it behaves as arithmetic requires. A
narrower perl reading a wider perl's float gets the nearest number it can hold,
which is the one it would have held itself. A wider perl reading a narrower
one's gets that number exactly: the value the writer had, not the value the
writer might have meant, so one tenth written by a long-double perl is that
perl's tenth and not a quadmath perl's.

What the bytes are not: compressed, or compatible with any other serialiser.
And the contents are trusted, as above, so a stream from a machine you do not
control is a stream you should not decode.

=head1 FUNCTIONS

Nothing is exported by default. C<struct_encode> and C<struct_decode> are
exported on request, and are the same two functions.

=head2 struct_encode

    my $bytes = struct_encode($value);

A byte string. Croaks, naming the type, on a value it cannot carry.

=head2 struct_decode

    my $value = struct_decode($bytes);

The value back. Croaks, naming the reason and the byte, on anything that is
not a stream this module wrote.

=head2 encode, decode

    my $bytes = Struct::Codec::encode($value);
    my $value = Struct::Codec::decode($bytes);

The same two functions under their short names, for a caller writing the
package in full. They are never exported, so they cannot collide with
L<Encode>'s.

=head2 import

Exports C<struct_encode> and C<struct_decode> when asked for them by name, and
nothing otherwise. Any other name is an error.

=head1 VARIABLES

=head2 $Struct::Codec::Eval

    my $sub = struct_decode($bytes);       # an anonymous sub, rebuilt from its source

    local $Struct::Codec::Eval = 0;        # bytes from elsewhere: refuse instead
    my $data = struct_decode($untrusted);

    local $Struct::Codec::Eval = sub {
        my ($source) = @_;                 # "{ ... }", as B::Deparse wrote it
        return Safe->new->reval("sub $source");
    };

Whether a sub stored by source may be rebuilt. True, the default, evaluates
C<"sub $source"> in the scope of the caller. False refuses with an error
naming the byte, which is the setting for bytes your own program did not
write. A code reference is handed the source and must return a code reference,
for a caller who wants a L<Safe> compartment or a cache of compiled subs. Subs
by name never consult this: they are looked up, not built.

=head1 THE C API

An XS module can call the codec without a Perl frame. The table is resolved at
runtime through C<Struct::Codec::_abi_ptr>, so there is no link-time coupling
and each distribution builds and upgrades on its own. In your F<Makefile.PL>:

    my $pkg = ExtUtils::Depends->new('My::Module', 'Struct::Codec');

which puts F<sc_abi.h> on the include path. Then once, at BOOT:

    #include "sc_abi.h"
    static const sc_abi *SC = NULL;

    BOOT:
    {
        SV *err;
        SV *sv = eval_pv("require Struct::Codec; Struct::Codec::_abi_ptr()", 0);
        err = get_sv("@", 0);
        if (sv && SvOK(sv) && (!err || !SvTRUE(err))) {
            const sc_abi *t = INT2PTR(const sc_abi *, SvUV(sv));
            if (t && t->abi_version >= SC_ABI_VERSION) SC = t;
        }
    }

Check with C<< >= >>, never C<==>: the table only ever grows at the end, and a
later version is a superset of the one you were built against. A NULL C<SC>
means the module is absent or too old, and what to do about that is your
policy.

The three entries, every one taking C<pTHX_>:

    SV     *(*encode)(pTHX_ SV *value);
    STRLEN  (*encode_to)(pTHX_ SV *value, char *buf, STRLEN cap, STRLEN *need);
    SV     *(*decode)(pTHX_ const char *bytes, STRLEN len);

C<encode> and C<decode> return an SV you own. C<encode_to> writes into memory
you supply: it returns the bytes written, or 0 with C<*need> set to what the
value would have taken when C<cap> is too small, and on that path it writes
nothing past C<cap> and allocates nothing at all. That is the entry a
fixed-size store calls, with a buffer the size of the slot, so an oversized
value is refused without a malloc. Call through the table with the member in
parentheses, C<(SC-E<gt>encode)(aTHX_ v)>, which keeps the call compiling on
a perl whose F<XSUB.h> defines C-library names as macros.

=head1 SEE ALSO

L<Storable>, which this matches in what it keeps. L<Shared::Arena>, the first
consumer of the C API.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-struct-codec at
rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Codec>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
