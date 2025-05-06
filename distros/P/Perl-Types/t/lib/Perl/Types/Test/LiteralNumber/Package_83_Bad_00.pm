# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPARP00' >>>
# <<< PARSE_ERROR: 'Unexpected Token:  -04' >>>

# [[[ HEADER ]]]
use Perl::Types;
package Perl::Types::Test::LiteralNumber::Package_83_Bad_00;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ SUBROUTINES ]]]
sub empty_sub { { my number $RETURN_TYPE }; return 0.e-04; }

1;    # end of package
