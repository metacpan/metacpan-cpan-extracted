# [[[ HEADER ]]]
package Perl::Types::Test::LiteralString::Package_QQuotes_06_Good;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ SUBROUTINES ]]]
sub empty_sub { { my string $RETURN_TYPE }; return q{`~!#%^&*()-_=+[]\\|;:'",<.>/?}; }

1;    # end of package
