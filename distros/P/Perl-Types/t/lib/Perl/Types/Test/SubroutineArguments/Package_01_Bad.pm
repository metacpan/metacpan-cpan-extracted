# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPL02' >>>
# <<< PARSE_ERROR: 'near "( my strin"' >>>

# [[[ HEADER ]]]
package Perl::Types::Test::SubroutineArguments::Package_01_Bad;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ SUBROUTINES ]]]
sub empty_sub {
    { my void $RETURN_TYPE };
    ( my strin $foo ) = @ARG;
    return 1;
}

1;    # end of package
