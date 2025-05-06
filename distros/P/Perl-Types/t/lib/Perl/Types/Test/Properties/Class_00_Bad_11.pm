# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPARP00' >>>

# [[[ HEADER ]]]
use Perl::Types;
package Perl::Types::Test::Properties::Class_00_Bad_11;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Types::Test);
use Perl::Types::Test;

# [[[ OO PROPERTIES ]]]
our hashref $properties
    = { empty_property => my  $TYPED_empty_property = 2 };

# [[[ SUBROUTINES & OO METHODS ]]]
sub empty_method { { my integer::method $RETURN_TYPE }; return 2; }

1;                  # end of class
