# [[[ HEADER ]]]
package Perl::Types::Test;
use strict;
use warnings;
use types;
our $VERSION = 0.004_000;

# [[[ OO INHERITANCE ]]]
use parent qw(class);
use class;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ OO PROPERTIES ]]]
our hashref $properties = {};

# [[[ SUBROUTINES & OO METHODS ]]]

# OO INHERITANCE TESTING
sub empty_method {
    { my void $RETURN_TYPE };
    ( my Perl::Types::Test $self ) = @ARG;
    print 'Hello, World!', "\n";
    return;
}

1;                  # end of class
