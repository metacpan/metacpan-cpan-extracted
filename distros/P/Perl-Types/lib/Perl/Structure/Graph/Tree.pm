package Perl::Structure::Graph::Tree;
use strict;
use warnings; 
use Perl::Types;
our $VERSION = 0.001_000;

# NEED FIX: weird inheritance for these as-reference-only data structures
package Perl::Structure::Graph::TreeReference;
use parent qw(Perl::Structure::GraphReference);
use Perl::Structure::Graph;

# [[[ GRAPHS ]]]

# ref to tree
package  # hide from PAUSE indexing
    treeref;
use parent qw(Perl::Structure::Graph::TreeReference);
use Perl::Structure::Graph::Tree;

# NEED ADD: remaining sub-types

1;  # end of class