# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPL02' >>>
# <<< PARSE_ERROR: 'Global symbol "$foo" requires explicit use Perl::Types;
package name' >>>

# [[[ HEADER ]]]
package Perl::Types::Test::LiteralString::Package_DoubleQuotes_05_Bad;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ SUBROUTINES ]]]
sub empty_sub { { my string $RETURN_TYPE }; return "\n$foo\nbar"; }

1;    # end of package
