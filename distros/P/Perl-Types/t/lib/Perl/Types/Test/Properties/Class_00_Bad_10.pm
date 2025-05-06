# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPL02' >>>
# <<< PARSE_ERROR: 'Global symbol "$TYPED_empty_property" requires explicit use Perl::Types;
package name' >>>

# [[[ HEADER ]]]
package Perl::Types::Test::Properties::Class_00_Bad_10;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Types::Test);
use Perl::Types::Test;

# [[[ OO PROPERTIES ]]]
our hashref $properties
    = { empty_property =>  integer $TYPED_empty_property = 2 };

# [[[ SUBROUTINES & OO METHODS ]]]
sub empty_method { { my integer::method $RETURN_TYPE }; return 2; }

1;                  # end of class
