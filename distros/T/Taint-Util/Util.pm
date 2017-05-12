package Taint::Util;
our $VERSION = '0.08';
use XSLoader ();

@EXPORT_OK{qw(tainted taint untaint)} = ();

sub import
{
    shift;
    my $caller = caller;
    for (@_ ? @_ : keys %EXPORT_OK)
    {
        die qq["$_" is not exported by the @{[__PACKAGE__]} module"]
            unless exists $EXPORT_OK{$_};
        *{"$caller\::$_"} = \&$_;
    }
}

XSLoader::load __PACKAGE__, $VERSION;

1;

__END__

=head1 NAME

Taint::Util - Test for and flip the taint flag without regex matches or C<eval>

=head1 SYNOPSIS

    #!/usr/bin/env perl -T
    use Taint::Util;

    # eek!
    untaint $ENV{PATH};

    # $sv now tainted under taint mode (-T)
    taint(my $sv = "hlagh");

    # Untaint $sv again
    untaint $sv if tainted $sv;

=head1 DESCRIPTION

Wraps perl's internal routines for checking and setting the taint flag
and thus does not rely on regular expressions for untainting or odd
tricks involving C<eval> and C<kill> for checking whether data is
tainted, instead it checks and flips a flag on the scalar in-place.

=head1 FUNCTIONS

=head2 tainted

Returns a boolean indicating whether a scalar is tainted. Always false
when not under taint mode.

=head2 taint & untaint

Taints or untaints given values, arrays will be flattened and their
elements tainted, likewise with the values of hashes (keys can't be
tainted, see L<perlsec>). Returns no value (which evaluates to false).

    untaint(%ENV);                  # Untaints the environment
    taint(my @hlagh = qw(a o e u)); # elements of @hlagh now tainted

References (being scalars) can also be tainted, a stringified
reference reference raises an error where a tainted scalar would:

    taint(my $ar = \@hlagh);
    system echo => $ar;      # err: Insecure dependency in system

This feature is used by perl internally to taint the blessed object
C<< qr// >> stringifies to.

    taint(my $str = "oh noes");
    my $re = qr/$str/;
    system echo => $re;      # err: Insecure dependency in system

This does not mean that tainted blessed objects with overloaded
stringification via L<overload> need return a tainted object since
those objects may return a non-tainted scalar when stringified (see
F<t/usage.t> for an example). The internal handling of C<< qr// >>
however ensures that this holds true.

File handles can also be tainted, but this is pretty useless as the
handle itself and not lines retrieved from it will be tainted, see the
next section for details.

    taint(*DATA);    # *DATA tainted
    my $ln = <DATA>; # $ln not tainted

=head1 About tainting in Perl

Since this module is a low level interface that directly exposes the
internal C<SvTAINTED*> functions it also presents new and exciting
ways for shooting yourself in the foot.

Tainting in Perl was always meant to be used for potentially hostile
external data passed to the program. Perl is passed a soup of strings
from the outside; it never receives any complex datatypes directly.

For instance, you might get tainted hash keys in C<%ENV> or tainted
strings from C<*STDIN>, but you'll never get a tainted Hash reference
or a tainted subroutine. Internally, the perl compiler sets the taint
flag on external data in a select few functions mainly having to do
with IO and string operations. For example, the C<ucfirst> function
will manually set a tainted flag on its newly created string depending
on whether the original was tainted or not.

However, since Taint::Util is exposing some of perl's guts, things get
more complex. Internally, tainting is implemented via perl's MAGIC
facility, which allows you to attach attach magic to any scalar, but
since perl doesn't liberally taint scalars it's there to back you up
if you do.

You can C<taint(*DATA)> and C<tainted(*DATA)> will subsequently be
true but if you read from the filehandle via C<< <DATA> >> you'll get
untainted data back. As you might have guessed this is completely
useless.

The test file F<t/usage.t> highlights some of these edge cases.

Back in the real world, the only reason tainting makes sense is because
perl will back you up when you use it, e.g. it will slap your hand if
you try to pass a tainted value to system().

If you taint references, perl doesn't offer that protection, because it
doesn't know anything about tainted references since it would never
create one. The things that do work like the stringification of
C<taint($t = [])> (i.e. C<ARRAY(0x11a5d48)>) being tainted only work
incidentally.

But I'm not going to stop you. By all means, have at it! Just don't
expect it to do anything more useful than warming up your computer.

See L<RT #53988|https://rt.cpan.org/Ticket/Display.html?id=53988> for
the bug that inspired this section.

=head1 EXPORTS

Exports C<tainted>, C<taint> and C<untaint> by default. Individual
functions can be exported by specifying them in the C<use> list, to
export none use C<()>.

=head1 HISTORY

I wrote this when implementing L<re::engine::Plugin> so that someone
writing a custom regex engine with it wouldn't have to rely on perl
regexps for untainting capture variables, which would be a bit odd.

=head1 SEE ALSO

L<perlsec>

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE

Copyright 2007-2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
