# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPARP00' >>>
# <<< PARSE_ERROR: 'Unexpected Token:  $TYPED_' >>>

# [[[ HEADER ]]]
package Perl::Types::Test::Constant::Package_00_Bad_02;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ CONSTANTS ]]]
## no critic qw(ProhibitConstantPragma ProhibitMagicNumbers)  # USER DEFAULT 3: allow constants
use constant PI  => my  $TYPED_PI  = 3.141_59;
use constant PIE => my string $TYPED_PIE = 'pecan';

# [[[ SUBROUTINES ]]]
sub empty_sub { { my void $RETURN_TYPE }; return 2; }

1;                  # end of package
