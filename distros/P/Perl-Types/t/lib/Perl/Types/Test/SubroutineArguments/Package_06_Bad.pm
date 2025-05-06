# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPL02' >>>
# <<< PARSE_ERROR: 'near "$bar my hashref::number"' >>>

# [[[ HEADER ]]]
use Perl::Types;
package Perl::Types::Test::SubroutineArguments::Package_06_Bad;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ SUBROUTINES ]]]
sub empty_sub {
    { my void $RETURN_TYPE };
    ( my number $foo, my arrayref::number $bar my hashref::number $baz ) = @ARG;
    return 1;
}

1;    # end of package
