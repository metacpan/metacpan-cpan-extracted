package TPath::Forester::Ref::Node;
{
  $TPath::Forester::Ref::Node::VERSION = '0.004';
}

# ABSTRACT: a node that represents a node in a plain struct


use v5.10;
use Moose;
use namespace::autoclean;
use Scalar::Util qw(looks_like_number);
use TPath::Forester::Ref::Root;


has value => ( is => 'ro', required => 1 );


has tag => ( is => 'ro', isa => 'Maybe[Str]' );


has children => (
    is      => 'ro',
    isa     => 'ArrayRef[TPath::Forester::Ref::Node]',
    default => sub { [] }
);


has type => ( is => 'ro', isa => 'Str', lazy => 1, builder => '_type_builder' );

has _root => (
    is       => 'ro',
    does     => 'TPath::Forester::Ref::Root',
    weak_ref => 1,
    writer   => '_add_root'
);


has is_first => ( is => 'ro', isa => 'Bool', default => 1, writer => '_first' );


has is_repeated => ( is => 'ro', isa => 'Int', writer => '_repeats' );


has is_ref => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    builder => '_is_ref_builder'
);
sub _is_ref_builder { ref $_[0]->value ? 1 : 0 }


has is_root => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    builder => '_is_root_builder'
);

sub _is_root_builder { $_[0]->does('TPath::Forester::Ref::Root') }


has is_leaf => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    builder => '_is_leaf_builder'
);

sub _is_leaf_builder {
    my $self = shift;
    if ( $self->is_repeated && !$self->is_first ) {
        my $first = $self->_root->_cycle_check( $self, 1 );
        return $first->is_root;
    }
    return @{ $self->children } && 1;
}

sub _type_builder {
    my $self  = shift;
    my $value = $self->value;
    return 'undef' unless defined $value;
    return 'object' if blessed $value;
    my $ref = ref $value;
    for ($ref) {
        when ('HASH')   { return 'hash' }
        when ('ARRAY')  { return 'array' }
        when ('CODE')   { return 'code' }
        when ('SCALAR') { return 'scalar' }
        when ('GLOB')   { return 'glob' }
    }
    return 'num' if looks_like_number $value;
    return 'string';
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

TPath::Forester::Ref::Node - a node that represents a node in a plain struct

=head1 VERSION

version 0.004

=head1 DESCRIPTION

A container for the elements of a Perl data structure. Hash references are
treated as lists of key-value pairs in alphabetical order.

=head1 ATTRIBUTES

=head2 value

The value this node represents.

=head2 tag

The hash key mapping of this node's value if it represents a key-value
pair in a hash.

=head2 children

The node's children, if any.

=head2 type

The type of value held by this node:

=over 2

=item hash

=item array

=item code

=item scalar

=item glob

=item object

A blessed reference.

=item undef

The C<undef> value.

=item num

If it isn't a reference and it looks like a number according to scalar util.

=item string

Everything else.

=back

=head2 is_first

Whether this is the first instance of this reference (or it isn't a reference).

=head2 is_repeated

Whether there are multiple references to this value. Something may be both first and
repeated, but it must be repeated if it is not first. The actual value returned is
the position of the reference in the repetition order. The tree is walked from left
to right counting parents before children.

When a repeat is found, it is treated as a leaf. This ensures the nodes form a tree.

=head2 is_ref

Whether the value held by the node is a reference.

=head2 is_root

Whether this is the root node.

=head2 is_leaf

Whether this is a leaf node. 

If this is a non-initial repeated reference, it is considered a leaf
only if the initial reference is a leaf.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
