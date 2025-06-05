# [[[ HEADER ]]]
package Perl::Structure::Hash::Properties;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.001_100;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Structure::Hash);
use Perl::Structure::Hash;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names

# [[[ INCLUDES ]]]
use Scalar::Util 'blessed';

# [[[ OO PROPERTIES ]]]
our hashref $properties = {  # whoah, so meta
    property_entries => my object_hashref $TYPED_property_entries = undef
};

# [[[ SUBROUTINES & OO METHODS ]]]

# ...

# [[[ SUB-TYPES ]]]

# a property is a data structure belonging to a class or object, each RPerl object has a properties hash
package  # hide from PAUSE indexing
    properties;
use strict;
use warnings;
use parent qw(Perl::Structure::Hash::Properties);

1;  # end of class
