# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPARP00' >>>
# <<< PARSE_ERROR: 'Unexpected Token:  use constant' >>>

# [[[ HEADER ]]]
package Perl::Types::Test::Constant::Package_00_Bad_04;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ CONSTANTS ]]]
## no critic qw(ProhibitConstantPragma ProhibitMagicNumbers)  # USER DEFAULT 3: allow constants
use constant PI  => my number $TYPED_PI  = 3.141_59;

# [[[ SUBROUTINES ]]]
sub empty_sub { { my void $RETURN_TYPE }; return 2; }

use constant PIE => my string $TYPED_PIE = 'pecan';

1;                  # end of package
