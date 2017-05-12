package Pod::Abstract::Tree;
use strict;

our $VERSION = '0.20';

=head1 NAME

Pod::Abstract::Tree - Manage a level of Pod document tree Nodes.

=head1 DESCRIPTION

Pod::Abstract::Tree keeps track of a set of Pod::Abstract::Node
elements, and allows manipulation of that list of elements. Elements
are stored in an ordered set - a single node can appear once only in a
single document tree, so inserting a node at a point will also remove
it from it's previous location.

This is an internal class to Pod::Abstract::Node, and should not
generally be used externally.

=head1 METHODS

=cut

sub new {
    my $class = shift;

    return bless {
        id_map => { },
        nodes => [ ],
    }, $class;
}

=head2 detach

 $tree->detach($node);

Unparent the C<$node> from C<$tree>. All other elements will be
shifted to fill the empty spot.

=cut

sub detach {
    my $self = shift;
    my $node = shift;
    my $id_map = $self->{id_map};
    my $serial = $node->serial;
    
    my $idx = $id_map->{$node->serial};
    return 0 unless defined $idx;
    die "Wrong node ($idx/$serial)! Got: ", $self->{nodes}[$idx]->serial
        unless $self->{nodes}[$idx]->serial == $serial;
    
    # Node is defined, remove it:
    splice @{$self->{nodes}},$idx,1;
    delete $id_map->{$serial};
    
    #  Move all following nodes back by 1
    my $length = scalar @{$self->{nodes}};
    for(my $i = $idx; $i < $length; $i ++) {
        my $s = $self->{nodes}[$i]->serial;
        $id_map->{$s} --;
    }
    
    # Node now has no parent.
    $node->parent(undef);
    return $node;
}

=head2 push

Add an element to the end of the node list.

=cut

sub push {
    my $self = shift;
    my $node = shift;
    
    if($node->attached) {
        $node->detach;
        warn "Implicit detach of node on push";
    }
    
    my $s = $node->serial;
    push @{$self->{nodes}}, $node;
    $self->{id_map}{$s} = $#{$self->{nodes}};
    return 1;
}

=head2 pop

Remove an element from the end of the node list.

=cut

sub pop {
    my $self = shift;
    
    my $node = pop @{$self->{nodes}};
    my $s = $node->serial;
    delete $self->{id_map}{$s};
    $node->parent(undef);

    return $node;
}

=head2 insert_before

 $tree->insert_before($target,$node);

Insert C<$node> before C<$target>. Both must be children of C<$tree>

=cut

sub insert_before {
    my $self = shift;
    my $target = shift;
    my $node = shift;
    
    my $idx = $self->{id_map}{$target->serial};
    return 0 unless defined $idx;
    
    splice(@{$self->{nodes}}, $idx, 0, $node);
    $self->{id_map}{$node->serial} = $idx;

    # Push all following nodes forwards by 1.
    my $length = scalar @{$self->{nodes}};
    for( my $i = $idx + 1; $i < $length; $i ++) {
        my $s = $self->{nodes}[$i]->serial;
        $self->{id_map}{$s} ++;
    }
    return 1;
}

=head2 insert_after

 $tree->insert_after($target,$node);

Insert C<$node> after C<$target>. Both must be children of C<$tree>

=cut

sub insert_after {
    my $self = shift;
    my $target = shift;
    my $node = shift;
    
    my $idx = $self->{id_map}{$target->serial};
    die $target->serial, " not in index ", join(", ", keys %{$self->{id_map}})
        unless defined $idx;
    my $last_idx = $#{$self->{nodes}};
    if($idx == $last_idx) {
        return $self->push($node);
    } else {
        my $before_target = $self->{nodes}[$idx + 1];
        return $self->insert_before($before_target, $node);
    }
}

=head2 unshift

Remove the first node from the node list and return it.

Unshift takes linear time - it has to relocate every other element in
id_map so that they stay in line.

=cut

sub unshift {
    my $self = shift;
    my $node = shift;

    if($node->attached) {
        $node->detach;
        warn "Implicit detach of node on unshift";
    }
    
    my $s = $node->serial;
    foreach my $k (keys %{$self->{id_map}}) {
        $self->{id_map}{$k} ++;
    }
    unshift @{$self->{nodes}}, $node;
    $self->{id_map}{$s} = 0;
    return 1;
}

=head2 children

Returns the in-order node list.

=cut

sub children {
    my $self = shift;
    return @{$self->{nodes}};
}

=head2 index_relative

 my $node = $tree->index_relative($target, $offset);

This method will return a node at an offset of $offset (which may be
negative) from this tree structure. If there is no such node, undef
will be returned. For example, an offset of 1 will give the following
element of $node.

=cut

sub index_relative {
    my $self = shift;
    my $node = shift;
    my $index = shift;
    my $serial = $node->serial;
    
    die "index_relative called with unattached node"
        unless $node->attached;
    my $node_idx = $self->{id_map}{$serial};
    die "index_relative called with node not present in tree"
        unless defined $node_idx;
    my $real_index = $node_idx + $index;
    my $n_nodes = scalar @{$self->{nodes}};
    if($real_index >= 0 && $real_index < $n_nodes) {
        return $self->{nodes}[$real_index];
    } else {
        return undef;
    }
}

=head1 AUTHOR

Ben Lilburne <bnej@mac.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Ben Lilburne

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
