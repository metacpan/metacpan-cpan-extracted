# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPL02' >>>
# <<< PARSE_ERROR: 'near "@;' >>>

# [[[ HEADER ]]]
use Perl::Types;
package Perl::Types::Test::SubroutineArguments::Package_07_Bad;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ SUBROUTINES ]]]
sub empty_sub {
    { my void $RETURN_TYPE };
    ( my number $foo, my string $bar, my arrayref::scalartype $baz, my hashref::integer $bat ) = @;
    return 1;
}

1;    # end of package
