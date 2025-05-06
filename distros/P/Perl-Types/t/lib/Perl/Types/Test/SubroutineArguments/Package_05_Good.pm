# [[[ HEADER ]]]
use Perl::Types;
package Perl::Types::Test::SubroutineArguments::Package_05_Good;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ SUBROUTINES ]]]
sub empty_sub { { my void $RETURN_TYPE }; ( my number $foo, my string $bar ) = @ARG; return 1; }

1;    # end of package
