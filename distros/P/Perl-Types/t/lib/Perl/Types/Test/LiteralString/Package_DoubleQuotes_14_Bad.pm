# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPC02' >>>
# <<< PARSE_ERROR: 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals' >>>

# [[[ HEADER ]]]
package Perl::Types::Test::LiteralString::Package_DoubleQuotes_14_Bad;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ SUBROUTINES ]]]
sub empty_sub { { my string $RETURN_TYPE }; return "'foo'{bar}"; }

1;    # end of package
