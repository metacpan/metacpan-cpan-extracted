# [[[ HEADER ]]]
package Perl::Type::Scalar;
use strict;
use warnings;
#use Perl::Types;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.006_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Type);
use Perl::Type;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names

# [[[ INCLUDES ]]]
use English;  # normally this would come from `use Perl::Types;` above

# [[[ CONSTANTS ]]]
use constant INFINITY => my string $TYPED_INFINITY = 'inf';

# [[[ SUB-TYPES ]]]
# a scalartype is a known, non-void data type, meaning a number or a string
# DEV NOTE: do NOT overload Perl's 'scalar' keyword!!!
package  # hide from PAUSE indexing
    scalartype;
use strict;
use warnings;
use parent qw(Perl::Type::Scalar);

# DEV NOTE, CORRELATION #rp018: Perl::Type::*.pm files do not 'use RPerl;' and thus do not trigger the pseudo-source-filter contained in
# RPerl::CompileUnit::Module::Class::create_symtab_entries_and_accessors_mutators(),
# so *__MODE_ID() subroutines are hard-coded here instead of auto-generated there
package main;
use strict;
use warnings;
sub Perl__Type__Scalar__MODE_ID { return 0; }

1;  # end of class
