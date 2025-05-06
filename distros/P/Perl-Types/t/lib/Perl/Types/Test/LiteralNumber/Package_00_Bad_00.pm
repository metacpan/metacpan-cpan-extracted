# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPL02' >>>
# <<< PARSE_ERROR: 'Can't modify constant item in predecrement' >>>

# [[[ HEADER ]]]
use Perl::Types;
package Perl::Types::Test::LiteralNumber::Package_00_Bad_00;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ SUBROUTINES ]]]
sub empty_sub { { my integer $RETURN_TYPE }; return --2; }

1;                  # end of package
