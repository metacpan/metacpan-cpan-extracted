# [[[ HEADER ]]]
package Perl::Type::NonsignedInteger;
use strict;
use warnings;
#use Perl::Types;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.008_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Type::Scalar);
use Perl::Type::Scalar;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names

# [[[ INCLUDES ]]]
use English;  # normally this would come from `use Perl::Types;` above

# DEV NOTE, CORRELATION #rp500 COMPILER REFACTOR: must use "nonsigned_integer" typedef because "unsigned_integer" or even "unsignedinteger" will trigger false error messages...

# [[[ SUB-TYPES ]]]
# an nonsigned_integer is a whole number greater or equal to zero, it has no floating-pointer (fractional/decimal) component or negative value
package    # hide from PAUSE indexing
    nonsigned_integer;
use strict;
use warnings;
use parent qw(Perl::Type::NonsignedInteger);

package    # hide from PAUSE indexing
    constant_nonsigned_integer;
use strict;
use warnings;
use parent qw(Perl::Type::NonsignedInteger);

# [[[ PRE-DECLARED TYPES ]]]
package    # hide from PAUSE indexing
    boolean;
package     # hide from PAUSE indexing
    integer;
package    # hide from PAUSE indexing
    number;
package    # hide from PAUSE indexing
    character;
package    # hide from PAUSE indexing
    string;

# [[[ SWITCH CONTEXT BACK TO PRIMARY PACKAGE ]]]
package Perl::Type::NonsignedInteger;
use strict;
use warnings;

# [[[ EXPORTS ]]]
use Exporter 'import';
our @EXPORT = qw(nonsigned_integer_CHECK nonsigned_integer_CHECKTRACE nonsigned_integer_to_boolean nonsigned_integer_to_integer nonsigned_integer_to_number nonsigned_integer_to_character nonsigned_integer_to_string);
our @EXPORT_OK = qw(nonsigned_integer_typetest0 nonsigned_integer_typetest1);

# [[[ TYPE-CHECKING ]]]
sub nonsigned_integer_CHECK {
    { my void $RETURN_TYPE };
    ( my $possible_nonsigned_integer ) = @ARG;
    if ( not( defined $possible_nonsigned_integer ) ) {
#        croak("\nERROR EIV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nnonsigned_integer value expected but undefined/null value found,\ncroaking");
        die("\nERROR EIV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nnonsigned_integer value expected but undefined/null value found,\ndying\n");
    }
    if ( not( main::PerlTypes_SvUIOKp($possible_nonsigned_integer) ) ) {
#        croak("\nERROR EIV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nnonsigned_integer value expected but non-nonsigned_integer value found,\ncroaking");
        dying("\nERROR EIV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nnonsigned_integer value expected but non-nonsigned_integer value found,\ndying\n");
    }
    return;
}
sub nonsigned_integer_CHECKTRACE {
    { my void $RETURN_TYPE };
    ( my $possible_nonsigned_integer, my $variable_name, my $subroutine_name ) = @ARG;
    if ( not( defined $possible_nonsigned_integer ) ) {
#        croak( "\nERROR EIV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nnonsigned_integer value expected but undefined/null value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        dying( "\nERROR EIV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nnonsigned_integer value expected but undefined/null value found,\nin variable $variable_name from subroutine $subroutine_name,\ndying\n" );
    }
    if ( not( main::PerlTypes_SvUIOKp($possible_nonsigned_integer) ) ) {
#        croak( "\nERROR EIV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nnonsigned_integer value expected but non-nonsigned_integer value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        dying( "\nERROR EIV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nnonsigned_integer value expected but non-nonsigned_integer value found,\nin variable $variable_name from subroutine $subroutine_name,\ndying\n" );
    }
    return;
}

# [[[ BOOLEANIFY ]]]
sub nonsigned_integer_to_boolean {
    { my boolean $RETURN_TYPE };
    ( my nonsigned_integer $input_nonsigned_integer ) = @ARG;
#    nonsigned_integer_CHECK($input_nonsigned_integer);
    nonsigned_integer_CHECKTRACE( $input_nonsigned_integer, '$input_nonsigned_integer', 'nonsigned_integer_to_boolean()' );
    if   ( $input_nonsigned_integer == 0 ) { return 0; }
    else                                  { return 1; }
    return;
}

# [[[ INTEGERIFY ]]]
sub nonsigned_integer_to_integer {
    { my integer $RETURN_TYPE };
    ( my nonsigned_integer $input_nonsigned_integer ) = @ARG;
#    nonsigned_integer_CHECK($input_nonsigned_integer);
    nonsigned_integer_CHECKTRACE( $input_nonsigned_integer, '$input_nonsigned_integer', 'nonsigned_integer_to_integer()' );
    return $input_nonsigned_integer;
}

# [[[ NUMBERIFY ]]]
sub nonsigned_integer_to_number {
    { my number $RETURN_TYPE };
    ( my nonsigned_integer $input_nonsigned_integer ) = @ARG;
#    nonsigned_integer_CHECK($input_nonsigned_integer);
    nonsigned_integer_CHECKTRACE( $input_nonsigned_integer, '$input_nonsigned_integer', 'nonsigned_integer_to_number()' );
    return ($input_nonsigned_integer * 1.0);
}

# [[[ CHARACTERIFY ]]]
sub nonsigned_integer_to_character {
    { my character $RETURN_TYPE };
    ( my nonsigned_integer $input_nonsigned_integer ) = @ARG;
#    nonsigned_integer_CHECK($input_nonsigned_integer);
    nonsigned_integer_CHECKTRACE( $input_nonsigned_integer, '$input_nonsigned_integer', 'nonsigned_integer_to_character()' );
    my string $tmp_string = nonsigned_integer_to_string($input_nonsigned_integer);
    if   ( $tmp_string eq q{} ) { return q{}; }
    else                        { return (substr $tmp_string, 0, 1); }
    return;
}

# [[[ STRINGIFY ]]]
sub nonsigned_integer_to_string {
    { my string $RETURN_TYPE };
    ( my nonsigned_integer $input_nonsigned_integer ) = @ARG;
#    nonsigned_integer_CHECK($input_nonsigned_integer);
    nonsigned_integer_CHECKTRACE( $input_nonsigned_integer, '$input_nonsigned_integer', 'nonsigned_integer_to_string()' );

    #    Perl::diag("in PERLOPS_PERLTYPES nonsigned_integer_to_string(), received \$input_nonsigned_integer = $input_nonsigned_integer\n");
    #    Perl::diag("in PERLOPS_PERLTYPES nonsigned_integer_to_string()...\n");

    # DEV NOTE: disable old stringify w/out underscores
    #    return "$input_nonsigned_integer";

    my string $retval = reverse "$input_nonsigned_integer";
    $retval =~ s/(\d{3})/$1_/gxms;
    if ( ( substr $retval, -1, 1 ) eq '_' ) { chop $retval; }
    $retval = reverse $retval;

    #    Perl::diag('in PERLOPS_PERLTYPES nonsigned_integer_to_string(), have $retval = ' . q{'} . $retval . q{'} . "\n");
    return $retval;
}

# [[[ TYPE TESTING ]]]
sub nonsigned_integer_typetest0 {
    { my nonsigned_integer $RETURN_TYPE };
    my nonsigned_integer $retval = ( 21 / 7 ) + main::Perl__Type__NonsignedInteger__MODE_ID(); # return nonsigned_integer (not number) value, don't do (22 / 7) etc.

    #    Perl::diag("in PERLOPS_PERLTYPES nonsigned_integer_typetest0(), have \$retval = $retval\n");
    return $retval;
}

sub nonsigned_integer_typetest1 {
    { my nonsigned_integer $RETURN_TYPE };
    ( my nonsigned_integer $lucky_nonsigned_integer ) = @ARG;
#    nonsigned_integer_CHECK($lucky_nonsigned_integer);
    nonsigned_integer_CHECKTRACE( $lucky_nonsigned_integer, '$lucky_nonsigned_integer', 'nonsigned_integer_typetest1()' );

#    Perl::diag('in PERLOPS_PERLTYPES nonsigned_integer_typetest1(), received $lucky_nonsigned_integer = ' . nonsigned_integer_to_string($lucky_nonsigned_integer) . "\n");
    return ( ( $lucky_nonsigned_integer * 2 ) + main::Perl__Type__NonsignedInteger__MODE_ID() );
}

# DEV NOTE, CORRELATION #rp018: Perl::Type::*.pm files do not 'use RPerl;' and thus do not trigger the pseudo-source-filter contained in
# RPerl::CompileUnit::Module::Class::create_symtab_entries_and_accessors_mutators(),
# so *__MODE_ID() subroutines are hard-coded here instead of auto-generated there
package main;
use strict;
use warnings;
sub Perl__Type__NonsignedInteger__MODE_ID { return 0; }

1;    # end of class
