# [[[ HEADER ]]]
## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names
package  # hide from PAUSE indexing
    perltypesconv;
use strict;
use warnings;
our $VERSION = 0.005_000;

# DEV NOTE, CORRELATION #rp012: type system includes, hard-copies in perltypes.pm & perltypesconv.pm & Class.pm

# [[[ DATA TYPES ]]]
#use Perl::Type::Void;
use Perl::Type::Boolean;
use Perl::Type::NonsignedInteger;
use Perl::Type::Integer;
use Perl::Type::Number;
use Perl::Type::Character;
use Perl::Type::String;
#use Perl::Type::Scalar;
#use Perl::Type::Unknown;
#use Perl::Type::FileHandle;

# [[[ DATA STRUCTURES ]]]
use Perl::Structure::Array;
use Perl::Structure::Array::SubTypes;
use Perl::Structure::Array::Reference;
use Perl::Structure::Hash;
use Perl::Structure::Hash::SubTypes;
use Perl::Structure::Hash::Reference;

# DEV NOTE, CORRELATION #rp008: use Exporter in perltypes.pm instead of here

=DISABLED_REPLACED_IN_RPERLTYPES
# [[[ EXPORTS ]]]
use Exporter 'import';

# DEV NOTE: don't include generic type conversion subroutines such as to_number() & to_string() in @EXPORT below, causes error:
# Subroutine main::to_number redefined at /usr/share/perl/5.18/Exporter.pm
our @EXPORT = qw(
    boolean_CHECK boolean_CHECKTRACE boolean_to_nonsigned_integer boolean_to_integer boolean_to_number boolean_to_character boolean_to_string
    nonsigned_integer_CHECK nonsigned_integer_CHECKTRACE nonsigned_integer_to_boolean nonsigned_integer_to_integer nonsigned_integer_to_number nonsigned_integer_to_character nonsigned_integer_to_string
    integer_CHECK integer_CHECKTRACE integer_to_boolean integer_to_nonsigned_integer integer_to_number integer_to_character integer_to_string
    number_CHECK number_CHECKTRACE number_to_boolean number_to_nonsigned_integer number_to_integer number_to_character number_to_string
    character_CHECK character_CHECKTRACE character_to_boolean character_to_nonsigned_integer character_to_integer character_to_number character_to_string
    string_CHECK string_CHECKTRACE string_to_boolean string_to_nonsigned_integer string_to_integer string_to_number string_to_character string_to_string
    arrayref_CHECK arrayref_CHECKTRACE arrayref_integer_CHECK arrayref_integer_CHECKTRACE arrayref_number_CHECK arrayref_number_CHECKTRACE arrayref_string_CHECK arrayref_string_CHECKTRACE
    hashref_CHECK hashref_CHECKTRACE integer_hashref_CHECK integer_hashref_CHECKTRACE number_hashref_CHECK number_hashref_CHECKTRACE string_hashref_CHECK string_hashref_CHECKTRACE
);
=cut

1;  # end of package
