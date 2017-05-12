package Solstice::Tree;

# $Id: Tree.pm 2412 2005-07-28 16:28:57Z mcrawfor $

=head1 NAME

Solstice::Tree - A basic tree object.

=head1 SYNOPSIS

  use Tree;

  my $tree = new Tree;

  my $child1 = new Tree;
  
  $tree->addChild($child1);
  $count = $tree->getChildCount();
  my @children = $tree->getChildren();
  my $child = $tree->getChild(0);

  my $parent = $tree->getParent();

  my $child2 = new Tree;
  $tree->addChild($child2);
  $tree->removeChild(1);

  my $boolean = $tree->isRoot();
  my $boolean = $tree->isLeaf();

  my $uniquelabelstring = $tree->getLabel();

  $child1->setValue("sample text");
  $child2->setValue(\$objectref);

  $tree->setValue("root");

  $tree->destroy();

=head1 DESCRIPTION

Provides a set of functionality for manipulating trees.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice);

use Solstice::List;

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 2412 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Constructor, creates a new tree object.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    
    $self->{'_parent'} = undef;
    $self->{'_children'} = Solstice::List->new();
    $self->{'_position'} = 0;

    return $self;
}

=item getParent()

Returns the parent of a child

=cut

sub getParent {
    my $self = shift;
    return defined $self->{'_parent'} ? $self->{'_parent'} : $self;
}

=item getChildren()

Returns an array of all children

=cut

sub getChildren {
    my $self = shift;
    
    # This is to ensure that during global destruction 
    # we don't get errors if things are destroyed out 
    # of order.
    if (defined $self->{'_children'}) {
        return @{$self->{'_children'}->getAll()};
    }
    return ();
}

sub iterator {
    my $self = shift;
    if (defined $self->{'_children'}) {
        return $self->{'_children'}->iterator();
    }
}


=item childExists($position)

Returns TRUE if a child exists at the passed $position, FALSE otherwise

=cut

sub childExists {
    my $self     = shift;
    my $position = shift;

    return $self->{'_children'}->exists($position);
}

=item addChild($child [, $position])

This will add a child to the tree, at optional $position. 
Returns 1 on success, and thanks to List, dies on error.

=cut

sub addChild {
    my $self = shift;
    my ($child, $position) = @_;
    
    if (!defined $child) {
        $self->warn('addChild(): Child is undefined');
        return FALSE;
    }

    if (!$self->isValidObject($child, 'Solstice::Tree')) {
        $self->warn('addChild(): Child is not a Solstice::Tree');
        return FALSE;
    }

    if (defined $position) {
        $self->{'_children'}->add($position, $child);
        
        for my $i ($position + 1 .. $self->{'_children'}->size() - 1) {
            my $current = $self->getChild($i);
            $current->{'_position'}++;
        }
    } else {
        $self->{'_children'}->push($child);
        $position = $self->{'_children'}->size() - 1;
    }
    $child->_setParent($self, $position);
    
    return TRUE;
}

=item removeChild($position, $return_tree)

This will remove a child, taking a flag on whether to return the tree that 
the child is the root of.  If the tree is not wanted, it will be destroyed.

=cut

sub removeChild {
    my $self = shift;
    my ($position, $return) = @_;

    return FALSE unless $self->childExists($position);
    
    my $child = $self->getChild($position);
    
    # Remove the child from the list, and decriment the position 
    # of any children after it in the list.
    $self->{'_children'}->remove($position);
    for my $i ($position .. $self->{'_children'}->size() - 1) {
        my $current = $self->getChild($i);
        $current->{'_position'}--;
    }
    
    if ($return) {
        $child->_setParent($child, 0);
        return $child;
    }
    $child->destroy();
    
    return TRUE;
}

=item addChildren($list)

=cut

sub addChildren {
    my $self = shift;
    my $list = shift;
    
    return FALSE unless defined $list;

    if ($self->isValidObject($list, 'Solstice::List')) {
        $list = $list->getAll();
    } else {
        return FALSE unless $self->isValidArrayRef($list);
    }

    for my $item (@$list) {
        $self->addChild($item);
    }
    
    return TRUE;
}

=item removeChildren()

Remove all children from this tree

=cut

sub removeChildren {
    my $self = shift;
    
    $self->{'_children'}->clear();
    
    return TRUE;
}

=item moveChild($oldposition, $newposition)

This will move a child from one position to another in the tree.  Does not wrap, i
will return 0 and do nothing if the old or new position is out of range.
Fixes positions, then uses List operations.  Returns 1 on success.

=cut

sub moveChild {
    my $self = shift;
    my ($oldposition, $newposition) = @_;

    return FALSE unless ($self->childExists($oldposition) and $self->childExists($newposition));
    return TRUE if ($oldposition == $newposition);

    if ($oldposition < $newposition) {
        for my $i ($oldposition .. $newposition) {
            $self->getChild($i)->{'_position'}--;
        }
    } else {
        for my $i ($newposition .. $oldposition - 1) {
            $self->getChild($i)->{'_position'}++;
        }
    }
    $self->getChild($oldposition)->{'_position'} = $newposition;
    
    $self->{'_children'}->move($oldposition, $newposition);

    return TRUE;
}

=item destroy()

Recursively destroys a tree, depth-first.

=cut

sub destroy {
    my $self = shift;
    
    if (defined $self->{'_children'}) {
        # In case things get destroyed out of order.
        for my $child (@{$self->{'_children'}->getAll()}) {
            if (defined $child) {
                $child->destroy();
            }
        }
        $self->{'_children'}->clear();
    }
    $self->{'_parent'} = undef;
    $self = undef;
    
    return TRUE;
}

=item getChildCount()

Returns the size of the children list.

=cut

sub getChildCount {
    my $self = shift;
    return $self->{'_children'}->size();
}

=item getTotalChildCount()

Returns the size of all children recursively down the list.

=cut

sub getTotalChildCount {
    my $self = shift;
    
    return 0 if $self->isLeaf();
    
    my $count = 0;
    foreach my $child ($self->getChildren()) {
        $count += $child->getTotalChildCount();
        $count++;
    }
    return $count;
}

=item getChild($position)

Returns the child at position n in the list.

=cut

sub getChild {
    my $self     = shift;
    my $position = shift;
    return $self->{'_children'}->get($position);
}

=item getPosition()

Returns the position of the node, relative to it's siblings.

=cut

sub getPosition {
    my $self = shift;
    return $self->{'_position'};
}

=item getRoot()

Recursively crawls up the tree until it hits the root, then returns it.

=cut

sub getRoot {
    my $self = shift;
    return $self if $self->isRoot();
    return $self->getParent()->getRoot();
}

=item isRoot()

Returns a boolean describing whether the current tree node is the root.

=cut

sub isRoot {
    my $self = shift;
    return ($self == $self->getParent());
}

=item isLeaf()

Returns a boolean describing whether the current tree node is a leaf.

=cut

sub isLeaf {
    my $self = shift;
    return !$self->{'_children'}->size();
}

=item isFirstChild()

Returns a boolean describing whether the current tree node is the first child.

=cut

sub isFirstChild {
    my $self = shift;
    return ($self->{'_position'} == 0);
}

=item isLastChild()

Returns a boolean describing whether the current tree node is the last child.

=cut

sub isLastChild {
    my $self = shift;
    return TRUE if $self->isRoot();
    return ($self->{'_position'} == ($self->getParent()->getChildCount() - 1));
}

=item getLabel()

Recursively goes up the tree and gets a unique text string

=cut

sub getLabel {
    my $self = shift;
    return '1' if $self->isRoot();
    return $self->getParent()->getLabel().'_'.$self->{'_position'};
}

=item setValue($value)

Sets the 'value' of this node.

=cut

sub setValue {
    my $self  = shift;
    $self->{'_value'} = shift;
}

=item getValue()

Gets the 'value' of this node.

=cut

sub getValue {
    my $self = shift;
    return $self->{'_value'};
}

=back

=head2 Private Methods

=over 4

=item _setParent($parent, $position)

Sets the parent of a child

=cut

sub _setParent {
    my $self = shift;
    my ($parent, $position) = @_;

    $self->{'_parent'} = $parent;
    $self->{'_position'} = $position;
}

sub DESTROY {
    my $self = shift;
    $self->destroy();
}


1;

__END__

=back

=head2 Modules Used

L<List|List>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2412 $ 



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
