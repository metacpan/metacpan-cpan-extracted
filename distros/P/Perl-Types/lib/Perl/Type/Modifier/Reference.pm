# [[[ HEADER ]]]
package Perl::Type::Modifier::Reference;
use strict;
use warnings;
#use Perl::Types;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.002_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Type::Modifier);
use Perl::Type::Modifier;

# [[[ SUB-TYPES ]]]
# a reference is the location of a data type or data structure;
# a reference is not a data type, regardless of Perl's internal RV type, use 'unknown' instead
# NEED FIX???: overload Perl's 'ref' keyword
package  # hide from PAUSE indexing
    ref;
use strict;
use warnings;
use parent qw(Perl::Type::Modifier::Reference);

1;  # end of class
