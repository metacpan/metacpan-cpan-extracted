# [[[ HEADER ]]]
package Perl::Type::String;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.015_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Type::Scalar);
use Perl::Type::Scalar;

# [[[ CRITICS ]]]
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names

# [[[ SUB-TYPES ]]]
# a string is 0 or more letters, digits, or other ASCII (Unicode???) symbols
package string;
use strict;
use warnings;
use parent qw(Perl::Type::String);

# [[[ SWITCH CONTEXT BACK TO PRIMARY PACKAGE ]]]
package Perl::Type::String;
use strict;
use warnings;

# [[[ INCLUDES ]]]
use POSIX qw(floor);

# DEV NOTE: do not put inside INIT{} block, because it will be "too late to run INIT block" in some cases, such as inside Catalyst
# DEV NOTE, CORRELATION #rp040: fix recursive dependencies of String.pm & HelperFunctions_cpp.pm, as triggered by ingy's Inline::create_config_file() system() call
# DEV NOTE, DO NOT REMOVE!  [error] Caught exception in ShinyCMS::Controller::Code->run_command "Undefined subroutine &main::PerlTypes_SvPOKp called at /home/wbraswell/github_repos/rperl-latest/lib/Perl/Type/String.pm line 82."
#if (not ((exists $ARGV[0]) and (defined $ARGV[0]) and ((substr $ARGV[0], -7, 7) eq '_Inline'))) {
#if (0) {
    use Perl::HelperFunctions_cpp;  # main::PerlTypes_SvPOKp
    Perl::HelperFunctions_cpp::cpp_load();
#}

# [[[ EXPORTS ]]]
use Exporter 'import';
our @EXPORT = qw(string_CHECK string_CHECKTRACE string_to_boolean string_to_nonsigned_integer string_to_integer string_to_number string_to_character string_to_string);
our @EXPORT_OK = qw(string_typetest0 string_typetest1);

# [[[ TYPE CHECKING ]]]
sub string_CHECK {
    { my void $RETURN_TYPE };
    ( my $possible_string ) = @ARG;
    if ( not( defined $possible_string ) ) {
#        croak( "\nERROR EPV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nstring value expected but undefined/null value found,\ncroaking" );
        die( "\nERROR EPV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nstring value expected but undefined/null value found,\ndying\n" );
    }
    if ( not( main::PerlTypes_SvPOKp($possible_string) ) ) {
#        croak( "\nERROR EPV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nstring value expected but non-string value found,\ncroaking" );
        die( "\nERROR EPV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nstring value expected but non-string value found,\ndying\n" );
    }
    return;
}

# DEV NOTE: avoid error for those packages which do NOT 'use RPerl', but instead do 'use Perl::Types' and 'use Perl::Config' and 'use perltypesconv' etc.
# "Undefined subroutine &Perl::Type::String::string_CHECKTRACE called at lib/Perl/Type/String.pm line XYZ   [ in string_to_integer() below ]
sub string_CHECKTRACE {
    { my void $RETURN_TYPE };
    ( my $possible_string, my $variable_name, my $subroutine_name ) = @ARG;
    if ( not( defined $possible_string ) ) {
#        croak( "\nERROR EPV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nstring value expected but undefined/null value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        die( "\nERROR EPV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nstring value expected but undefined/null value found,\nin variable $variable_name from subroutine $subroutine_name,\ndying\n" );
    }
    if ( not( main::PerlTypes_SvPOKp($possible_string) ) ) {
#        croak( "\nERROR EPV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nstring value expected but non-string value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        die( "\nERROR EPV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nstring value expected but non-string value found,\nin variable $variable_name from subroutine $subroutine_name,\ndying\n" );
    }
    return;
}

# [[[ BOOLEANIFY ]]]
sub string_to_boolean {
    { my boolean $RETURN_TYPE };
    (my string $input_string) = @ARG;
#    string_CHECK($input_string);
    string_CHECKTRACE( $input_string, '$input_string', 'string_to_boolean()' );
    $input_string =~ s/_//gxms;  # remove underscores to allow them in $input_string, fixes "Argument isn't numeric in multiplication (*)"
    if (($input_string * 1) == 0) { return 0; }
    else { return 1; }
    return;
}

# [[[ UNSIGNED INTEGERIFY ]]]
sub string_to_nonsigned_integer {
    { my integer $RETURN_TYPE };
    (my string $input_string) = @ARG;
#    string_CHECK($input_string);
    string_CHECKTRACE( $input_string, '$input_string', 'string_to_nonsigned_integer()' );
    $input_string =~ s/_//gxms;  # remove underscores to allow them in $input_string, fixes "Argument isn't numeric in multiplication (*)"
    return (floor(abs ($input_string * 1)) * 1);
}

# [[[ INTEGERIFY ]]]
sub string_to_integer {
    { my integer $RETURN_TYPE };
    (my string $input_string) = @ARG;
#    string_CHECK($input_string);
    string_CHECKTRACE( $input_string, '$input_string', 'string_to_integer()' );
    # DEV NOTE: must use double-casting via '* 1' below to avoid following errors
    # ERROR EIV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:
    # integer value expected but non-integer value found,
    # in variable input_sv from subroutine XS_unpack_integer(),
    $input_string =~ s/_//gxms;  # remove underscores to allow them in $input_string, fixes "Argument isn't numeric in multiplication (*)"
#    return floor($input_string * 1);
    return (floor($input_string * 1) * 1);
}

# [[[ NUMBERIFY ]]]
sub string_to_number {
    { my number $RETURN_TYPE };
    (my string $input_string) = @ARG;
#    string_CHECK($input_string);
    string_CHECKTRACE( $input_string, '$input_string', 'string_to_number()' );
    $input_string =~ s/_//gxms;  # remove underscores to allow them in $input_string, fixes "Argument isn't numeric in multiplication (*)"
    return ($input_string * 1.0);
}

# [[[ CHARACTERIFY ]]]
sub string_to_character {
    { my character $RETURN_TYPE };
    (my string $input_string) = @ARG;
#    string_CHECK($input_string);
    string_CHECKTRACE( $input_string, '$input_string', 'string_to_character()' );
    if ($input_string eq q{}) { return q{}; }
    else { return (substr $input_string, 0, 1); }
    return;
}

# [[[ STRINGIFY ]]]
sub string_to_string {
    { my string $RETURN_TYPE };
    ( my string $input_string ) = @ARG;
#    string_CHECK($input_string);
    string_CHECKTRACE( $input_string, '$input_string', 'string_to_string()' );

#    Perl::diag("in PERLOPS_PERLTYPES string_to_string(), received \$input_string =\n$input_string\n\n");
    $input_string =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
    $input_string =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
    $input_string = "'$input_string'";

#    Perl::diag("in PERLOPS_PERLTYPES string_to_string(), bottom of subroutine, returning possibly-modified \$input_string =\n$input_string\n\n");
    return $input_string;
}

# [[[ TYPE TESTING ]]]
sub string_typetest0 {
    { my string $RETURN_TYPE };
    my string $retval = 'Spice PERLOPS_PERLTYPES';

#    Perl::diag("in PERLOPS_PERLTYPES string_typetest0(), have \$retval = '$retval'\n");
    return $retval;
}
sub string_typetest1 {
    { my string $RETURN_TYPE };
    ( my string $lucky_string ) = @ARG;
#    string_CHECK($lucky_string);
    string_CHECKTRACE( $lucky_string, '$lucky_string',
        'string_typetest1()' );

#    Perl::diag("in PERLOPS_PERLTYPES string_typetest1(), received \$lucky_string = '$lucky_string'\n");
    return ( string_to_string($lucky_string) . ' PERLOPS_PERLTYPES' );
}

# DEV NOTE, CORRELATION #rp018: Perl::Type::*.pm files do not 'use RPerl;' and thus do not trigger the pseudo-source-filter contained in
# RPerl::CompileUnit::Module::Class::create_symtab_entries_and_accessors_mutators(),
# so *__MODE_ID() subroutines are hard-coded here instead of auto-generated there
package main;
use strict;
use warnings;
sub Perl__Type__String__MODE_ID { return 0; }

1;  # end of class
