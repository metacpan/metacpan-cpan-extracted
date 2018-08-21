package Set::Hash::Keys;

=head1 NAME

Set::Hash::Keys - Treat Hashes as Sets, based on the keys only

=head1 VERSION 0.01

=cut

our $VERSION = '0.01';

use List::Util 'reduce';

=SYNOPSIS

    use Set::Hash::Keys;
    my $set1 = Set::Hash::Keys->new(
        foo => 'blue',
        bar => 'july',
    );
    my $set2 = Set::Hash::Keys->new(
        foo => 'bike',
        baz => 'fish',
    );
    
    my $set3 = $set1 + $set2; # union
    #   foo => 'bike', # only the last remains
    #   bar => 'july',
    #   baz => 'fish',
    
    my $set4 = $set1 * $set2; # intersection
    #   foo => 'bike', # only the last remains
    
    my $set5 = $set1 - $set2; # difference
    #   bar => 'july',
    
    my ($sub1, $sub2) = $set1 / $set2;
    
    my $set5 += { qux => 'moon', ... }; # add new elements
    #   bar => 'july',
    #   qux => 'moon',
    
    my $set3 -= { foo => 'sofa', ... };
    #   bar => 'july',
    #   baz => 'fish',
    

=head1 DESCRIPTION

This module will help to check two or more hashes for which keys they have in
common and which not. It is all based on 'Set Theory' and works as expected. But
keep in mind that it only considders the keys to create unions, differences or
intersections. And that just like ordinary hash operations, the last key/value
pair wins.

Other moules will treat operations in respect to the values too, and only will
do a difference or union if both key and value are the same in both hashes or.
sets.

=cut

use overload(
    '+'   => sub { pop @_ ?        union($_[1],$_[0]) :        union($_[0],$_[1]) },
    '-'   => sub { pop @_ ?   difference($_[1],$_[0]) :   difference($_[0],$_[1]) },
    '*'   => sub { pop @_ ? intersection($_[1],$_[0]) : intersection($_[0],$_[1]) },
    '/'   => sub { pop @_ ?    exclusive($_[1],$_[0]) :    exclusive($_[0],$_[1]) },
    '%'   => sub {                                       symmetrical($_[0],$_[1]) },
);

=head1 IMPORTS

For convenience, the C<set_hash> constructor has been imported in your current
namespace, so you can do:

    my $set_h = set_hash( foo => 'boat', bar => 'just' );

All other functions mentioned below can be imported individually, or using the
C<:all> tag.

=cut

use Exporter 'import';

@EXPORT = qw (
    &set_hash
);

@EXPORT_OK = qw (
    &union
    &intersection
    &difference
    &exclusive
    &symmetrical
);

%EXPORT_TAGS = (
    'all' => \@EXPORT_OK,
);

sub set_hash {
    __PACKAGE__->new(@_)
}

sub new {
    my $class = shift;
    my %data = @_;
    
    return bless \%data, $class
}

=head1 CONSTRUCTORS

=cut

=head2 new

=cut

=head1 SET OPERATIONS

The following Set operations are provided as functions, that will take a list of
sets or HashRef's, or as binary (set) operators (that requires at least one of
the two being a L<Set::Hash::Keys> or as, or as an assignment operator. Usually
the function or set-operator will return a single L<Set::Hash::Keys> object. But
L<difference>, and L<exclusive> will return a list off object when evaluated in
list context. See below for how to use each and every set-operation.

See L<https://en.wikipedia.org/wiki/Set_(mathematics)#Basic_operations|Basic Set operations>

=cut

=head2 union

Based on the keys, this will produce a new unified L<Set::Hash::Keys> object
from the sets passed in.

    my $set_1 = union(
        {
            foo => 'blue',
            bar => 'july',
        },
        {
            foo => 'bike',
            baz => 'fish',
        },
        {
            qux => 'wood',
        },
    );
    print values %$set_1; # july, fish, bike, wood
    
    my $set_2 = $set_1 + { bar => 'hand' };
    print values %$set_2; # hand, fish, bike, wood
    
    $set_2 += { foo => 'wipe', xyz => 'bell' }
    print values %$set_2; # hand, fish, wipe, wood, bell

NOTE: like ordinary hashes, when using the same key more than once, the value of
the last one used will remain.

=cut

sub union {
    return unless defined $_[0];

    my $hash_ref = reduce {
        +{ %$a, %$b }
    } @_;
    
    __PACKAGE__->new( %$hash_ref );
}

=head2 intersection

The C<intersection> will produce a L<Set::Hash::Keys> thas has all keys in
common.

    my $set_1 = intersection(
        {
            foo => 'blue',
            bar => 'july',
        },
        {
            foo => 'bike',
            baz => 'fish',
        },
        {
            qux => 'wood',
        },
    );
    print values %$set_1; # bike
    
    my $set_2 = $set_1 * { foo => 'hand', qux => 'just' };
    print values %$set_2; # hand
    
    $set_1 *= { foo => 'wipe', xyz => 'bell' }
    print values %$set_1; # wipe

NOTE: the value stored with any key, will be the value of the last set passed in

=cut

sub intersection {
    return unless defined $_[0];

    my $hash_ref = reduce {
        +{
            map {
                $_, $b->{$_}
            } grep {
                exists $b->{$_}
            } keys %$a
        }
    } @_;
    
    __PACKAGE__->new( %$hash_ref );
}

=head2 difference

In scalar context, this will produce a set from the first set, minus all
key/value pairs mentioned after the first set.

    my $set_1 = difference(
        {
            foo => 'blue',
            bar => 'july',
        },
        {
            foo => 'bike',
            baz => 'fish',
        },
        {
            qux => 'wood',
        },
    );
    print values %$set_1; # blue
    
    my $set_2 = $set_1 - { foo => 'hand', qux => 'just' };
    print values %$set_2; # -
    
    $set_1 -= { foo => 'wipe', xyz => 'bell' }
    print values %$set_1; # -

In list context, this will produce a list of set, where the difference is
produced by taking each passed in set, minus all the key/values from the other
sets. And as such producing a list of sets that have unique values per set.

    my @diffs = difference(
        {
            foo => 'blue',
            bar => 'july',
        },
        {
            foo => 'bike',
            baz => 'fish',
        },
        {
            qux => 'wood',
        },
    );
    print values %$diffs[0]; # july
    print values %$diffs[1]; # fish
    print values %$diffs[2]; # wood

NOTE: it will retain the key/value pairs from the first set.

=cut

sub difference {
    return unless defined $_[0];
    
    if ( wantarray() ) {
        my $sets_ref = [];
        for my $i ( 0 .. $#_ ) {
            my @other = @_; # make a clone, since splice mutates it
            my $set_i = splice( @other, $i, 1 );
            my $set_d = difference( $set_i, @other );   
            push @$sets_ref, $set_d;
        }
        return @$sets_ref
    }
    
    my $hash_ref = reduce {
        +{
            map {
                $_, $a->{$_}
            } grep {
                !exists $b->{$_}
            } keys %$a
        }
    } @_;
    
    __PACKAGE__->new( %$hash_ref )
}

=head2 exclusive

In list context, this will produce a list of sets where each set will only
contain those key/value pairs that are exclusive to each set, in respect to the
other sets in the argument list.

This is basicly the same as <difference> in list context.

In scalar context, it will return the C<union> of the before mentioned sets. So,
these key/value pairs are not mentioned in any other set.

    my $set_x = exclusive(
        {
            foo => 'blue',
            bar => 'july',
        },
        {
            foo => 'bike',
            baz => 'fish',
        },
        {
            qux => 'wood',
        },
    );
    print values %$set_x # july, fish, wood

    my $set_1 = Set::Hash::Keys->new( foo => 'blue', bar => 'july' );
    
    my $set_2 = $set / { foo => 'bike' , baz => 'fish' }
    print values %$set_2 # july, fish,
    
    $set_2 /= { qux => 'wood' };
    print values %$set_2 # july, fish, wood
    
    # for liust context, see `difference`

NOTE: for two sets, this basically produces the 'symmetrical difference'

=cut

sub exclusive {
    wantarray() ? difference( @_ ) : union( difference( @_ ) )
}

=head2 symmetrical

Produces the symmetrical difference from a list of sets. This is quite obvious
for two sets and returns those key/value pairs that are in either sets but not
in both.

However, when passing in multiple sets, this gets confusing, but basically it
will hold those key/value pairs that have an odd count, even counts will not be
in the set. For more information see proper Set Theory explenation.

As mentioned before, the symmetrical difference for two sets, is the same as the
union of the exclusive key/value pairs.

    my $set_s = symmetrical(
        {
            foo => 'blue',
            bar => 'july',
        },
        {
            foo => 'bike',
            baz => 'fish',
        },
        {
            foo => 'moon',
            baz => 'wood',
        },
    print values %$set_1 # july, moon

=cut

sub symmetrical {
    reduce { union ( difference( $a, $b ) ) } @_
}

=head1 AUTHOR

Theo J. van Hoesel L<Th.J.v.Hoesel@THEMA-MEDIA.nl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Theo J. van Hoesel - THEMA-MEDIA

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

Terms of the Perl programming language system itself

a) the GNU General Public License as published by the Free Software Foundation;
   either version 1, or (at your option) any later version, or
b) the "Artistic License"

=cut

1;
