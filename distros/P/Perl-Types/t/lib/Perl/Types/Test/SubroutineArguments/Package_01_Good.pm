# [[[ HEADER ]]]
package Perl::Types::Test::SubroutineArguments::Package_01_Good;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ SUBROUTINES ]]]
sub empty_sub { { my void $RETURN_TYPE }; ( my string $foo ) = @ARG; return 1; }

1;    # end of package
