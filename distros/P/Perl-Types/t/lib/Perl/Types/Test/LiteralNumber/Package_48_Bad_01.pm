# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPL02' >>>
# <<< PARSE_ERROR: 'Misplaced _ in number' >>>

# [[[ HEADER ]]]
use Perl::Types;
package Perl::Types::Test::LiteralNumber::Package_48_Bad_01;
use strict;
use warnings;
our $VERSION = 0.001_000;

sub empty_sub { { my number $RETURN_TYPE }; return 23_456._2; }

1;    # end of package
