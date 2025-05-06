# [[[ HEADER ]]]
package Perl::Structure::CodeReference;
use strict;
use warnings;
use Perl::Types;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Type::Modifier::Reference);
use Perl::Type::Modifier::Reference

# [[[ OO PROPERTIES ]]]
our hashref $properties = {};

# [[[ SUB-TYPES ]]]

package  # hide from PAUSE indexing
    coderef;
use strict;
use warnings;
use parent -norequire, qw(Perl::Structure::CodeReference);

1;    # end of class

