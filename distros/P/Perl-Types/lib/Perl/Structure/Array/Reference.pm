# [[[ HEADER ]]]
package Perl::Structure::Array::Reference;
use strict;
use warnings;
use Perl::Types;
our $VERSION = 0.005_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Type::Modifier::Reference);
use Perl::Type::Modifier::Reference;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ OO PROPERTIES ]]]
# NEED FIX: type 'hashref' not yet defined here,
# makes it impossible to 'use Perl::Structure::Array;' or 'use Perl::Structure::Hash;',
# followed by more cascading errors
our hashref $properties = {};

#our $properties = {};

1;    # end of class
