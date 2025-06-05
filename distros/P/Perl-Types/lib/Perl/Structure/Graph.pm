package Perl::Structure::Graph;
use strict;
use warnings; 
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.001_000;

use parent qw(Perl::Type::Modifier::Reference);
use Perl::Type::Modifier::Reference;


# [[[ GRAPHS ]]]

# ref to graph
package  # hide from PAUSE indexing
    graphref;
use parent qw(Perl::Structure::GraphReference); 
use Perl::Structure::Graph;

# NEED ADD: remaining sub-types

1;  # end of class
