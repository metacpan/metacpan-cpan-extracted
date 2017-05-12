=head1 NAME

MooseX::Types::Ro - Moose type constraints for read-only containers

=head1 SYNOPSIS

    package Foo;

    use Moose;
    use MooseX::Types::Ro qw(RoArrayRef RoHashRef);

    has array => ( is => 'ro', isa => RoArrayRef, coerce => 1 );
    has hash => ( is => 'ro', isa => RoHashRef, coerce => 1 );

    my $foo = Foo->new(array => [1, 2, 3], hash => { foo => 1, bar => 2 });

    # These all throw exceptions now:

    $foo->array->[0] = 42;
    $foo->array->[3] = 42;
    push @{$foo->array}, 69;

    $foo->hash->{bar} = 3;
    delete $foo->hash->{bar};p
    $foo->hash->{baz} = 4;

=head1 DESCRIPTION

L<MooseX::Types::Ro> provides L<Moose> type constraints for read-only
array and hash references.  Attempting to modify the values in any way,
including adding or deleting from the arrays and hashes will throw an
exception.

=cut

package MooseX::Types::Ro;

use strict;
use warnings;

our $VERSION = '0.002';
$VERSION = eval $VERSION;

use MooseX::Types -declare => [qw(RoHashRef RoArrayRef)];
use MooseX::Types::Moose qw(HashRef ArrayRef Value Undef);
use Internals qw(SetReadOnly IsWriteProtected);
use List::MoreUtils qw(all);
use Scalar::Util qw(blessed);

use namespace::autoclean;

=head1 TYPES

=head2 RoArrayRef

A subtype of C<ArrayRef> in which the array itself and all the elements
are read-only.  Coerces from C<ArrayRef> by making a shallow copy and
marking it read-only.

=cut

subtype RoArrayRef,
    as ArrayRef,
    where { IsWriteProtected($_) && all { IsWriteProtected(\$_) } @{$_} },
    message { "Array or values are writable" };

coerce RoArrayRef,
    from ArrayRef,
    via {
        my @copy = @{$_};
        SetReadOnly(\@copy);
        SetReadOnly(\$_) foreach @copy;
        return \@copy;
    };

=head2 RoHashRef

A subtype of C<HashRef> in which the hash itself and all the values are
read-only.  Coerces from HashRef by making a shallow copy and marking it
read-only.

=cut

subtype RoHashRef,
    as HashRef,
    where { IsWriteProtected($_) && all { IsWriteProtected(\$_) } values %{$_} },
    message { "Hash or values are writable" };

coerce RoHashRef,
    from HashRef,
    via {
        my %copy = %{$_};
        SetReadOnly(\%copy);
        SetReadOnly(\$_) foreach values %copy;
        return \%copy;
    };

=head1 SEE ALSO

L<MooseX::Types>,
L<MooseX::Types::Moose>,
L<Moose::Util::TypeConstraints>,
L<Internals>

=head1 AUTHOR

Dagfinn Ilmari MannsE<aring>ker <ilmari@ilmari.org>.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010 Dagfinn Ilmari MannsE<aring>ker <ilmari@ilmari.org>.

This program is free software; you can redistribute and/or modify it under
the same terms as perl itself.

=cut

1;

