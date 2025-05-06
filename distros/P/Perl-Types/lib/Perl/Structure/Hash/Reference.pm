# [[[ HEADER ]]]
package Perl::Structure::Hash::Reference;
use strict;
use warnings;
use Perl::Types;
our $VERSION = 0.004_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Type::Modifier::Reference);
use Perl::Type::Modifier::Reference;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ OO PROPERTIES ]]]
our hashref $properties = {};

1;    # end of class
