package Repository::Simple::Node;

use strict;
use warnings;

use Carp;
use Readonly;
use Repository::Simple::Permission;
use Repository::Simple::Property;
use Repository::Simple::Util qw( basename dirname normalize_path );

our $VERSION = '0.06';

our @CARP_NOT = qw( Repository::Simple::Util );

=head1 NAME

Repository::Simple::Node - Repository nodes

=head1 SYNOPSIS

The following code can be found in F<ex/print_nodes.pl>:

  use Repository::Simple;

  sub print_node;

  my $repository = Repository::Simple->attach(
      FileSystem => root => $ARGV[0],
  );

  my $node = $repository->root_node;
  print_node($node, 0);

  sub print_node {
      my ($node, $depth) = @_;
      
      print "\t" x $depth, " * ", $node->name, "\n";

      for my $child ($node->nodes) {
          print_node($child, $depth + 1);
      }

      for my $p ($node->properties) {
          print "\t" x $depth, "\t * ", $p->name, " = ", $p->value, "\n";
      }
  }

=head1 DESCRIPTION

Each instance of this class describes a node in a repository. A node is basically a unit of information described by a path.

To retrieve an instance of this type, you never construct this object directly. Instead, use one of the node access methods in L<Repository::Simple> and L<Repository::Simple::Node>:

  my $root = $repository->root_node;
  my @children = $root->nodes;

=cut

# $node = Repository::Simple::Node->new($repository, $path)
#
# Create a new node object.
#
sub new {
    my ($class, $repository, $path) = @_;

    return bless {
        repository => $repository,
        path       => $path,
    }, $class;
}

=head2 METHODS

=over

=item $repository = $node-E<gt>repository

Returns the L<Repository::Simple> object to which this node belongs.

=cut

sub repository {
    my $self = shift;
    return $self->{repository};
}

=item $node = $type-E<gt>parent

Fetch the node that is the parent of this node. This will always return a node, even for the root node. The root node is the parent of itself. 

If you consider time travel, you may wish to stop yourself before you think too hard on the implications and gross yourself out.

=cut

sub parent {
    my $self = shift;

    my $parent_path = dirname($self->path);

    $self->repository->check_permission($parent_path, $READ);

    return Repository::Simple::Node->new(
        $self->repository, 
        $parent_path,
    );
}

=item $name = $node-E<gt>name

Fetch the name of the node. This will always be the last element of the node's path. That is, if the path of the node is:

  /foo/bar/baz

then the name of the node is:

  baz

In this API it has been decided that the root node will be represented by the string "/" to match with the normal Unix practice of naming the root tree object. The root node must have this name and no other node may have this name.

=cut

sub name {
    my ($self) = @_;
    return $self->{name} if $self->{name};
    return $self->{name} = basename($self->{path});
}

=item $path = $node-E<gt>path

This returns the full path from the root of the tree to this node.

=cut

sub path {
    my ($self) = @_;
    return $self->{path};
}

=item @nodes = $node-E<gt>nodes

Returns all the child nodes of this node.

=cut

sub nodes {
    my ($self) = @_;

    my $path       = $self->path;
    my $repository = $self->repository;
    my @node_names = $repository->engine->nodes_in($path);

    my @nodes;
    for my $node_name (@node_names) {
        eval {
            my $node_path = normalize_path($path, $node_name);
            $repository->check_permission($node_path, $READ);
            push @nodes, Repository::Simple::Node->new($repository, $node_path);
        };

        # Ignore errors, just don't include the unreadable nodes
        carp $@ if $@;
    }

    return @nodes;
}

=item @properties = $node-E<gt>properties

Returns all the proeprties of this node.

=cut

sub properties {
    my ($self) = @_;
    
    my $path           = $self->path;
    my $repository     = $self->repository;
    my @property_names = $repository->engine->properties_in($path);

    my @properties;
    for my $property_name (@property_names) {
        eval {
            my $property_path = normalize_path($path, $property_name);
            $repository->check_permission($path, $READ);
            push @properties, 
                Repository::Simple::Property->new($self, $property_name);
        };

        # Ignore errors, just don't list those properties
        carp $@ if $@;
    }

    return @properties;
}

=item $type = $node-E<gt>type

Returns the L<Repository::Simple::Type::Node> object describing the node.

=cut

sub type {
    my ($self) = @_;
    return $self->repository->engine->node_type_of($self->{path});
}

=back

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2005 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
