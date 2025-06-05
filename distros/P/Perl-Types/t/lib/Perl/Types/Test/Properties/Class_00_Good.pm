# [[[ HEADER ]]]
package Perl::Types::Test::Properties::Class_00_Good;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Types::Test);
use Perl::Types::Test;

# [[[ OO PROPERTIES ]]]
our hashref $properties
    = { test_property => my integer $TYPED_test_property = 2 };

# [[[ SUBROUTINES & OO METHODS ]]]
sub test_method {
    { my integer $RETURN_TYPE };
    ( my Perl::Types::Test::Properties::Class_00_Good $self, my integer $input_integer ) = @ARG;
    $self->{test_property} *= $input_integer;
    return $self->{test_property};
}

1;    # end of class
