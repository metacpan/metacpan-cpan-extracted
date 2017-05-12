package Readonly::Tiny;

=head1 NAME

Readonly::Tiny - Simple, correct readonly values

=head1 SYNOPSIS

    use Readonly::Tiny;

    my $x = readonly [1, 2, 3];
    # $x is not readonly, but the array it points to is.
    
    my @y = (4, 5, 6);
    readonly \@y;
    # @y is readonly, as well as its contents.

=head1 DESCRIPTION

Readonly::Tiny provides a simple and correct way of making values
readonly. Unlike L<Readonly> it does not cause arrays and hashes to be
tied, it just uses the core C<SvREADONLY> flag.

=head1 FUNCTIONS

=cut

use 5.008;
use warnings;
use strict;

our $VERSION = "4";

use Exporter "import";
our @EXPORT = qw/readonly/;
our @EXPORT_OK = qw/readonly readwrite Readonly/;

use Carp            qw/croak/;
use Scalar::Util    qw/reftype refaddr blessed/;
use Hash::Util;
#use Data::Dump      qw/pp/;

use constant RX_MAGIC => (reftype(qr/x/) ne "REGEXP");

if (RX_MAGIC) {
    require B;

    *is_regexp = sub {
        my $o = B::svref_2object($_[0]) or return;
        blessed($o) eq "B::PVMG"        or return;

        my $m = $o->MAGIC;
        while ($m) {
            $m->TYPE eq "r" and return 1;
            $m = $m->MOREMAGIC;
        }

        return;
    };
}

sub debug { 
    #warn sprintf "%s [%x] %s\n", @_;
}

=head2 readonly

    my $ro = readonly $ref, \%opts;

Make a data structure readonly. C<$ref> must be a reference; the
referenced value, and any values referenced recursively, will be made
readonly. C<$ref> is returned, but it will not itself be readonly; it is
possible to make a variable readonly by passing a reference to it, as in
the L</SYNOPSIS>.

C<%opts> is a hashref of options:

=over 4

=item peek

Normally blessed references will not be looked through. The scalar
holding the reference will be made readonly (so a different object
cannot be assigned) but the contents of the object itself will be left
alone. Supplying C<< peek => 1 >> allows blessed refs to be looked
through.

=item skip

This should be a hashref keyed by refaddr. Any object whose refaddr is
in the hash will be skipped.

=back

Note that making a hash readonly has the same effect as calling
L<C<Hash::Util::lock_hash>|Hash::Util/lock_hash>; in particular, it
causes restricted hashes to be re-restricted to their current set of
keys.

=head2 readwrite

    my $rw = readwrite $ref, \%opts;

Undo the effects of C<readonly>. C<%opts> is the same. Note that making
a hash readwrite will undo any restrictions put in place using
L<Hash::Util>.

B<BE VERY CAREFUL> calling this on values you have not made readonly
yourself. It will silently ignore attempts to make the core values
C<PL_sv_undef>, C<PL_sv_yes> and C<PL_sv_no> readwrite, but there are
many other values the core makes readonly, usually with good reason.
Recent versions of perl will not allow you to make readwrite a value the
core has set readonly, but you should probably not rely on this.

=cut

sub _recurse;

sub readonly    { _recurse 1, @_; $_[0] }
sub readwrite   { _recurse 0, @_; $_[0] }

my %immortal =
    map +(refaddr $_, 1),
    \undef, \!1, \!0;

sub _recurse {
    my ($ro, $r, $o) = @_;

    my $x = refaddr $r
        or croak "readonly needs a reference";

    exists $o->{skip}{$x}       and return $r;
    $o->{skip}{$x} = 1;

    !$ro && $immortal{$x}       and return $r;
    blessed $r && !$o->{peek}   and return $r;

    my $t = reftype $r;
    #debug $t, $x, pp $r;

    # It's not clear it's meaningful to SvREADONLY these types. A qr//
    # is a ref to a REGEXP, so a scalar holding one can be made
    # readonly; the REGEXP itself would normally be skipped anyway
    # because it's blessed.
    $t eq "CODE" || $t eq "IO" || $t eq "FORMAT" || $t eq "REGEXP"
        and return $r;

    # Look for r magic pre-5.12
    RX_MAGIC and is_regexp($r) and return $r;

    unless ($o->{shallow}) {
        if ($t eq "REF") {
            _recurse $ro, $$r, $o;
        }
        if ($t eq "ARRAY") {
            _recurse $ro, \$_, $o for @$r;
        }
        if ($t eq "HASH") {
            &Internals::SvREADONLY($r, 0);
            _recurse $ro, \$_, $o for values %$r;
            Hash::Util::lock_keys(%$r);
        }
        if ($t eq "GLOB") {
            *$r{$_} and _recurse $ro, *$r{$_}, $o 
                for qw/SCALAR ARRAY HASH/;
        }
    }

    # bleeding prototypes...
    &Internals::SvREADONLY($r, $ro);
    #debug "READONLY", $r, &Internals::SvREADONLY($r);
}

=head2 Readonly

    Readonly my $x, 1;
    Readonly my @y, 2, 3, 4;
    Readonly my %z, foo => 5;

This is a compatibility shim for L<Readonly>. It is prototyped to take a
reference to its first argument, and assigns the rest of the argument
list to that argument before making the whole thing readonly.

=cut

sub Readonly (\[$@%]@) {
    my $r = shift;
    my $t = reftype $r
        or croak "Readonly needs a reference";

    if ($t eq "SCALAR" or $t eq "REF") {
        $$r = $_[0];
    }
    if ($t eq "ARRAY") {
        @$r = @_;
    }
    if ($t eq "HASH") {
        %$r = @_;
    }
    if ($t eq "GLOB") {
        *$r = $_[0];
    }

    readonly $r;
}

1;

=head1 EXPORTS

C<readonly> is exported by default. C<readwrite> and C<Readonly> are
exported on request.

=head1 SEE ALSO

L<Readonly> was the first module to supply readonly values. It was
written for Perl 5.6, and as a result the interface and implementation
are both rather clunky. With L<Readonly::XS> the performance is improved
for scalar varuables, but arrays and hashes still use a tied
implementation which is very slow.

L<Const::Fast> is a greatly improved reaoonly module which uses perl's
internal C<SvREADONLY> flag instead of ties. The differences between
this module and L<Const::Fast> are:

=over 4

=item *

The C<readonly> function does not insist on performing an assignment, it
just returns a readonly value. This is, IMHO, more useful, since it
means a readonly value can be returned from a function. In particular,
it is often useful to return a readonly value from a builder method.

=item *

It does not attempt to clone deep structures. If C<Clone::Fast> is
applied to a structure with cross-links it will clone the whole thing,
on the principle that parts of the graph may be shared with something
else which should not be readonly. This module takes the approach that
if you asked for something to be made readonly you meant it, and if it
points to something it shouldn't that's your mistake.

=back

=head1 BUGS

Please report bugs to <L<bug-Readonly-Tiny@rt.cpan.org>>.

=head1 AUTHOR

Ben Morrow <ben@morrow.me.uk>

=head1 COPYRIGHT

Copyright 2015 Ben Morrow.

Released under the 2-clause BSD licence.

