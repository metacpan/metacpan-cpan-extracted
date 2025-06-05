# [[[ HEADER ]]]
package Perl::Type::Scalar;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.007_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Type);
use Perl::Type;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names

# [[[ CONSTANTS ]]]
# DEV NOTE: the special string 'inf' is recognized by Perl as representing infinity,
# but that is about the limit of the Perl interpreter's abilities and it does not appear to be officially documented?
# NEED ANSWER: why does `use constant INFINITY` cause the following error?
#     Prototype mismatch: sub Perl::Type::Scalar::INFINITY: none vs () at /usr/share/perl/5.30/constant.pm line 171.
# could it be due to wholesale EXPORT and EXPORT_OK in Perl::Config or Perl::Types or perltypes??
#use constant INFINITY => my string $TYPED_INFINITY = 'inf';
use constant INFINITY_VALUE => my string $TYPED_INFINITY_VALUE = 'inf';

# [[[ SUB-TYPES ]]]
# a scalartype is a known, non-void data type, meaning a number or a string
# DEV NOTE: do NOT overload Perl's 'scalar' keyword!!!
package scalartype;
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
