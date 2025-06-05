# [[[ PREPROCESSOR ]]]
# <<< PARSE_ERROR: 'ERROR ECOPAPC02' >>>
# <<< PARSE_ERROR: 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitMagicNumbers' >>>

# [[[ HEADER ]]]
package Perl::Types::Test::LiteralNumber::Package_47_Bad_01;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

sub empty_sub { { my number $RETURN_TYPE }; return -2333_456_789.234_56; }

1;    # end of package
