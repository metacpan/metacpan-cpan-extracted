# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPL02' >>>
# <<< PARSE_ERROR: 'near "my hashref::number foo "' >>>

# [[[ HEADER ]]]
package Perl::Types::Test::SubroutineArguments::Package_03_Bad;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ SUBROUTINES ]]]
sub empty_sub {
    { my void $RETURN_TYPE };
    ( my hashref::number foo ) = @ARG;
    return 1;
}

1;    # end of package
