# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPL02' >>>
# <<< PARSE_ERROR: 'Bareword found where operator expected' >>>

# [[[ HEADER ]]]
package Perl::Types::Test::LiteralNumber::Package_80_Bad_00;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ SUBROUTINES ]]]
sub empty_sub { { my number $RETURN_TYPE }; return 23_456.234_567_89e; }

1;    # end of package
