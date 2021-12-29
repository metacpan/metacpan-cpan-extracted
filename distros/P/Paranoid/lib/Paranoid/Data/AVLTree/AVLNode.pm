# Paranoid::Data::AVLTree::AVLNode -- AVL Tree Node Object Class
#
# $Id: lib/Paranoid/Data/AVLTree/AVLNode.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $
#
# This software is free software.  Similar to Perl, you can redistribute it
# and/or modify it under the terms of either:
#
#   a)     the GNU General Public License
#          <https://www.gnu.org/licenses/gpl-1.0.html> as published by the
#          Free Software Foundation <http://www.fsf.org/>; either version 1
#          <https://www.gnu.org/licenses/gpl-1.0.html>, or any later version
#          <https://www.gnu.org/licenses/license-list.html#GNUGPL>, or
#   b)     the Artistic License 2.0
#          <https://opensource.org/licenses/Artistic-2.0>,
#
# subject to the following additional term:  No trademark rights to
# "Paranoid" have been or are conveyed under any of the above licenses.
# However, "Paranoid" may be used fairly to describe this unmodified
# software, in good faith, but not as a trademark.
#
# (c) 2005 - 2020, Arthur Corliss (corliss@digitalmages.com)
# (tm) 2008 - 2020, Paranoid Inc. (www.paranoid.com)
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Paranoid::Data::AVLTree::AVLNode;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION);
use base qw(Exporter);
use Paranoid;
use Carp;

($VERSION) = ( q$Revision: 2.09 $ =~ /(\d+(?:\.\d+)+)/sm );

use constant AVLKEY     => 0;
use constant AVLVAL     => 1;
use constant AVLRIGHT   => 2;
use constant AVLLEFT    => 3;
use constant AVLRHEIGHT => 4;
use constant AVLLHEIGHT => 5;

use constant AVLNHEADER => 'AVLNODE:v1:';

#####################################################################
#
# Module code follows
#
#####################################################################

sub new {

    # Purpose:  Instantiates an AVLNode object
    # Returns:  Object reference if successful, undef otherwise
    # Usage:    $obj = Paranoid::Data::AVLTree::AVLNode->new(
    #                   $key, $val
    #                   );

    my $class = shift;
    my $key   = shift;
    my $val   = shift;
    my $self  = [];

    bless $self, $class;
    if ( defined $key and length $key ) {
        $$self[AVLKEY]     = $key;
        $$self[AVLVAL]     = $val;
        $$self[AVLRHEIGHT] = 0;
        $$self[AVLLHEIGHT] = 0;
    } else {
        $self = undef;
    }

    return $self;
}

sub ioRecord {

    # Purpose:  Returns a string record representation of the node
    # Returns:  String
    # Usage:    $record = $obj->ioRecord;

    my $self = shift;
    my $rv   = AVLNHEADER;
    my ( $ksize, $vsize );

    {
        use bytes;
        $ksize = length $$self[AVLKEY];
        $vsize = defined $$self[AVLVAL] ? length $$self[AVLVAL] : -1;
    }

    $rv .= "$ksize:$vsize:";
    $rv .= $$self[AVLKEY];
    $rv .= $$self[AVLVAL] if defined $$self[AVLVAL];

    return $rv;
}

sub key {

    # Purpose:  Returns the node key
    # Returns:  String
    # Usage:    $key = $obj->key;

    my $self = shift;
    return $$self[AVLKEY];
}

sub val {

    # Purpose:  Returns the node value
    # Returns:  Scalar/undef
    # Usage:    $val = $node->val;

    my $self = shift;
    return $$self[AVLVAL];
}

sub setVal {

    # Purpose:  Sets the node value
    # Returns:  Boolean
    # Usage:    $rv = $obj->setVal($val);

    my $self = shift;
    my $val  = shift;

    $$self[AVLVAL] = $val;

    return 1;
}

sub right {

    # Purpose:  Returns the right-side node reference
    # Returns:  AVLNode ref/undef
    # Usage:    $ref = $obj->right;

    my $self = shift;
    return $$self[AVLRIGHT];
}

sub setRight {

    # Purpose:  Sets the right-side node reference
    # Returns:  Boolean
    # Usage:    $rv = $obj->setRight($node);

    my $self = shift;
    my $val  = shift;

    $$self[AVLRIGHT] = $val;
    $$self[AVLRHEIGHT] = defined $val ? $val->height : 0;

    return 1;
}

sub left {

    # Purpose:  Returns the left-side node reference
    # Returns:  AVLNode ref/undef
    # Usage:    $ref = $obj->left;

    my $self = shift;
    return $$self[AVLLEFT];
}

sub setLeft {

    # Purpose:  Sets the left-side node reference
    # Returns:  Boolean
    # Usage:    $rv = $obj->setLeft($node);

    my $self = shift;
    my $val  = shift;

    $$self[AVLLEFT] = $val;
    $$self[AVLLHEIGHT] = defined $val ? $val->height : 0;

    return 1;
}

sub incrRHeight {

    # Purpose:  Increments the right-side branch height
    # Returns:  Boolean
    # Usage:    $rv = $obj->incrRHeight;

    my $self = shift;

    $$self[AVLRHEIGHT]++;

    return 1;
}

sub incrLHeight {

    # Purpose:  Increments the left-side branch height
    # Returns:  Boolean
    # Usage:    $rv = $obj->incrLHeight;

    my $self = shift;

    $$self[AVLLHEIGHT]++;

    return 1;
}

sub addRHeight {

    # Purpose:  Adds the passed value to the right-side height
    # Returns:  Boolean
    # Usage:    $rv = $obj->addRHeight($n);

    my $self = shift;
    my $n    = shift;

    $$self[AVLRHEIGHT] += $n;

    return 1;
}

sub addLHeight {

    # Purpose:  Adds the passed value to the left-side height
    # Returns:  Boolean
    # Usage:    $rv = $obj->addLHeight($n);

    my $self = shift;
    my $n    = shift;

    $$self[AVLLHEIGHT] += $n;

    return 1;
}

sub decrRHeight {

    # Purpose:  Decrements the right-side branch height
    # Returns:  Boolean
    # Usage:    $rv = $obj->decrRHeight;

    my $self = shift;

    $$self[AVLRHEIGHT]--;

    return 1;
}

sub decrLHeight {

    # Purpose:  Decrements the left-side branch height
    # Returns:  Boolean
    # Usage:    $rv = $obj->decrLHeight;

    my $self = shift;

    $$self[AVLLHEIGHT]--;

    return 1;
}

sub balance {

    # Purpose:  Returns the current balance of right/left-side branch heights
    # Returns:  Integer
    # Usage:    $balance = $obj->balance;

    my $self = shift;

    return $$self[AVLRHEIGHT] - $$self[AVLLHEIGHT];
}

sub count {

    # Purpose:  Returns the count of nodes from this node and its sub-branches
    # Returns:  Integer
    # Usage:    $count = $obj->count;

    my $self = shift;
    my $rv   = 1;

    $rv += $$self[AVLRIGHT]->count if defined $$self[AVLRIGHT];
    $rv += $$self[AVLLEFT]->count  if defined $$self[AVLLEFT];

    return $rv;
}

sub height {

    # Purpose:  Returns the height of this node and its longest sub-branch
    # Returns:  Integer
    # Usage:    $height = $obj->height;

    my $self = shift;

    return 1 + (
          $$self[AVLRHEIGHT] > $$self[AVLLHEIGHT]
        ? $$self[AVLRHEIGHT]
        : $$self[AVLLHEIGHT] );
}

sub rHeight {

    # Purpose:  Returns the height of the right-side sub-branch
    # Returns:  Integer
    # Usage:    $height = $obj->rHeight;

    my $self = shift;

    return $$self[AVLRHEIGHT];
}

sub lHeight {

    # Purpose:  Returns the height of the left-side sub-branch
    # Returns:  Integer
    # Usage:    $height = $obj->lHeight;

    my $self = shift;

    return $$self[AVLLHEIGHT];
}

sub updtHeights {

    # Purpose:  Brute force method of recalculating all sub-branch heights
    # Returns:  Boolean
    # Usage:    $rv = $obj->updtHeights;

    my $self = shift;

    $$self[AVLRHEIGHT] =
        defined $$self[AVLRIGHT]
        ? $$self[AVLRIGHT]->height
        : 0;
    $$self[AVLLHEIGHT] =
        defined $$self[AVLLEFT] ? $$self[AVLLEFT]->height : 0;

    return 1;
}

sub children {

    # Purpose:  Returns all nodes linked to from this node
    # Returns:  Array of AVLNode refs
    # Usage:    @crefs = $obj->children;

    my $self = shift;
    my @rv;

    push @rv, $$self[AVLRIGHT] if defined $$self[AVLRIGHT];
    push @rv, $$self[AVLLEFT]  if defined $$self[AVLLEFT];

    return @rv;
}

1;

__END__

=head1 NAME

Paranoid::Data::AVLTree::AVLNode - AVL Tree Node Object Class

=head1 VERSION

$Id: lib/Paranoid/Data/AVLTree/AVLNode.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $

=head1 SYNOPSIS

    $node   = Paranoid::Data::AVLTree::AVLNode->new($key, $val);
    $record = $node->ioRecord;
    $key    = $node->key;
    $val    = $node->val;
    $rv     = $node->setVal($val);
    $ref    = $node->right;
    $rv     = $node->setRight($node);
    $ref    = $node->left;
    $rv     = $node->setLeft($node);
    $rv     = $node->incrRHeight;
    $rv     = $node->incrLHeight;
    $rv     = $node->addRHeight($n);
    $rv     = $node->addLHeight($n);
    $rv     = $node->decrRHeight;
    $rv     = $node->decrLHeight;
    $balance = $node->balance;
    $count  = $node->count;
    $height = $node->height;
    $height = $node->rHeight;
    $height = $node->lHeight;
    $rv     = $node->updtHeights;
    @crefs  = $node->children;

=head1 DESCRIPTION

This class provides the core data objects that comprise an AVL-balanced tree.

=head1 SUBROUTINES/METHODS

=head2 new

    $node   = Paranoid::Data::AVLTree::AVLNode->new($key, $val);

This method creates a new AVLNode object.  Like hashes, the key must be
defined, but it cannot be a zero-length string.  In those cases, this method
will return undef.

=head2 ioRecord

    $record = $node->ioRecord;

This method creates a string representation of the node for use in spooling to
disk.

=head2 key

    $key    = $node->key;

This method returns the key for the node.

=head2 val

    $val    = $node->val;

This method returns the associated value for the node.  It can be undef.

=head2 setVal

    $rv     = $node->setVal($val);

This method sets the assocated value for the node.

=head2 right

    $ref    = $node->right;

This method retrieves a reference to the next right-side node in the branch,
if any.

=head2 setRight

    $rv     = $node->setRight($node);

This method sets/removes the reference to the next right-side node in the branch.

=head2 left

    $ref    = $node->left;

This method retrieves a reference to the next left-side node in the branch,
if any.

=head2 setLeft

    $rv     = $node->setLeft($node);

This method sets/removes the reference to the next left-side node in the branch.

=head2 incrRHeight

    $rv     = $node->incrRHeight;

This method increments the height counter for the ride-side sub-branch.

=head2 incrLHeight

    $rv     = $node->incrLHeight;

This method increments the height counter for the left-side sub-branch.

=head2 addRHeight

    $rv     = $node->addRHeight($n);

This method adds the passed value to the height counter for the right-side
sub-branch.

=head2 addLHeight

    $rv     = $node->addLHeight($n);

This method adds the passed value to the height counter for the left-side
sub-branch.

=head2 decrRHeight

    $rv     = $node->decrRHeight;

This method decrements the height counter for the right-side sub-branch.

=head2 decrLHeight

    $rv     = $node->decrLHeight;

This method decrements the height counter for the left-side sub-branch.

=head2 balance

    $balance = $node->balance;

This returns the node balance, which is a relative indidcator of the disparity
in heights of the right & left sub-branches.  A negative number denotes a
longer left-side branch, zero means equal sub-branch heights, and a positive
integer denotes a longer right-side branch.

=head2 count

    $count  = $node->count;

This method returns the count of nodes, including all nodes in linked
sub-branches.

=head2 height

    $height = $node->height;

This method returns the longest height of the node and any attached
sub-branches.

=head2 rHeight

    $height = $node->rHeight;

This method returns the height of the right-side sub-branch, or zero if there
is no linked branch.

=head2 lHeight

    $height = $node->lHeight;

This method returns the height of the left-side sub-branch, or zero if there
is no linked branch.

=head2 updtHeights

    $rv     = $node->updtHeights;

This method performs a brute force recalculation of all attached sub-branches.

=head2 children

    @crefs  = $node->children;

This returns references to the next nodes in any attadhed sub-branches.

=head1 DEPENDENCIES

=over

=item o

L<Carp>

=item o

L<Paranoid>

=back

=head1 BUGS AND LIMITATIONS 

=head1 AUTHOR 

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is free software.  Similar to Perl, you can redistribute it
and/or modify it under the terms of either:

  a)     the GNU General Public License
         <https://www.gnu.org/licenses/gpl-1.0.html> as published by the 
         Free Software Foundation <http://www.fsf.org/>; either version 1
         <https://www.gnu.org/licenses/gpl-1.0.html>, or any later version
         <https://www.gnu.org/licenses/license-list.html#GNUGPL>, or
  b)     the Artistic License 2.0
         <https://opensource.org/licenses/Artistic-2.0>,

subject to the following additional term:  No trademark rights to
"Paranoid" have been or are conveyed under any of the above licenses.
However, "Paranoid" may be used fairly to describe this unmodified
software, in good faith, but not as a trademark.

(c) 2005 - 2020, Arthur Corliss (corliss@digitalmages.com)
(tm) 2008 - 2020, Paranoid Inc. (www.paranoid.com)

