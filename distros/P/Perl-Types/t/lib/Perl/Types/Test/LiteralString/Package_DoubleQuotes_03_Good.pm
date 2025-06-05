# [[[ HEADER ]]]
package Perl::Types::Test::LiteralString::Package_DoubleQuotes_03_Good;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ SUBROUTINES ]]]
sub empty_sub { { my string $RETURN_TYPE }; return "foo\nbar"; }

1;    # end of package
