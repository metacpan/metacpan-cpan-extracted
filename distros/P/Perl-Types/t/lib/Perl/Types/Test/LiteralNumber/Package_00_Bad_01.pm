# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPL02' >>>
# <<< PARSE_ERROR: 'Bareword "_2" not allowed' >>>

# [[[ HEADER ]]]
package Perl::Types::Test::LiteralNumber::Package_00_Bad_01;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ SUBROUTINES ]]]
sub empty_sub { { my integer $RETURN_TYPE }; return _2; }

1;                  # end of package
