# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPL02' >>>
# <<< PARSE_ERROR: 'Bareword "empty_property" not allowed while "strict subs" in use' >>>

# [[[ HEADER ]]]
package Perl::Types::Test::Properties::Class_00_Bad_06;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Types::Test);
use Perl::Types::Test;

# [[[ OO PROPERTIES ]]]
our hashref $properties
    = { empty_property > my integer $TYPED_empty_property = 2 };

# [[[ SUBROUTINES & OO METHODS ]]]
sub empty_method { { my integer $RETURN_TYPE }; return 2; }

1;                  # end of class
