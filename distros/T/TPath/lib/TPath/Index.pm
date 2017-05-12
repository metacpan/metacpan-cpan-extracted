# ABSTRACT: tree-specific database

package TPath::Index;
$TPath::Index::VERSION = '1.007';

use Moose;
use Scalar::Util qw(refaddr weaken);
use namespace::autoclean;

use TPath::TypeConstraints;

with 'TPath::TypeCheck';


has f => ( is => 'ro', does => 'TPath::Forester', required => 1 );


has indexed => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has _is_indexed => ( is => 'rw', isa => 'Bool', default => 0 );

# Map from children to their parents.
has cp_index => ( is => 'ro', isa => 'HashRef', default => sub { {} } );

# descendant index
has d_index => ( is => 'ro', isa => 'HashRef', default => sub {{}});

# kid index
has k_index => ( is => 'ro', isa => 'HashRef', default => sub {{}});


has root => ( is => 'ro', required => 1 );

# micro-optimization
has _root_ref => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { refaddr $_[0]->root }
);


sub is_root {
    my ( $self, $n ) = @_;
    return refaddr $n == $self->_root_ref;
}

sub BUILD {
    my $self = shift;
    confess 'forester node type is '
      . $self->f->node_type
      . ' while index node type is '
      . $self->node_type
      unless ( $self->f->node_type // '' ) eq ( $self->node_type // '' );
}


sub index {
    my $self = shift;
    return if $self->_is_indexed;
    $self->walk( $self->root );
    $self->_is_indexed(1);
}

sub walk {
    my ( $self, $n ) = @_;
    my $children = $self->f->_decontextualized_kids( $n, $self );
    $self->n_index($n);
    for my $c (@$children) {
        $self->pc_index( $n, $c );
        $self->walk($c);
    }
}


sub parent {
    my ( $self, $n ) = @_;
    return $self->cp_index->{ refaddr $n };
}

sub n_index {
    my ( $self, $n ) = @_;
    my $id = $self->id($n);
    if ( defined $id ) {
        $self->indexed->{$id} = $n;
    }
}


sub pc_index {
    my ( $self, $n, $c ) = @_;
    confess "$c must be a reference" unless ref $c;
    my $ref = $n;
    weaken $ref;
    $self->cp_index->{ refaddr $c} = $ref;
}


sub id {
    my ( $self, $n ) = @_;
    $self->_typecheck($n);
    return $self->f->id($n);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Index - tree-specific database

=head1 VERSION

version 1.007

=head1 SYNOPSIS

  my $f = MyForester->new;      # hypothetical forester for my sort of tree
  my $root = next_tree();       # generate my sort of tree
  my $index = $f->index($root); # construct reusable index for $root

=head1 DESCRIPTION

A cache of information about a particular tree. Reuse indices to save effort.

The chief function of an index is to enable an expression to map a node to its ancestors for those
trees that provide this mapping themselves. All tree-specific caches belong here, though.

You should regard the methods and attributes of a L<TPath::Index> as private. The public function
of an index is to be the optional second argument of a L<TPath::Expression>'s C<select> method.

=head1 ATTRIBUTES

=head2 indexed

The map from ids to nodes.

=head2 root

The root of the indexed tree.

=head1 METHODS

=head2 is_root

Expects a node. Returns whether this node is the root of the tree
indexed by this index.

=head2 index

Cause this index to walk its tree and perform all necessary indexation.

=head2 parent

Expects a node and returns the parent of this node.

=head2 pc_index

Record the link from child to parent. If this index is unnecessary for a
particular variety of tree -- nodes know their parents -- then you should
override this method to be a no-op. It assumes all nodes
are references and will throw an error if this is not the case.

=head2 id

Returns the unique identifier, if any, that identifies this node. This method
delegates to the forester's C<id> method.

=attribute f

The L<TPath::Forester> that generated this index.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
