# [[[ HEADER ]]]
package Perl::Types::Test::LiteralString::Package_QQuotes_02_Good;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ SUBROUTINES ]]]
sub empty_sub { { my string $RETURN_TYPE }; return q{foo\\n}; }

1;    # end of package
