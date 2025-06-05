# [[[ HEADER ]]]
package Perl::Types::Test::Fu2;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Types::Test);
use Perl::Types::Test;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)
## no critic qw(RequireInterpolationOfMetachars)
## no critic qw(ProhibitConstantPragma ProhibitMagicNumbers)

# [[[ OO PROPERTIES ]]]
our hashref $properties = { thud => my arrayref::integer $TYPED_thud = [] };

# [[[ SUBROUTINES & OO METHODS ]]]
sub quux {
    { my void $RETURN_TYPE };
    ( my Perl::Types::Test::Fu2 $self, my integer $howdy, my hashref::string $doody) = @ARG;
    return 2;
}
1;    # end of class
