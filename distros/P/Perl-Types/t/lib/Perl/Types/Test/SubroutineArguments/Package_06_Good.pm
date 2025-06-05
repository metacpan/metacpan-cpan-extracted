# [[[ HEADER ]]]
package Perl::Types::Test::SubroutineArguments::Package_06_Good;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ SUBROUTINES ]]]
sub empty_sub { { my void $RETURN_TYPE }; ( my number $foo, my arrayref::number $bar, my hashref::number $baz ) = @ARG; return 1; }

1;    # end of package
