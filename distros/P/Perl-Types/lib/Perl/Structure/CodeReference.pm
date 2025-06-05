# [[[ HEADER ]]]
package Perl::Structure::CodeReference;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Type::Modifier::Reference);
use Perl::Type::Modifier::Reference

# [[[ OO PROPERTIES ]]]
our hashref $properties = {};

# [[[ SUB-TYPES ]]]

package coderef;
use strict;
use warnings;
use parent -norequire, qw(Perl::Structure::CodeReference);

1;    # end of class

