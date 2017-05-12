package Set::Tiny;

use 5.004;
use strict;

require Exporter;
@Set::Tiny::ISA = qw(Exporter);
@Set::Tiny::EXPORT_OK = qw(set);

$Set::Tiny::VERSION = '0.04';

sub new {
    my $class = shift;
    my %self;
    @self{@_} = ();
    return bless \%self, $class;
}

sub set {
    if (ref($_[0]) eq "Set::Tiny") {
        return $_[0]->clone();
    }
    elsif (ref($_[0]) eq 'ARRAY') {
        return Set::Tiny->new(@{$_[0]});
    }
    else {
        return Set::Tiny->new(@_);
    }
}

sub as_string { "(" . join(" ", sort keys %{$_[0]}) . ")" }

sub size { scalar keys %{$_[0]} }

sub element { exists $_[0]->{$_[1]} ? $_[1] : () }

sub elements { keys %{$_[0]} }

sub contains {
    my $self = shift;
    exists $self->{$_} or return for @_;
    return 1;
}

sub clone {
    my $class = ref $_[0];
    return $class->new( keys %{$_[0]} );
}

sub clear {
    %{$_[0]} = ();
    return $_[0];
}

sub insert {
    my $self = shift;
    @{$self}{@_} = ();
    return $self;
}

sub remove {
    my $self = shift;
    delete @{$self}{@_};
    return $self;
}

sub invert {
    my $self = shift;
    exists $self->{$_} ? delete $self->{$_} : ($self->{$_} = undef) for @_;
    return $self;
}

sub is_null { ! %{$_[0]} }

sub is_subset { $_[1]->contains( keys %{$_[0]} ) }

sub is_proper_subset { $_[0]->size < $_[1]->size && $_[0]->is_subset($_[1]) }

sub is_superset { $_[1]->is_subset($_[0]) }

sub is_proper_superset { $_[0]->size > $_[1]->size && $_[1]->is_subset($_[0]) }

sub is_equal { $_[1]->is_subset($_[0]) && $_[0]->is_subset($_[1]) }

sub is_disjoint { ! $_[0]->intersection($_[1])->size }

sub is_properly_intersecting {
    ! $_[0]->is_disjoint($_[1])
      && $_[0]->difference($_[1])->size
      && $_[1]->difference($_[0])->size
}

sub difference { $_[0]->clone->remove(keys %{$_[1]}) }

sub union {
    my $class = ref $_[0];
    return $class->new( keys %{$_[0]}, keys %{$_[1]} );
}

sub intersection {
    my $class = ref $_[0];
    return $class->new( grep { exists($_[0]->{$_}) } keys %{$_[1]} );
}

sub intersection2 {
    my $class = ref $_[0];
    my ($a, $b) = $_[0]->size > $_[1]->size ? ($_[0], $_[1]) : ($_[1], $_[0]);
    return $class->new( grep { exists($a->{$_}) } keys %{$b} );
}

sub symmetric_difference { $_[0]->clone->invert(keys %{$_[1]}) }

{
    *copy = \&clone;
    *has = \&contains;
    *member = \&element;
    *members = \&elements;
    *delete = \&remove;
    *is_empty = \&is_null;
    *unique = \&symmetric_difference;
}

1;

__END__

=head1 NAME

Set::Tiny - Simple sets of strings

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    use Set::Tiny;

    my $s1 = Set::Tiny->new(qw( a b c ));
    my $s2 = Set::Tiny->new(qw( b c d ));

    my $u  = $s1->union($s2);
    my $i  = $s1->intersection($s2);
    my $s  = $s1->symmetric_difference($s2);

    print $u->as_string; # (a b c d)
    print $i->as_string; # (b c)
    print $s->as_string; # (a d)

    print "i is a subset of s1"   if $i->is_subset($s1);
    print "u is a superset of s1" if $u->is_superset($s1);

    # or using the shorter initializer:

    use Set::Tiny qw( set );

    my $s1 = set(qw( a b c ));
    my $s2 = set([1, 2, 3]);

=head1 DESCRIPTION

Set::Tiny is a thin wrapper around regular Perl hashes to perform often needed
set operations, such as testing two sets of strings for equality, or checking
whether one is contained within the other.

For a more complete implementation of mathematical set theory, see
L<Set::Scalar>. For sets of arbitrary objects, see L<Set::Object>.

=head2 Why Set::Tiny?

=over

=item Convenience

Set::Tiny aims to provide a convenient interface to commonly used set
operations, which you would usually implement using regular hashes and a couple
of C<for> loops (in fact, that's exactly what Set::Tiny does).

=item Speed

The price in performance you pay for this convenience when using a
full-featured set implementation like L<Set::Scalar> is way too high if you
don't actually need the advanced functionality it offers.
Run F<examples/benchmark.pl> for a (non-representative) comparison
between different C<Set::> modules.

=item Ease of use

L<Set::Object> offers better performance than L<Set::Scalar>, but needs a C
compiler to install. Set::Tiny has no dependencies and contains no C code.

=back

=head1 EXPORTABLE FUNCTIONS

=head2 set( [I<list or arrayref>] )

If you request it, Set::Tiny can export a function C<set()>, which lets you
create a Set::Tiny instance in a more compact form.

Unlike the constructor, this function also accepts the set elements as an array
reference.

If you pass an existing Set::Tiny to the initializer, it creates a clone of the set
and returns that.

=head1 METHODS

Note that all methods that expect a I<list> of set elements stringify
their arguments before inserting them into the set.

=head2 new( [I<list>] )

Class method. Returns a new Set::Tiny object, initialized with the strings in
I<list>, or the empty set if I<list> is empty.

=head2 clone

=head2 copy

Returns a new set with the same elements as this one.

=head2 insert( [I<list>] )

Inserts the elements in I<list> into the set.

=head2 delete( [I<list>] )

=head2 remove( [I<list>] )

Removes the elements in I<list> from the set. Elements that are not
members of the set are ignored.

=head2 invert( [I<list>] )

For each element in I<list>, if it is already a member of the set,
deletes it from the set, else insert it into the set.

=head2 clear

Removes all elements from the set.

=head2 as_string

Returns a string representation of the set.

=head2 elements

=head2 members

Returns the (unordered) list of elements.

=head2 size

Returns the number of elements.

=head2 has( [I<list>] )

=head2 contains( [I<list>] )

Returns true if B<all> of the elements in I<list> are members of the set. If
I<list> is empty, returns true.

=head2 element( [I<string>] )

=head2 member( [I<string>] )

Returns the string if it is contained in the set.

=head2 is_null

=head2 is_empty

Returns true if the set is the empty set.

=head2 union( I<set> )

Returns a new set containing both the elements of this set and I<set>.

=head2 intersection( I<set> )

Returns a new set containing the elements that are present in both this
set and I<set>.

=head2 intersection2( I<set> )

Like C<intersection()>, but orders the sets by size before comparing their
elements. This results in a small overhead for small, evenly sized sets, but
a large speedup when comparing bigger (~ 100 elements) and very unevenly
sized sets.

=head2 difference( I<set> )

Returns a new set containing the elements of this set with the elements
of I<set> removed.

=head2 unique( I<set> )

=head2 symmetric_difference( I<set> )

Returns a new set containing the elements that are present in either this set
or I<set>, but not in both.

=head2 is_equal( I<set> )

Returns true if this set contains the same elements as I<set>.

=head2 is_disjoint( I<set> )

Returns true if this set has no elements in common with I<set>. Note that the
empty set is disjoint to any other set.

=head2 is_properly_intersecting( I<set> )

Returns true if this set has elements in common with I<set>, but both
also contain elements that they have not in common with each other.

=head2 is_proper_subset( I<set> )

Returns true if this set is a proper subset of I<set>.

=head2 is_proper_superset( I<set> )

Returns true if this set is a proper superset of I<set>.

=head2 is_subset( I<set> )

Returns true if this set is a subset of I<set>.

=head2 is_superset( I<set> )

Returns true if this set is a superset of I<set>.

=head1 AUTHOR

Stanis Trendelenburg, C<< <trendels at cpan.org> >>

=head1 CREDITS

Thanks to Adam Kennedy for advice on how to make this module C<Tiny>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-set-tiny at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Set-Tiny>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Stanis Trendelenburg, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Set::Scalar>, L<Set::Object>
