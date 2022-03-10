# Paranoid::Data::AVLTree -- AVL-Balanced Tree Class
#
# $Id: lib/Paranoid/Data/AVLTree.pm, 2.10 2022/03/08 00:01:04 acorliss Exp $
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
use Paranoid::Data;
use Paranoid::Debug qw(:all);
use Paranoid::Data::AVLTree::AVLNode;
use Paranoid::IO;
use Fcntl qw(:DEFAULT :flock :mode :seek);
use Carp;

($VERSION) = ( q$Revision: 2.10 $ =~ /(\d+(?:\.\d+)+)/sm );

use constant AVLROOT  => 0;
use constant AVLKEYS  => 1;
use constant AVLPROF  => 2;
use constant AVLSTATS => 3;

use constant STAT_INSERTS   => 0;
use constant STAT_DELETES   => 1;
use constant STAT_REBALANCE => 2;
use constant STAT_ROTATIONS => 3;

use constant AVLZEROLS => 1;
use constant AVLUNDEF  => 2;

# Record signature format:
#   PDAVL KFLAG VFLAG KLEN VLEN
#   Z6    Cx    Cx    NNx  NNx
#     28 bytes
use constant SIGNATURE => 'Z6CxCxNNxNNx';
use constant SIG_LEN   => 28;
use constant SIG_TYPE  => 'PDAVL';

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

    subPreamble( PDLEVEL1, '%', %args );

    bless $self, $class;

    subPostamble( PDLEVEL1, '$', $self );

    return $self;
}

sub profile {

    # Purpose:  Enables/disables performance profiling
    # Returns:  Boolean
    # Usage:    $rv = $obj->profile(1);

    my $self   = shift;
    my $enable = shift;

    $$self[AVLPROF] = $enable;
    if ($enable) {

        # Reset counters
        $$self[AVLSTATS]                 = [];
        $$self[AVLSTATS][STAT_INSERTS]   = 0;
        $$self[AVLSTATS][STAT_DELETES]   = 0;
        $$self[AVLSTATS][STAT_REBALANCE] = 0;
        $$self[AVLSTATS][STAT_ROTATIONS] = 0;
    }

    return 1;
}

sub stats {

    # Purpose:  Returns the values of the current perf counters
    # Returns:  Hash
    # Usage:    %stats = $obj->stats;

    my $self = shift;
    my %stats;

    if ( defined $$self[AVLSTATS] ) {
        %stats = (
            insertions => $$self[AVLSTATS][STAT_INSERTS],
            deletions  => $$self[AVLSTATS][STAT_DELETES],
            rebalances => $$self[AVLSTATS][STAT_REBALANCE],
            rotations  => $$self[AVLSTATS][STAT_ROTATIONS],
            );
    } else {
        %stats = (
            insertions => 0,
            deletions  => 0,
            rebalances => 0,
            rotations  => 0,
            );
    }

    return %stats;
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

    pderror($line);

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

    subPreamble( PDLEVEL4, '$$$', $key, $nref, $pref );

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

    subPostamble( PDLEVEL4, '$', $rv );

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

    subPreamble( PDLEVEL3, '$', $key );

    if ( defined $key ) {
        $self->_findNode( $key, \$node, \@path );
        pdebug( 'node is %s', PDLEVEL4, $node );
        $val = $node->val if defined $node;
    }

    subPostamble( PDLEVEL3, 'b', $val );

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

    subPreamble( PDLEVEL3, '$b', $key, $val );

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
                $$self[AVLSTATS][STAT_INSERTS]++ if $$self[AVLPROF];

            }

        } else {
            $$self[AVLROOT] = $nn;
            pdebug( 'adding node as the tree root: %s',
                PDLEVEL4, $$self[AVLROOT] );
            $$self[AVLSTATS][STAT_INSERTS]++ if $$self[AVLPROF];
        }

    } else {
        $rv = 0;
        pdebug( 'invalid key submitted: %s', PDLEVEL1, $key );
    }

    subPostamble( PDLEVEL3, '$', $rv );

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

    subPreamble( PDLEVEL4, '$$', $root, $x );

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
        $$self[AVLSTATS][STAT_ROTATIONS]++ if $$self[AVLPROF];
    }

    subPostamble( PDLEVEL4, '$', $rv );

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

    subPreamble( PDLEVEL4, '$$', $root, $x );

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
        $$self[AVLSTATS][STAT_ROTATIONS]++ if $$self[AVLPROF];
    }

    subPostamble( PDLEVEL4, '$', $rv );

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

    subPreamble( PDLEVEL4, '$$', $root, $x );

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

    subPostamble( PDLEVEL4, '$', $rv );

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

    subPreamble( PDLEVEL4, '$$', $root, $x );

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

    subPostamble( PDLEVEL4, '$', $rv );

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

    subPreamble( PDLEVEL4, '$$', $root, $x );

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

    subPostamble( PDLEVEL4, '$', $rv );

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

    subPreamble( PDLEVEL4, '$', $node );

    if ( $self->_findNode( $key, \$node, \@path ) ) {

        # Start at the bottom of the chain
        push @path, $node;
        $key = $node->key;

        # Find number of nodes that are unbalanced
        $n = scalar grep { abs( $_->balance ) > 1 } @path;
        $$self[AVLSTATS][STAT_REBALANCE]++ if $$self[AVLPROF] and $n;
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

    subPostamble( PDLEVEL4, '$', 1 );

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

    subPreamble( PDLEVEL3, '$b', $key, $val );

    $rv = $self->_addNode( $key, $val );
    if ($rv) {
        $self->_findNode( $key, \$node, \@path );
        $rv = $self->_rebalance($node);
    }

    subPostamble( PDLEVEL3, '$', $rv );

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

    subPreamble( PDLEVEL4, '$$', $root, $node );

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

    subPostamble( PDLEVEL4, '$', $rv );

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

    subPreamble( PDLEVEL3, '$', $key );

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
        $$self[AVLSTATS][STAT_DELETES]++ if $$self[AVLSTATS] and $rv;

        # Rebalance
        $root = $$self[AVLROOT] unless defined $root;
        $rv = $self->_rebalance($root) if defined $root and $rv;
    }

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

sub purgeNodes {

    # Purpose:  Deletes the root reference, essentially purging the entire
    #           tree
    # Returns:  Boolean
    # Usage:    $rv = $obj->purgeNodes;

    my $self = shift;

    subPreamble(PDLEVEL3);

    $$self[AVLROOT] = undef;

    subPostamble( PDLEVEL3, '$', 1 );

    return 1;
}

sub _writeRecord {

    # Purpose:  Writes the passed node to file
    # Returns:  Boolean
    # Usage:    $rv = _writeRecord($filename, $node);

    my $file = shift;
    my $node = shift;
    my ( $rv, $rec, $k, $v, $kf, $vf );

    # Get key/val
    $k = $node->key;
    $v = $node->val;

    # Set flag values
    $kf =
         !defined $k ? AVLUNDEF
        : length $k  ? 0
        :              AVLZEROLS;
    $vf =
         !defined $v ? AVLUNDEF
        : length $v  ? 0
        :              AVLZEROLS;

    {
        use bytes;
        $rec = pack SIGNATURE, SIG_TYPE, $kf, $vf,
            quad2Longs( $kf ? 0 : length $k ),
            quad2Longs( $vf ? 0 : length $v );
        $rec .= $k unless $kf;
        $rec .= $v unless $vf;

        $rv = pwrite( $file, $rec ) == length $rec ? 1 : 0;
    }

    pdebug( 'failed to write record', PDLEVEL1 ) unless $rv;

    return $rv;
}

sub save2File {

    # Purpose:  Saves binary tree to a file
    # Returns:  Boolean
    # Usage:    $rv = $obj->save($file);

    my $self = shift;
    my $file = shift;
    my $rv;
    my ( @lc, @rc, @ln, @rn, $node );

    subPreamble( PDLEVEL1, '$', $file );

    if ( defined $file and length $file ) {
        if ( popen( $file, O_RDWR | O_CREAT ) ) {
            pseek( $file, 0, SEEK_SET );
            ptruncate($file);

            # Start descending the tree one level at a time
            if ( defined $$self[AVLROOT] ) {
                $rv = _writeRecord( $file, $$self[AVLROOT] );
                @lc = ( grep {defined} $$self[AVLROOT]->left );
                @rc = ( grep {defined} $$self[AVLROOT]->right );

                # Note:  the whole point of this is to attempt to retrieve
                # nodes from both sides of the tree in a way that, when read,
                # will require minimal rebalances.

                # Start descending and writing
                while ( $rv and ( @lc or @rc ) ) {

                    # Extract a list of all left and right nodes
                    @ln = grep {defined} map { $_->left } @lc;
                    push @ln, grep {defined} map { $_->right } @lc;
                    @rn = grep {defined} map { $_->left } @rc;
                    push @rn, grep {defined} map { $_->right } @rc;

                    # Record all of the current level of children
                    while ( $rv and ( @lc or @rc ) ) {

                        # Shift off of the left side
                        $node = shift @lc;
                        $rv = _writeRecord( $file, $node ) if defined $node;

                        # Shift off of the right side
                        $node = shift @rc;
                        $rv = _writeRecord( $file, $node )
                            if $rv and defined $node;

                        # Pop off of the left side
                        $node = pop @lc;
                        $rv = _writeRecord( $file, $node )
                            if $rv and defined $node;

                        # Pop off of the right side
                        $node = pop @rc;
                        $rv = _writeRecord( $file, $node )
                            if $rv and defined $node;

                    }

                    # Start with the next level
                    @lc = @ln;
                    @rc = @rn;
                }

            } else {
                pdebug( 'nothing in the tree to write', PDLEVEL2 );
                $rv = 1;
            }

            pclose($file);
        }
    }

    subPostamble( PDLEVEL1, '$', $rv );

    return $rv;
}

sub _readRecord {

    # Purpose:  Reads the node from the file
    # Returns:  Boolean
    # Usage:    $rv = _readRecord($self, $filename);

    my $self = shift;
    my $file = shift;
    my ( $rv,    $node, $sig, $content );
    my ( $stype, $kf,   $vf,  $kl, $vl, $kv, $vv );
    my ( $kl1,   $kl2,  $vl1, $vl2 );

    # Read Signature
    if ( pread( $file, $sig, SIG_LEN ) == SIG_LEN ) {
        ( $stype, $kf, $vf, $kl1, $kl2, $vl1, $vl2 ) = unpack SIGNATURE, $sig;
        if ( $stype eq SIG_TYPE ) {
            $rv = 1;
            $kl = longs2Quad( $kl1, $kl2 );
            $vl = longs2Quad( $vl1, $vl2 );

            if ( !defined $kl or !defined $vl ) {
                $rv = 0;
                pdebug( '64-bit values not supported on 32-bit platforms',
                    PDLEVEL1 );
            }
        } else {
            pdebug( 'PDAVL signature failed basic validation: %s',
                PDLEVEL1, $sig );
        }
    } else {
        pdebug( 'failed to read PDAVL signature', PDLEVEL1 );
    }

    # Extract key/val lengths/values
    if ($rv) {
        if ($kf) {
            $kv = '' if $kf == AVLZEROLS;
        }
        if ($vf) {
            $vv = '' if $vf == AVLZEROLS;
        }
    }

    # Read key
    if ( $rv and $kl ) {
        if ( pread( $file, $content, $kl ) == $kl ) {
            $kv = $content;
        } else {
            pdebug( 'failed to read full length of key content', PDLEVEL1 );
            $rv = 0;
        }
    }

    # Read value
    if ( $rv and $vl ) {
        if ( pread( $file, $content, $vl ) == $vl ) {
            $vv = $content;
        } else {
            pdebug( 'failed to read full length of key content', PDLEVEL1 );
            $rv = 0;
        }
    }

    # Add the key/pair
    $rv = $self->addPair( $kv, $vv ) if $rv;

    pdebug( 'failed to read record', PDLEVEL1 ) unless $rv;

    return $rv;
}

sub loadFromFile {

    # Purpose:  Loads content from file
    # Returns:  Boolean
    # Usage:    $rv = $obj->loadFromFile($file);

    my $self = shift;
    my $file = shift;
    my ( $rv, $eof );

    subPreamble( PDLEVEL1, '$', $file );

    # Purge current hash contents
    $self->purgeNodes;

    # Make sure file is open and at the beginning
    if ( defined popen( $file, O_RDWR ) ) {
        $eof = pseek( $file, 0, SEEK_END );
        pseek( $file, 0, SEEK_SET );

        # Read records
        do {
            $rv = _readRecord( $self, $file );
        } while $rv and ptell($file) != $eof;

        pclose($file);
    }

    subPostamble( PDLEVEL1, '$', $rv );

    return $rv;
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

$Id: lib/Paranoid/Data/AVLTree.pm, 2.10 2022/03/08 00:01:04 acorliss Exp $

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
    $tree->profile(1);
    %stats = $tree->stats;

    $rv = $tree->save2File($filename);
    $rv = $tree->loadFromFile($filename);

=head1 DESCRIPTION

This class provides an AVL-balance tree implementation, that can work both as
an independent object or as a tied hash.  Future versions will include methods
to allow for simple spooling to and from disk.

B<NOTE:> while these objects do support assignment of any arbitrary value to
each node, spooling to and from files only supports the use of scalar values.
Any object/code references, globs, or nested data structures will not survive
save/load functionality.

=head1 SUBROUTINES/METHODS

=head2 new

    $tree   = new Paranoid::Data::AVLTree;

This creates a new tree object.

=head2 profile

    $rv     = $obj->profile(1);
    $rv     = $obj->profile(0);

This method enables or disables performance profiling, which can provide some
basic statistics on internal operations.  Whenever profiling is enabled the
counters are reset.

=head2 stats

    %stats = $obj->stats;

This method returns a hash of various performance counters.  The contents of
the hash at this time consists of the following:

    key         purpose
    ------------------------------------------------
    insertions  number of node insertions
    deletions   number of node deletions
    rebalances  number of rebalances triggered
    rotations   number of branch rotations triggered

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

=head2 save2File

    $rv = $tree->save2File($filename);

This method saves the current contents of the AVL Tree to the specified file.
It attempts to save the nodes in an order which minimizes the number of
rotations when read to maximize loading performance.

=head2 loadFromFile

    $rv = $tree->loadFromFile($filename);

This method loads the contents of the named file into memory.  It does only the
most rudimentary validation of records upon loading.  Note that the current
contents of the AVL Tree is purged prior to loading to ensure the contents
after loading reflect precisely what is in the file.  That said, if there is
any kind of file corruption in the middle of the file, it can mean the AVL
Tree is only partially loaded after a failed attempt.

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

