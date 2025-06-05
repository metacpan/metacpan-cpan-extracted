# [[[ HEADER ]]]
package Perl::Structure::Graph::TreeReference;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Structure);
use Perl::Structure;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {};

1;    # end of class
