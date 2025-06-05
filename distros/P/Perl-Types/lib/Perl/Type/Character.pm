# [[[ HEADER ]]]
package Perl::Type::Character;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.011_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Type::String);
use Perl::Type::String;

# [[[ INCLUDES ]]]
use POSIX qw(floor);

# [[[ SUB-TYPES ]]]
# a character is a string of length 0 or 1, meaning a single letter, digit, or other ASCII (Unicode???) symbol
package character;
use strict;
use warnings;
use parent qw(Perl::Type::Integer);

# [[[ SWITCH CONTEXT BACK TO PRIMARY PACKAGE ]]]
package Perl::Type::Character;
use strict;
use warnings;

# [[[ EXPORTS ]]]
use Exporter 'import';
our @EXPORT = qw(character_CHECK character_CHECKTRACE character_to_boolean character_to_nonsigned_integer character_to_integer character_to_number character_to_string);
our @EXPORT_OK = qw(character_typetest0 character_typetest1);

# [[[ TYPE-CHECKING ]]]
sub character_CHECK {
    { my void $RETURN_TYPE };
    ( my $possible_character ) = @ARG;
    if ( not( defined $possible_character ) ) {
#        croak( "\nERROR ETV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\ncharacter value expected but undefined/null value found,\ncroaking" );
        die( "\nERROR ETV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\ncharacter value expected but undefined/null value found,\ndying\n" );
    }
    if ( not( main::PerlTypes_SvCOKp($possible_character) ) ) {
#        croak( "\nERROR ETV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\ncharacter value expected but non-character value found,\ncroaking" );
        die( "\nERROR ETV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\ncharacter value expected but non-character value found,\ndying\n" );
    }
    return;
}
sub character_CHECKTRACE {
    { my void $RETURN_TYPE };
    ( my $possible_character, my $variable_name, my $subroutine_name ) = @ARG;
    if ( not( defined $possible_character ) ) {
#        croak( "\nERROR ETV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\ncharacter value expected but undefined/null value found,\nin variable " . $variable_name . " from subroutine " . $subroutine_name . ",\ncroaking" );
        die( "\nERROR ETV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\ncharacter value expected but undefined/null value found,\nin variable " . $variable_name . " from subroutine " . $subroutine_name . ",\ndying\n" );
    }
    if ( not( main::PerlTypes_SvCOKp($possible_character) ) ) {
#        croak( "\nERROR ETV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\ncharacter value expected but non-character value found,\nin variable " . $variable_name . " from subroutine " . $subroutine_name . ",\ncroaking" );
        die( "\nERROR ETV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\ncharacter value expected but non-character value found,\nin variable " . $variable_name . " from subroutine " . $subroutine_name . ",\ndying\n" );
    }
    return;
}

# [[[ BOOLEANIFY ]]]
sub character_to_boolean {
    { my boolean $RETURN_TYPE };
    (my character $input_character) = @ARG;
#    character_CHECK($lucky_character);
    character_CHECKTRACE( $input_character, '$input_character', 'character_to_boolean()' );
    if (($input_character * 1) == 0) { return 0; }
    else { return 1; }
    return;
}

# [[[ UNSIGNED INTEGERIFY ]]]
sub character_to_nonsigned_integer {
    { my nonsigned_integer $RETURN_TYPE };
    (my character $input_character) = @ARG;
#    character_CHECK($lucky_character);
    character_CHECKTRACE( $input_character, '$input_character', 'character_to_nonsigned_integer()' );
    return floor(abs ($input_character * 1));
}

# [[[ INTEGERIFY ]]]
sub character_to_integer {
    { my integer $RETURN_TYPE };
    (my character $input_character) = @ARG;
#    character_CHECK($lucky_character);
    character_CHECKTRACE( $input_character, '$input_character', 'character_to_integer()' );
    return floor($input_character * 1);
}

# [[[ NUMBERIFY ]]]
sub character_to_number {
    { my number $RETURN_TYPE };
    (my character $input_character) = @ARG;
#    character_CHECK($lucky_character);
    character_CHECKTRACE( $input_character, '$input_character', 'character_to_number()' );
    return ($input_character * 1.0);
}

# [[[ STRINGIFY ]]]
sub character_to_string {
    { my string $RETURN_TYPE };
    (my character $input_character) = @ARG;
#    character_CHECK($lucky_character);
    character_CHECKTRACE( $input_character, '$input_character', 'character_to_string()' );
    return $input_character;
}

# [[[ TYPE TESTING ]]]
sub character_typetest0 { { my character $RETURN_TYPE }; return chr(main::Perl__Type__Character__MODE_ID() + (ord '0')); }
sub character_typetest1 {
    { my character $RETURN_TYPE };
    (my character $lucky_character) = @ARG;
#    character_CHECK($lucky_character);
    character_CHECKTRACE( $lucky_character, '$lucky_character', 'character_typetest1()' );
    return chr((ord $lucky_character) + main::Perl__Type__Character__MODE_ID());
}

# DEV NOTE, CORRELATION #rp018: Perl::Type::*.pm files do not 'use RPerl;' and thus do not trigger the pseudo-source-filter contained in
# RPerl::CompileUnit::Module::Class::create_symtab_entries_and_accessors_mutators(),
# so *__MODE_ID() subroutines are hard-coded here instead of auto-generated there
package main;
use strict;
use warnings;
sub Perl__Type__Character__MODE_ID { return 0; }

1;  # end of class
