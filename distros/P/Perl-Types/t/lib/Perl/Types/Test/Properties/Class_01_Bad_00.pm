# [[[ PREPROCESSOR ]]]
# <<< GENERATE_ERROR: 'ERROR ECOGEAS' >>>
# <<< GENERATE_ERROR: 'P11' >>>
# <<< GENERATE_ERROR: "OO property 'yyz' already declared in parent namespace 'Perl::Types::Test::Foo::'" >>>
# <<< GENERATE_ERROR: 'name masking disallowed' >>>

# [[[ HEADER ]]]
package Perl::Types::Test::Properties::Class_01_Bad_00;
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Types::Test::Foo);
use Perl::Types::Test::Foo;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    yyz => my hashref::number $TYPED_yyz = { a => 2.2, b => 5.3, c => 8.4 }
};

1;    # end of class
