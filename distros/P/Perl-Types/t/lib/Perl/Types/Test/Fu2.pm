# [[[ HEADER ]]]
use Perl::Types;
package Perl::Types::Test::Fu2;
use strict;
use warnings;
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
    { my void::method $RETURN_TYPE };
    ( my object $self, my integer $howdy, my hashref::string $doody) = @ARG;
    return 2;
}
1;    # end of class
