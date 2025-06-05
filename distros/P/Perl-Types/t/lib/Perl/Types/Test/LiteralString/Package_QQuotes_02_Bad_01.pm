# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPARP00' >>>
# <<< PARSE_ERROR: 'Unexpected Token:  {' >>>

# [[[ HEADER ]]]
package Perl::Types::Test::LiteralString::Package_QQuotes_02_Bad_01;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ SUBROUTINES ]]]
sub empty_sub { { my string $RETURN_TYPE }; return q{foo\ n}; }

1;    # end of package
