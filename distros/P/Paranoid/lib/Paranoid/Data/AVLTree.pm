# Paranoid::Data::AVLTree -- AVL-Balanced Tree Class
#
# $Id: lib/Paranoid/Data/AVLTree.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $
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

package Paranoid::Data::AVLTree;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION);
use base qw(Exporter);
use Paranoid;
use Paranoid::Debug qw(:all);
use Paranoid::Data::AVLTree::AVLNode;
use Carp;

($VERSION) = ( q$Revision: 2.09 $ =~ /(\d+(?:\.\d+)+)/sm );

use constant AVLROOT => 0;
use constant AVLKEYS => 1;

#####################################################################
#
# Module code follows
#
#####################################################################

sub new {

    # Purpose:  instantiates an AVLTree object
    # Returns:  Object reference if successful, undef otherwise
    # Usage:    $obj = Paranoid::Data::AVLTree->new();

    my ( $class, %args ) = splice @_;
    my $self = [undef];

    pdebug( 'entering w/%s', PDLEVEL1, %args );
    pIn();

    bless $self, $class;

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $self );

    return $self;
}

sub count {

    # Purpose:  Returns the number of nodes in the tree
    # Returns:  Integer
    # Usage:    $count = $obj->count;

    my $self = shift;

    return defined $$self[AVLROOT] ? $$self[AVLROOT]->count : 0;
}

sub height {

    # Purpose:  Returns the height of the tree based on the longest branch
    # Returns:  Integer
    # Usage:    $height = $obj->height;

    my $self = shift;

    return defined $$self[AVLROOT] ? $$self[AVLROOT]->height : 0;
}

sub _printKeys {

    # Purpose:  Prints the key structure of a tree starting with the node
    #           passed, and includes all children
    # Returns:  String
    # Usage:    $output = _printKeys($root);

    my $i    = shift;
    my $node = shift;
    my $side = shift;
    my $h    = $node->height;
    my $b    = $node->balance;
    my $line = '';

    $line = '  ' x $i if $i;
    $line .= defined $side ? "($side/$h/$b) " : "($h/$b) ";
    $line .= $node->key;
    $line .= "\n";

    $i++;
    $line .= _printKeys( $i, $node->left,  'l' ) if defined $node->left;
    $line .= _printKeys( $i, $node->right, 'r' ) if defined $node->right;

    return $line;
}

sub dumpKeys {

    # Purpose:  A wrapper method that calls _printKeys() with the root node
    #           stored in the object
    # Returns:  String
    # Usage:    $obj->dumpKeys;

    my $self = shift;
    my $line = '<empty>';

    $line = _printKeys( 1, $$self[AVLROOT] ) if defined $$self[AVLROOT];
    warn "Key Dump:\n$line";

    return 1;
}

sub _keys {

    # Purpose:  Returns an array containing all the keys in tree starting
    #           with the passed node
    # Returns:  List of Strings
    # Usage:    @keys = _keys($rootNode);

    my $node  = shift;
    my @stack = $node->key;

    push @stack, _keys( $node->left )  if defined $node->left;
    push @stack, _keys( $node->right ) if defined $node->right;

    return @stack;
}

sub nodeKeys {

    # Purpose:  A wrapper method that calles _keys with the root node
    #           stored in the object
    # Returns:  List of Strings
    # Usage:    @keys = $obj->nodeKeys;

    my $self = shift;
    my @k;

    @k = _keys( $$self[AVLROOT] ) if defined $$self[AVLROOT];

    return @k;
}

sub _findNode {

    # Purpose:  Checks for the existence of a matching node in the tree
    #           and updates the passed references for the path to where
    #           the node would be positioned, as well as the node, if
    #           there is one.
    # Returns:  Boolean
    # Usage:    $rv = $obj->_findNode($key, $node, @path);

    my $self = shift;
    my $key  = shift;
    my $nref = shift;
    my $pref = shift;
    my $root = $$self[AVLROOT];
    my $rv   = 0;
    my ( @path, $node );

    pdebug( 'entering w/(%s)(%s)(%s)', PDLEVEL4, $key, $nref, $pref );
    pIn();

    $$nref = undef;
    @$pref = ();
    if ( defined $root ) {
        $node = $root;
        while ( defined $node ) {
            if ( $node->key eq $key ) {
                $rv    = 1;
                $$nref = $node;
                pdebug( 'node found: %s', PDLEVEL4, $$nref );
                last;
            } else {
                push @path, $node;
                $node = $key gt $node->key ? $node->right : $node->left;
            }
        }
        @$pref = @path;
        pdebug( 'path to node position: %s', PDLEVEL4, @$pref );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL4, $rv );

    return $rv;
}

sub nodeExists {

    # Purpose:  Checks for the existence of a matching node
    # Returns:  Boolean
    # Usage:    $rv = $obj->nodeExists($key):

    my $self = shift;
    my $key  = shift;
    my $rv   = 0;
    my ( @path, $node );

    pdebug( 'entering w/%s', PDLEVEL3, $key );
    pIn();

    if ( defined $key ) {
        $self->_findNode( $key, \$node, \@path );
        $rv = defined $node;
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

    return $self->_findNode( $key, \$node, \@path );
}

sub fetchVal {

    # Purpose:  Returns the associated value for the key, if it's present
    # Returns:  Scalar
    # Usage:    $val = obj->fetchVal($key);

    my $self = shift;
    my $key  = shift;
    my ( @path, $node, $val );

    pdebug( 'entering w/%s', PDLEVEL3, $key );
    pIn();

    if ( defined $key ) {
        $self->_findNode( $key, \$node, \@path );
        pdebug( 'node is %s', PDLEVEL4, $node );
        $val = $node->val if defined $node;
    }

    pOut();
    pdebug( 'leaving w/rv: %s bytes',
        PDLEVEL3, defined $val
        ? length $val
        : 0 );

    return $val;
}

sub _addNode {

    # Purpose:  Adds or updates a node for the key/value passed
    # Returns:  Boolean
    # Usage:    $rv = $obj->_addNode($key, $value);

    my $self = shift;
    my $key  = shift;
    my $val  = shift;
    my $root = $$self[AVLROOT];
    my $rv   = 1;
    my ( @path, $nn, $node, $parent );

    pdebug( 'entering w/ %s => %s', PDLEVEL3, $key, $val );
    pIn();

    # Validation check
    $nn = Paranoid::Data::AVLTree::AVLNode->new( $key, $val );

    if ( defined $nn ) {
        if ( defined $root ) {
            if ( $self->_findNode( $key, \$node, \@path ) ) {
                $node->setVal($val);
                pdebug( 'updating existing node', PDLEVEL4 );
            } else {

                # Attach the new node
                foreach (@path) {
                    if ( $key gt $_->key ) {
                        $_->incrRHeight;
                    } else {
                        $_->incrLHeight;
                    }
                }
                if ( $key gt $path[-1]->key ) {
                    $path[-1]->setRight($nn);
                } else {
                    $path[-1]->setLeft($nn);
                }
                pdebug( 'added node at the end of the branch', PDLEVEL4 );

            }

        } else {
            $$self[AVLROOT] = $nn;
            pdebug( 'adding node as the tree root: %s',
                PDLEVEL4, $$self[AVLROOT] );
        }

    } else {
        $rv = 0;
        pdebug( 'invalid key submitted: %s', PDLEVEL1, $key );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

    return $rv;
}

sub _updtRootRef {

    # Purpose:  Updates the parent link matching the original ref
    #           with the new ref.  Link can be on either side of
    #           the branch, or could be root of the tree, entirely.
    # Returns:  Boolean
    # Usage:    $rv = $obj->_updtRootRef($root, $oldref, $newref);

    my $self = shift;
    my $root = shift;
    my $oref = shift;
    my $nref = shift;
    my $rv   = 1;

    if ( defined $root ) {

        # Update the parent link (could be on either side) to the child
        if ( defined $root->left and $root->left == $oref ) {
            pdebug( 'updating link on the root\'s right side', PDLEVEL4 );
            $root->setLeft($nref);
        } elsif ( defined $root->right and $root->right == $oref ) {
            pdebug( 'updating link on the root\'s left side', PDLEVEL4 );
            $root->setRight($nref);
        } else {
            pdebug( 'ERROR: old ref not linked to root!', PDLEVEL1 );
            $rv = 0;
        }

    } else {

        # No parent means we're rotating the root
        pdebug( 'updating root node link', PDLEVEL4 );
        $$self[AVLROOT] = $nref;
    }

    return $rv;
}

sub _rrr {

    # Purpose:  Performs a single rotate right
    # Returns:  Boolean
    # Usage:    $rv = $self->_rrr($root, $node);

    my $self = shift;
    my $root = shift;
    my $x    = shift;
    my $z    = $x->left;
    my $rv;

    pdebug( 'entering w/(%s)(%s)', PDLEVEL4, $root, $x );
    pIn();

    # Update root node as a prerequisite to continuing
    $rv = defined $x and defined $z and $self->_updtRootRef( $root, $x, $z );

    # Update x & z refs
    if ($rv) {
        $x->setLeft( $z->right );
        $z->setRight($x);

        # Update heights
        $x->updtHeights;
        $z->updtHeights;
        if ( defined $root ) {
            $root->updtHeights;
        } else {
            $$self[AVLROOT]->updtHeights;
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL4, $rv );

    return $rv;
}

sub _rll {

    # Purpose:  Performs a single rotate left
    # Returns:  Boolean
    # Usage:    $rv = $self->_rll($root, $node);

    my $self = shift;
    my $root = shift;
    my $x    = shift;
    my $z    = $x->right;
    my $rv;

    pdebug( 'entering w/(%s)(%s)', PDLEVEL4, $root, $x );
    pIn();

    # Update root node as a prerequisite to continuing
    $rv = defined $x and defined $z and $self->_updtRootRef( $root, $x, $z );

    # Update x & z refs
    if ($rv) {
        $x->setRight( $z->left );
        $z->setLeft($x);

        # Update heights
        $x->updtHeights;
        $z->updtHeights;
        if ( defined $root ) {
            $root->updtHeights;
        } else {
            $$self[AVLROOT]->updtHeights;
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL4, $rv );

    return $rv;
}

sub _rrl {

    # Purpose:  Performs a double rotation of right-left
    # Returns:  Boolean
    # Usage:    $rv = $self->_rrl($root, $node);

    my $self = shift;
    my $root = shift;
    my $x    = shift;
    my $z    = $x->right;
    my $y    = $z->left;
    my $rv   = 0;

    pdebug( 'entering w/(%s)(%s)', PDLEVEL4, $root, $x );
    pIn();

    $rv = $self->_rrr( $x, $z );
    if ($rv) {
        $z = $x->right;
        if ( $z == $y ) {
            $rv = $self->_rll( $root, $x );
        } else {
            pdebug( 'double rotation incorrect results on first rotation',
                PDLEVEL1 );
        }
    } else {
        pdebug( 'double rotation failed on first rotation', PDLEVEL1 );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL4, $rv );

    return $rv;
}

sub _rlr {

    # Purpose:  Performs a double rotation of left-right
    # Returns:  Boolean
    # Usage:    $rv = $self->_rlr($root, $node);

    my $self = shift;
    my $root = shift;
    my $x    = shift;
    my $z    = $x->left;
    my $y    = $z->right;
    my $rv   = 0;

    pdebug( 'entering w/(%s)(%s)', PDLEVEL4, $root, $x );
    pIn();

    $rv = $self->_rll( $x, $z );
    if ($rv) {
        $z = $x->left;
        if ( $z == $y ) {
            $rv = $self->_rrr( $root, $x );
        } else {
            pdebug( 'double rotation incorrect results on first rotation',
                PDLEVEL1 );
        }
    } else {
        pdebug( 'double rotation failed on first rotation', PDLEVEL1 );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL4, $rv );

    return $rv;
}

sub _rotate {

    # Purpose:  Performs the appropriate rotation for the specified node under
    #           the specified root.  This includes not only what direction to
    #           rotate, but whether to perform a single or double rotation.
    # Returns:  Boolean
    # Usage:    $rv = $obj->_rotate($root, $node);

    my $self = shift;
    my $root = shift;
    my $x    = shift;
    my $rv   = 1;

    pdebug( 'entering w/(%s)(%s)', PDLEVEL4, $root, $x );
    pIn();

    if ( $x->balance > 1 ) {

        # Rotate left
        if ( $x->right->balance < 0 ) {

            # Perform a double rotation
            $rv = $self->_rrl( $root, $x );

        } else {

            # Perform a single rotation
            $rv = $self->_rll( $root, $x );
        }

    } elsif ( $x->balance < -1 ) {

        # Rotate right
        if ( $x->left->balance > 0 ) {

            # Perform a double rotation
            $rv = $self->_rlr( $root, $x );

        } else {

            # Perform a single rotation
            $rv = $self->_rrr( $root, $x );
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL4, $rv );

    return $rv;
}

sub _rebalance {

    # Purpose:  Rebalances the tree for the branch extending to the specified
    #           node by performing rotations on all nodes that are unbalanced
    # Returns:  Boolean
    # Usage:    $rv = $obj->($node);

    my $self = shift;
    my $node = shift;
    my $key  = $node->key;
    my ( @path, $parent, $n );

    pdebug( 'entering w/%s', PDLEVEL4, $node );
    pIn();

    if ( $self->_findNode( $key, \$node, \@path ) ) {

        # Start at the bottom of the chain
        push @path, $node;
        $key = $node->key;

        # Find number of nodes that are unbalanced
        $n = scalar grep { abs( $_->balance ) > 1 } @path;
        while ($n) {
            pdebug( 'found %s node(s) in the branch that are unbalanced',
                PDLEVEL4, $n );
            $node = $parent = undef;

            foreach (@path) {
                $node = $_;
                if ( abs( $node->balance ) > 1 ) {
                    pdebug( 'key: %s balance: %s',
                        PDLEVEL4, $node->key, $node->balance );

                    # Determine type of rotation and execute it
                    $self->_rotate( $parent, $node );
                    $self->_findNode( $key, \$node, \@path );
                    push @path, $node;
                    $n = scalar grep { abs( $_->balance ) > 1 } @path;
                    last;
                } else {
                    $parent = $node;
                }
            }
        }
    }

    pOut();
    pdebug( 'leaving w/rv: 1', PDLEVEL4 );

    return 1;
}

sub addPair {

    # Purpose:  Adds or updates a node for the key/value passed
    # Returns:  Boolean
    # Usage:    $rv = $obj->addPair($key, $value);

    my $self = shift;
    my $key  = shift;
    my $val  = shift;
    my $rv   = 1;
    my ( @path, $node );

    pdebug( 'entering w/ %s => %s', PDLEVEL3, $key, $val );
    pIn();

    $rv = $self->_addNode( $key, $val );
    if ($rv) {
        $self->_findNode( $key, \$node, \@path );
        $rv = $self->_rebalance($node);
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

    return $rv;
}

sub _splice {

    # Purpose:  Splices off the requested node and reattaches any
    #           sub-branches, and returns a new target key useful
    #           for tracing for rebalancing purposes.
    # Returns:  String
    # Usage:    $key = $obj->_splice($root, $node);

    my $self = shift;
    my $root = shift;
    my $node = shift;
    my ( $rv, $ln, $rn, $cn, @path, $height );

    pdebug( 'entering w/(%s)(%s)', PDLEVEL4, $root, $node );
    pIn();

    $ln = $node->left;
    $rn = $node->right;

    if ( defined $ln and defined $rn ) {

        # Attach the longer branch underneath the shorter branch
        if ( $ln->height < $rn->height ) {

            # Right branch is longer
            #
            # Find a place to attach on the left branch
            push @path, $ln;
            $cn = $ln;
            while ( defined $cn->right ) {
                $cn = $cn->right;
                push @path, $cn;
            }
            $cn->setRight($rn);

            # Update the height back up to the root of the left branch
            $height = $cn->height;
            foreach ( reverse @path ) {
                if ( $_->rHeight < $height ) {
                    $_->addRHeight( $height - $_->rHeight );
                }
                $height++;
            }

            # Now, attach the left branch to the root
            $self->_updtRootRef( $root, $node, $ln );

            # Hand back the node key that we're going to seek to in the
            # calling function
            $rv = $rn->key;

        } else {

            # Left branch is longer
            #
            # Find a place to attach on the right branch
            push @path, $rn;
            $cn = $rn;
            while ( defined $cn->left ) {
                $cn = $cn->left;
                push @path, $cn;
            }
            $cn->setLeft($ln);

            # Update the height back up to the root of the left branch
            $height = $cn->height;
            foreach ( reverse @path ) {
                if ( $_->lHeight < $height ) {
                    $_->addLHeight( $height - $_->lHeight );
                }
                $height++;
            }

            # Now, attach the left branch to the root
            $self->_updtRootRef( $root, $node, $rn );

            # Hand back the node key that we're going to seek to in the
            # calling function
            $rv = $ln->key;

        }

    } else {
        pdebug( 'this function shouldn\'t be called without two branches',
            PDLEVEL4 );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL4, $rv );

    return $rv;
}

sub delNode {

    # Purpose:  Removes the specifed node
    # Returns:  Boolean
    # Usage:    $rv = $obj->delNode($key);

    my $self = shift;
    my $key  = shift;
    my $rv   = 0;
    my ( $root, $node, @path, $height );

    pdebug( 'entering w/%s', PDLEVEL4, $key );
    pIn();

    if ( $self->_findNode( $key, \$node, \@path ) ) {
        $root = $path[-1];

        # Test for simplest deletion conditions
        if ( scalar $node->children <= 1 ) {

            # Node for deletion only has one or zero children
            $rv =
                defined $node->left
                ? $self->_updtRootRef( $root, $node, $node->left )
                : defined $node->right
                ? $self->_updtRootRef( $root, $node, $node->right )
                : $self->_updtRootRef( $root, $node, undef );

            # Adjust heights
            foreach ( reverse @path ) {
                if ( $key lt $_->key ) {
                    $_->decrLHeight
                        if defined $_->left
                            and $_->left->height < $_->lHeight;
                } else {
                    $_->decrRHeight
                        if defined $_->right
                            and $_->right->height < $_->rHeight;
                }
            }

        } else {

            # Splice the node out
            $key = $self->_splice( $root, $node );

            if ( $self->_findNode( $key, \$node, \@path ) ) {
                $rv   = 1;
                $root = $node;

            } else {
                pdebug( 'something went horribly wrong', PDLEVEL1 );
            }

        }

        # Rebalance
        $root = $$self[AVLROOT] unless defined $root;
        $rv = $self->_rebalance($root) if defined $root and $rv;
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL4, $rv );

    return $rv;
}

sub purgeNodes {

    # Purpose:  Deletes the root reference, essentially purging the entire
    #           tree
    # Returns:  Boolean
    # Usage:    $rv = $obj->purgeNodes;

    my $self = shift;

    pdebug( 'entering', PDLEVEL4 );

    $$self[AVLROOT] = undef;

    pdebug( 'leaving w/rv: 1', PDLEVEL4 );

    return 1;
}

sub TIEHASH {
    return new Paranoid::Data::AVLTree;
}

sub FETCH {
    my $self = shift;
    my $key  = shift;
    my $rv;

    return $self->fetchVal($key);
}

sub STORE {
    my $self = shift;
    my $key  = shift;
    my $val  = shift;

    return $self->addPair( $key, $val );
}

sub EXISTS {
    my $self = shift;
    my $key  = shift;

    return $self->nodeExists($key);
}

sub DELETE {
    my $self = shift;
    my $key  = shift;

    return $self->delNode($key);
}

sub CLEAR {
    my $self = shift;

    return $self->purgeNodes;
}

sub FIRSTKEY {
    my $self = shift;
    my @k    = $self->nodeKeys();
    my ( $key, $node, @path, %rv );

    if (@k) {
        $key = shift @k;
        $self->_findNode( $key, \$node, \@path );
        %rv = ( $node->key() => $node->val() );
        $$self[AVLKEYS] = [@k];
    }

    return each %rv;
}

sub NEXTKEY {
    my $self = shift;
    my ( $key, $node, @path, %rv );

    if ( defined $$self[AVLKEYS] and scalar @{ $$self[AVLKEYS] } ) {
        $key = shift @{ $$self[AVLKEYS] };
        $self->_findNode( $key, \$node, \@path );
        %rv = ( $node->key() => $node->val() );
    }

    return each %rv;
}

sub SCALAR {
    my $self = shift;

    return $self->count;
}

sub UNTIE {
    return 1;
}

1;

__END__

=head1 NAME

Paranoid::Data::AVLTree - AVL-Balanced Tree Class

=head1 VERSION

$Id: lib/Paranoid/Data/AVLTree.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $

=head1 SYNOPSIS

    # Preferred use
    tie %tree, 'Paranoid::Data::AVLTree';

    # Or, purely as an object
    $tree   = new Paranoid::Data::AVLTree;
    $count  = $tree->count;
    $height = $tree->height;
    @keys   = $tree->nodeKeys;
    $rv     = $tree->nodeExists($key):
    $val    = $tree->fetchVal($key);
    $rv     = $tree->addPair($key, $value);
    $rv     = $tree->delNode($key);
    $rv     = $tree->purgeNodes;
    $tree->dumpKeys;

=head1 DESCRIPTION

This class provides an AVL-balance tree implementation, that can work both as
an independent object or as a tied hash.  Future versions will include methods
to allow for simple spooling to and from disk.

=head1 SUBROUTINES/METHODS

=head2 new

    $tree   = new Paranoid::Data::AVLTree;

This creates a new tree object.

=head2 count

    $count  = $tree->count;

This method returns a count of all the nodes in the tree.

=head2 height

    $height = $tree->height;

This method returns the height of the tree.

=head2 nodeKeys

    @keys   = $tree->nodeKeys;

This method returns a list of all keys for all nodes in the tree.

=head2 nodeExists

    $rv     = $tree->nodeExists($key):

This method returns a boolean value indicating whether a node exists wtih a
matching key.

=head2 fetchVal

    $val    = $tree->fetchVal($key);

This method returns the associated value for the passed key.  Like hashes, it
will return undef for nonexistant keys.

=head2 addPair

    $rv     = $tree->addPair($key, $value);

This method adds the requested key/value pair, or updates an existing node
with the same key.  It will return a boolean false if the key is an invalid
value.

=head2 delNode

    $rv     = $tree->delNode($key);

This method deletes the specified node if it exists.  It will return boolean
false should no matching node exist.

=head2 purgeNodes

    $rv     = $tree->purgeNodes;

This purges all nodes from the tree.

=head2 dumpKeys

    $tree->dumpKeys;

This method exists purely for diagnostic purposes.  It dumps a formatted tree
structure to B<STDERR> showing all keys in the tree, along with the relative
branch height and balance of every node, along with what side of the tree each
node is attached.

=head2 TIE METHODS

These methods aren't intended for direct use, but to support tied hashes.

=head3 CLEAR

=head3 DELETE

=head3 EXISTS

=head3 FETCH

=head3 FIRSTKEY

=head3 NEXTKEY

=head3 SCALAR

=head3 STORE

=head3 TIEHASH

=head3 UNTIE

=head1 DEPENDENCIES

=over

=item o

L<Carp>

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=item o

L<Paranoid::Data::AVLTree::AVLNode>

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

