# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPC02' >>>
# <<< PARSE_ERROR: 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyQuotes' >>>

# [[[ HEADER ]]]
use Perl::Types;
package Perl::Types::Test::LiteralString::Package_SingleQuotes_00_Bad;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ SUBROUTINES ]]]
sub empty_sub { { my string $RETURN_TYPE }; return ''; }

1;    # end of package
