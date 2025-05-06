## no critic qw(ProhibitUselessNoCritic PodSpelling ProhibitExcessMainComplexity)  # DEVELOPER DEFAULT 1a: allow unreachable & POD-commented code; SYSTEM SPECIAL 4: allow complex code outside subroutines, must be on line 1
package Perl::Structure::Array::SubTypes1D;
use strict;
use warnings;
use Perl::Types;
our $VERSION = 0.021_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(ProhibitUnreachableCode RequirePodSections RequirePodAtEnd)  # DEVELOPER DEFAULT 1b: allow unreachable & POD-commented code, must be after line 1
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names

# [[[ EXPORTS ]]]
# DEV NOTE, CORRELATION #rp051: hard-coded list of RPerl data types and data structures
use Exporter 'import';
our @EXPORT = qw(
    arrayref_integer_CHECK
    arrayref_integer_CHECKTRACE
    arrayref_number_CHECK
    arrayref_number_CHECKTRACE
    arrayref_string_CHECK
    arrayref_string_CHECKTRACE
    arrayref_integer_to_string_compact
    arrayref_integer_to_string
    arrayref_integer_to_string_pretty
    arrayref_integer_to_string_expand
    arrayref_integer_to_string_format
    arrayref_number_to_string_compact
    arrayref_number_to_string
    arrayref_number_to_string_pretty
    arrayref_number_to_string_expand
    arrayref_number_to_string_format
    arrayref_string_to_string_compact
    arrayref_string_to_string
    arrayref_string_to_string_pretty
    arrayref_string_to_string_expand
    arrayref_string_to_string_format
);
our @EXPORT_OK = qw(
    arrayref_integer_typetest0
    arrayref_integer_typetest1
    arrayref_number_typetest0
    arrayref_number_typetest1
    arrayref_string_typetest0
    arrayref_string_typetest1
);

# [[[ INCLUDES ]]]
use Perl::Type::Integer;  # for integer_CHECKTRACE(), used in arrayref_TYPE_typetest1()

# [[[ PRE-DECLARED TYPES ]]]
package    # hide from PAUSE indexing
    boolean;
package    # hide from PAUSE indexing
    nonsigned_integer;
#package     # hide from PAUSE indexing
#    integer;
package    # hide from PAUSE indexing
    number;
package    # hide from PAUSE indexing
    character;
package    # hide from PAUSE indexing
    string;

# [[[ ARRAY REF INTEGER ]]]
# [[[ ARRAY REF INTEGER ]]]
# [[[ ARRAY REF INTEGER ]]]

# (ref to array) of integers
package arrayref::integer;
use strict;
use warnings;
use parent -norequire, qw(arrayref);
use Carp;

# [[[ SWITCH CONTEXT BACK TO PRIMARY PACKAGE FOR EXPORT TO WORK ]]]
package Perl::Structure::Array::SubTypes1D;
use strict;
use warnings;

# [[[ TYPE-CHECKING ]]]

sub arrayref_integer_CHECK {
    { my void $RETURN_TYPE };
    ( my $possible_arrayref_integer ) = @ARG;

# DEV NOTE: the following two if() statements are functionally equivalent to the arrayref_CHECK() subroutine, but with integer-specific error codes
    if ( not( defined $possible_arrayref_integer ) ) {
        croak( "\nERROR EAVRVIV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\narrayref_integer value expected but undefined/null value found,\ncroaking" );
    }

    if ( not( main::PerlTypes_SvAROKp($possible_arrayref_integer) ) ) {
        croak( "\nERROR EAVRVIV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\narrayref_integer value expected but non-arrayref value found,\ncroaking" );
    }

    my integer $possible_integer;
    for my integer $i ( 0 .. ( ( scalar @{$possible_arrayref_integer} ) - 1 ) )
    {
        $possible_integer = $possible_arrayref_integer->[$i];

# DEV NOTE: the following two if() statements are functionally equivalent to the integer_CHECK() subroutine, but with array-specific error codes
        if ( not( defined $possible_integer ) ) {
            croak( "\nERROR EAVRVIV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\ninteger value expected but undefined/null value found at index $i,\ncroaking" );
        }
        if ( not( main::PerlTypes_SvIOKp($possible_integer) ) ) {
            croak( "\nERROR EAVRVIV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\ninteger value expected but non-integer value found at index $i,\ncroaking" );
        }
    }
    return;
};

sub arrayref_integer_CHECKTRACE {
    { my void $RETURN_TYPE };
    ( my $possible_arrayref_integer, my $variable_name, my $subroutine_name ) = @ARG;
    if ( not( defined $possible_arrayref_integer ) ) {
        croak( "\nERROR EAVRVIV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\narrayref_integer value expected but undefined/null value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
    }
    if ( not( main::PerlTypes_SvAROKp($possible_arrayref_integer) ) ) {
        croak( "\nERROR EAVRVIV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\narrayref_integer value expected but non-arrayref value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
    }

    my integer $possible_integer;
    for my integer $i ( 0 .. ( ( scalar @{$possible_arrayref_integer} ) - 1 ) )
    {
        $possible_integer = $possible_arrayref_integer->[$i];
        if ( not( defined $possible_integer ) ) {
            croak( "\nERROR EAVRVIV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\ninteger value expected but undefined/null value found at index $i,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        }
        if ( not( main::PerlTypes_SvIOKp($possible_integer) ) ) {
            croak( "\nERROR EAVRVIV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\ninteger value expected but non-integer value found at index $i,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        }
    }
    return;
}

# [[[ STRINGIFY ]]]

# DEV NOTE: 1-D format levels are 1 less than 2-D format levels

# call actual stringify routine, format level -2 (compact), indent level 0
sub arrayref_integer_to_string_compact {
    { my string $RETURN_TYPE };
    ( my $input_avref ) = @ARG;
    return arrayref_integer_to_string_format($input_avref, -2, 0);
}

# call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
sub arrayref_integer_to_string {
    { my string $RETURN_TYPE };
    ( my $input_avref ) = @ARG;
    return arrayref_integer_to_string_format($input_avref, -1, 0);
}

# call actual stringify routine, format level 0 (pretty), indent level 0
sub arrayref_integer_to_string_pretty {
    { my string $RETURN_TYPE };
    ( my $input_avref ) = @ARG;
    return arrayref_integer_to_string_format($input_avref, 0, 0);
}

# call actual stringify routine, format level 1 (expand), indent level 0
sub arrayref_integer_to_string_expand {
    { my string $RETURN_TYPE };
    ( my $input_avref ) = @ARG;
    return arrayref_integer_to_string_format($input_avref, 1, 0);
}

# convert from (Perl SV containing RV to (Perl AV of (Perl SVs containing IVs))) to Perl-parsable (Perl SV containing PV)
# stringify an arrayref::integer
sub arrayref_integer_to_string_format {
    { my string $RETURN_TYPE };
    ( my arrayref::integer $input_avref, my integer $format_level, my integer $indent_level ) = @ARG;

#    Perl::diag("in PERLOPS_PERLTYPES arrayref_integer_to_string_format(), top of subroutine\n");
#    Perl::diag('in PERLOPS_PERLTYPES arrayref_integer_to_string_format(), received $format_level = ', $format_level, "\n");
#    Perl::diag('in PERLOPS_PERLTYPES arrayref_integer_to_string_format(), received $indent_level = ', $indent_level, "\n");

#    arrayref_integer_CHECK($input_avref);
    arrayref_integer_CHECKTRACE( $input_avref, '$input_avref', 'arrayref_integer_to_string_format()' );

    # declare local variables, av & sv mean "array value" & "scalar value" as used in Perl core
#    my @input_av;  # DEV NOTE: match CPPOPS_*TYPES code
    my integer $input_av__length;
    my integer $input_av__element;
    my string $output_sv = q{};
    my boolean $i_is_0 = 1;

    # generate indent
    my string $indent = q{    } x $indent_level;

    # compute length of (number of elements in) input array
#    @input_av        = @{$input_avref};  # DEV NOTE: match CPPOPS_*TYPES code
#    $input_av__length = scalar @input_av;  # DEV NOTE: match CPPOPS_*TYPES code
    $input_av__length = scalar @{$input_avref};

#	Perl::diag("in PERLOPS_PERLTYPES arrayref_integer_to_string_format(), have \$input_av__length = $input_av__length\n");

    # pre-begin with optional indent, depending on format level
    if ($format_level >= 1) { $output_sv .= $indent; }

    # begin output string with left-square-bracket, as required for all RPerl arrays
    $output_sv .= '[';

    # loop through all valid values of $i for use as index to input array
    for my integer $i ( 0 .. ( $input_av__length - 1 ) ) {

        # retrieve input array's element at index $i
#        $input_av__element = $input_av[$i];  # DEV NOTE: match CPPOPS_*TYPES code
        $input_av__element = $input_avref->[$i];

# DEV NOTE: type-checking already done as part of arrayref_integer_CHECKTRACE()
#        integer_CHECK($input_av__element);
#integer_CHECKTRACE( $input_av__element, "\$input_av__element at index $i", 'arrayref_integer_to_string_format()' );

        # append comma to output string for all elements except index 0
        if ($i_is_0) { $i_is_0 = 0; }
        else         { $output_sv .= ','; }

        # append newline-indent-tab or space, depending on format level
        if    ($format_level >=  1) { $output_sv .= "\n" . $indent . q{    }; }
        elsif ($format_level >= -1) { $output_sv .= q{ }; }

        # stringify individual element, append to output string
#        $output_sv .= $input_av__element;  # NO UNDERSCORES
        $output_sv .= ::integer_to_string($input_av__element);  # YES UNDERSCORES
    }

    # append newline-indent or space, depending on format level
    if    ($format_level >=  1) { $output_sv .= "\n" . $indent; }
    elsif ($format_level >= -1) { $output_sv .= q{ }; }

    # end output string with right-square-bracket, as required for all RPerl arrays
    $output_sv .= ']';

#    Perl::diag("in PERLOPS_PERLTYPES arrayref_integer_to_string_format(), after for() loop, have \$output_sv =\n$output_sv\n");
#    Perl::diag("in PERLOPS_PERLTYPES arrayref_integer_to_string_format(), bottom of subroutine\n");

    # return output string, containing stringified input array
    return $output_sv;
}

# [[[ TYPE TESTING ]]]

sub arrayref_integer_typetest0 {
    { my string $RETURN_TYPE };
    ( my arrayref::integer $lucky_integers) = @ARG;

    #    arrayref_integer_CHECK($lucky_integers);
    arrayref_integer_CHECKTRACE( $lucky_integers, '$lucky_integers', 'arrayref_integer_typetest0()' );

#    my integer $how_lucky = scalar @{$lucky_integers};
#    for my integer $i ( 0 .. ( $how_lucky - 1 ) ) {
#        my $lucky_integer = $lucky_integers->[$i];
#        Perl::diag("in PERLOPS_PERLTYPES arrayref_integer_typetest0(), have lucky integer $i/" . ( $how_lucky - 1 ) . ' = ' . $lucky_integers->[$i] . ", BARBAT\n");
#    }
#    Perl::diag("in PERLOPS_PERLTYPES arrayref_integer_typetest0(), bottom of subroutine\n");
    return ( arrayref_integer_to_string($lucky_integers) . 'PERLOPS_PERLTYPES' );
}

sub arrayref_integer_typetest1 {
    { my arrayref::integer $RETURN_TYPE };
    ( my integer $my_size) = @ARG;

    #    integer_CHECK($my_size);
    integer_CHECKTRACE( $my_size, '$my_size', 'arrayref_integer_typetest1()' );
    my arrayref::integer $new_array = [];
    for my integer $i ( 0 .. ( $my_size - 1 ) ) {
        $new_array->[$i] = $i * 5;

#        Perl::diag("in PERLOPS_PERLTYPES arrayref_integer_typetest1(), setting element $i/" . ( $my_size - 1 ) . ' = ' . $new_array->[$i] . ", BARBAT\n");
    }
    return ($new_array);
}

# [[[ ARRAY REF NUMBER ]]]
# [[[ ARRAY REF NUMBER ]]]
# [[[ ARRAY REF NUMBER ]]]

# (ref to array) of numbers
package arrayref::number;
use strict;
use warnings;
use parent -norequire, qw(arrayref);
use Carp;

# [[[ SWITCH CONTEXT BACK TO PRIMARY PACKAGE FOR EXPORT TO WORK ]]]
package Perl::Structure::Array::SubTypes1D;
use strict;
use warnings;

# [[[ TYPE-CHECKING ]]]

sub arrayref_number_CHECK {
    { my void $RETURN_TYPE };
    ( my $possible_arrayref_number ) = @ARG;
    if ( not( defined $possible_arrayref_number ) ) {
        croak( "\nERROR EAVRVNV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\narrayref_number value expected but undefined/null value found,\ncroaking" );
    }

    if ( not( main::PerlTypes_SvAROKp($possible_arrayref_number) ) ) {
        croak( "\nERROR EAVRVNV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\narrayref_number value expected but non-arrayref value found,\ncroaking" );
    }

    my number $possible_number;
    for my integer $i ( 0 .. ( ( scalar @{$possible_arrayref_number} ) - 1 ) )
    {
        $possible_number = $possible_arrayref_number->[$i];
        if ( not( defined $possible_number ) ) {
            croak( "\nERROR EAVRVNV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nnumber value expected but undefined/null value found at index $i,\ncroaking" );
        }
        if (not(   main::PerlTypes_SvNOKp($possible_number)
                || main::PerlTypes_SvIOKp($possible_number) )
            )
        {
            croak( "\nERROR EAVRVNV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nnumber value expected but non-number value found at index $i,\ncroaking" );
        }
    }
    return;
}

sub arrayref_number_CHECKTRACE {
    { my void $RETURN_TYPE };
    ( my $possible_arrayref_number, my $variable_name, my $subroutine_name ) = @ARG;
    if ( not( defined $possible_arrayref_number ) ) {
        croak( "\nERROR EAVRVNV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\narrayref_number value expected but undefined/null value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
    }
    if ( not( main::PerlTypes_SvAROKp($possible_arrayref_number) ) ) {
        croak( "\nERROR EAVRVNV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\narrayref_number value expected but non-arrayref value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
    }

    my number $possible_number;
    for my integer $i ( 0 .. ( ( scalar @{$possible_arrayref_number} ) - 1 ) )
    {
        $possible_number = $possible_arrayref_number->[$i];
        if ( not( defined $possible_number ) ) {
            croak( "\nERROR EAVRVNV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nnumber value expected but undefined/null value found at index $i,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        }
        if (not(   main::PerlTypes_SvNOKp($possible_number)
                || main::PerlTypes_SvIOKp($possible_number) ) ) {
            croak( "\nERROR EAVRVNV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nnumber value expected but non-number value found at index $i,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        }
    }
    return;
}

# [[[ STRINGIFY ]]]

# DEV NOTE: 1-D format levels are 1 less than 2-D format levels

# call actual stringify routine, format level -2 (compact), indent level 0
sub arrayref_number_to_string_compact {
    { my string $RETURN_TYPE };
    ( my $input_avref ) = @ARG;
    return arrayref_number_to_string_format($input_avref, -2, 0);
}

# call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
sub arrayref_number_to_string {
    { my string $RETURN_TYPE };
    ( my $input_avref ) = @ARG;
    return arrayref_number_to_string_format($input_avref, -1, 0);
}

# call actual stringify routine, format level 0 (pretty), indent level 0
sub arrayref_number_to_string_pretty {
    { my string $RETURN_TYPE };
    ( my $input_avref ) = @ARG;
    return arrayref_number_to_string_format($input_avref, 0, 0);
}

# call actual stringify routine, format level 1 (expand), indent level 0
sub arrayref_number_to_string_expand {
    { my string $RETURN_TYPE };
    ( my $input_avref ) = @ARG;
    return arrayref_number_to_string_format($input_avref, 1, 0);
}

# convert from (Perl SV containing RV to (Perl AV of (Perl SVs containing NVs))) to Perl-parsable (Perl SV containing PV)
# stringify an arrayref::number
sub arrayref_number_to_string_format {
    { my string $RETURN_TYPE };
    ( my arrayref::number $input_avref, my integer $format_level, my integer $indent_level ) = @ARG;

#    Perl::diag("in PERLOPS_PERLTYPES arrayref_number_to_string_format(), top of subroutine\n");
#    Perl::diag('in PERLOPS_PERLTYPES arrayref_number_to_string_format(), received $format_level = ', $format_level, "\n");
#    Perl::diag('in PERLOPS_PERLTYPES arrayref_number_to_string_format(), received $indent_level = ', $indent_level, "\n");

#    arrayref_number_CHECK($input_avref);
    arrayref_number_CHECKTRACE( $input_avref, '$input_avref', 'arrayref_number_to_string_format()' );

    # declare local variables, av & sv mean "array value" & "scalar value" as used in Perl core
#    my @input_av;  # DEV NOTE: match CPPOPS_*TYPES code
    my integer $input_av__length;
    my integer $input_av__element;
    my string $output_sv = q{};
    my boolean $i_is_0 = 1;

    # generate indent
    my string $indent = q{    } x $indent_level;

    # compute length of (number of elements in) input array
#    @input_av        = @{$input_avref};  # DEV NOTE: match CPPOPS_*TYPES code
#    $input_av__length = scalar @input_av;  # DEV NOTE: match CPPOPS_*TYPES code
    $input_av__length = scalar @{$input_avref};

#   Perl::diag("in PERLOPS_PERLTYPES arrayref_number_to_string_format(), have \$input_av__length = $input_av__length\n");

    # pre-begin with optional indent, depending on format level
    if ($format_level >= 1) { $output_sv .= $indent; }

    # begin output string with left-square-bracket, as required for all RPerl arrays
    $output_sv .= '[';

    # loop through all valid values of $i for use as index to input array
    for my integer $i ( 0 .. ( $input_av__length - 1 ) ) {

        # retrieve input array's element at index $i
#        $input_av__element = $input_av[$i];  # DEV NOTE: match CPPOPS_*TYPES code
        $input_av__element = $input_avref->[$i];

# DEV NOTE: type-checking already done as part of arrayref_number_CHECKTRACE()
#        number_CHECK($input_av__element);
#number_CHECKTRACE( $input_av__element, "\$input_av__element at index $i", 'arrayref_number_to_string_format()' );

        # append comma to output string for all elements except index 0
        if ($i_is_0) { $i_is_0 = 0; }
        else         { $output_sv .= ','; }

        # append newline-indent-tab or space, depending on format level
        if    ($format_level >=  1) { $output_sv .= "\n" . $indent . q{    }; }
        elsif ($format_level >= -1) { $output_sv .= q{ }; }

        # stringify individual element, append to output string
#        $output_sv .= $input_av__element;  # NO UNDERSCORES
        $output_sv .= Perl::Type::Number::number_to_string($input_av__element);  # YES UNDERSCORES
    }

    # append newline-indent or space, depending on format level
    if    ($format_level >=  1) { $output_sv .= "\n" . $indent; }
    elsif ($format_level >= -1) { $output_sv .= q{ }; }

    # end output string with right-square-bracket, as required for all RPerl arrays
    $output_sv .= ']';

#    Perl::diag("in PERLOPS_PERLTYPES arrayref_number_to_string_format(), after for() loop, have \$output_sv =\n$output_sv\n");
#    Perl::diag("in PERLOPS_PERLTYPES arrayref_number_to_string_format(), bottom of subroutine\n");

    # return output string, containing stringified input array
    return $output_sv;
}

# [[[ TYPE TESTING ]]]

sub arrayref_number_typetest0 {
    { my string $RETURN_TYPE };
    ( my arrayref::number $lucky_numbers) = @ARG;

    #    arrayref_number_CHECK($lucky_numbers);
    arrayref_number_CHECKTRACE( $lucky_numbers, '$lucky_numbers', 'arrayref_number_typetest0()' );

#    my integer $how_lucky = scalar @{$lucky_numbers};
#    for my integer $i ( 0 .. ( $how_lucky - 1 ) ) {
#        my $lucky_number = $lucky_numbers->[$i];
#        Perl::diag("in PERLOPS_PERLTYPES arrayref_number_typetest0(), have lucky number $i/" . ( $how_lucky - 1 ) . ' = ' . $lucky_numbers->[$i] . ", BARBAZ\n");
#    }
#    Perl::diag("in PERLOPS_PERLTYPES arrayref_number_typetest0(), bottom of subroutine\n");
    return ( arrayref_number_to_string($lucky_numbers) . 'PERLOPS_PERLTYPES' );
}

sub arrayref_number_typetest1 {
    { my arrayref::number $RETURN_TYPE };
    ( my integer $my_size) = @ARG;

    #    integer_CHECK($my_size);
    integer_CHECKTRACE( $my_size, '$my_size', 'arrayref_number_typetest1()' );
    my arrayref::number $new_array = [];
    for my integer $i ( 0 .. ( $my_size - 1 ) ) {
        $new_array->[$i] = $i * 5.123456789;

#        Perl::diag("in PERLOPS_PERLTYPES arrayref_number_typetest1(), setting element $i/" . ( $my_size - 1 ) . ' = ' . $new_array->[$i] . ", BARBAZ\n");
    }
    return ($new_array);
}

# [[[ ARRAY REF CHARACTER ]]]
# [[[ ARRAY REF CHARACTER ]]]
# [[[ ARRAY REF CHARACTER ]]]

# (ref to array) of chars
package arrayref::character;
use strict;
use warnings;
use parent -norequire, qw(arrayref);

# [[[ ARRAY REF STRING ]]]
# [[[ ARRAY REF STRING ]]]
# [[[ ARRAY REF STRING ]]]

# (ref to array) of strings
package arrayref::string;
use strict;
use warnings;
use parent -norequire, qw(arrayref);
use Carp;

# [[[ SWITCH CONTEXT BACK TO PRIMARY PACKAGE FOR EXPORT TO WORK ]]]
package Perl::Structure::Array::SubTypes1D;
use strict;
use warnings;

# [[[ TYPE-CHECKING ]]]

sub arrayref_string_CHECK {
    { my void $RETURN_TYPE };
    ( my $possible_arrayref_string ) = @ARG;
    if ( not( defined $possible_arrayref_string ) ) {
        croak( "\nERROR EAVRVPV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\narrayref_string value expected but undefined/null value found,\ncroaking" );
    }

    if ( not( main::PerlTypes_SvAROKp($possible_arrayref_string) ) ) {
        croak( "\nERROR EAVRVPV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\narrayref_string value expected but non-arrayref value found,\ncroaking" );
    }

    my string $possible_string;
    for my integer $i ( 0 .. ( ( scalar @{$possible_arrayref_string} ) - 1 ) )
    {
        $possible_string = $possible_arrayref_string->[$i];
        if ( not( defined $possible_string ) ) {
            croak( "\nERROR EAVRVPV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nstring value expected but undefined/null value found at index $i,\ncroaking" );
        }
        if ( not( main::PerlTypes_SvPOKp($possible_string) ) ) {
            croak( "\nERROR EAVRVPV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nstring value expected but non-string value found at index $i,\ncroaking" );
        }
    }
    return;
}

sub arrayref_string_CHECKTRACE {
    { my void $RETURN_TYPE };
    ( my $possible_arrayref_string, my $variable_name, my $subroutine_name ) = @ARG;
    if ( not( defined $possible_arrayref_string ) ) {
        croak( "\nERROR EAVRVPV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\narrayref_string value expected but undefined/null value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
    }
    if ( not( main::PerlTypes_SvAROKp($possible_arrayref_string) ) ) {
        croak( "\nERROR EAVRVPV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\narrayref_string value expected but non-arrayref value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
    }

    my string $possible_string;
    for my integer $i ( 0 .. ( ( scalar @{$possible_arrayref_string} ) - 1 ) )
    {
        $possible_string = $possible_arrayref_string->[$i];
        if ( not( defined $possible_string ) ) {
            croak( "\nERROR EAVRVPV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nstring value expected but undefined/null value found at index $i,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        }
        if ( not( main::PerlTypes_SvPOKp($possible_string) ) ) {
            croak( "\nERROR EAVRVPV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nstring value expected but non-string value found at index $i,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        }
    }
    return;
}

# [[[ STRINGIFY ]]]

# DEV NOTE: 1-D format levels are 1 less than 2-D format levels

# call actual stringify routine, format level -2 (compact), indent level 0
sub arrayref_string_to_string_compact {
    { my string $RETURN_TYPE };
    ( my $input_avref ) = @ARG;
    return arrayref_string_to_string_format($input_avref, -2, 0);
}

# call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
sub arrayref_string_to_string {
    { my string $RETURN_TYPE };
    ( my $input_avref ) = @ARG;
    return arrayref_string_to_string_format($input_avref, -1, 0);
}

# call actual stringify routine, format level 0 (pretty), indent level 0
sub arrayref_string_to_string_pretty {
    { my string $RETURN_TYPE };
    ( my $input_avref ) = @ARG;
    return arrayref_string_to_string_format($input_avref, 0, 0);
}

# call actual stringify routine, format level 1 (expand), indent level 0
sub arrayref_string_to_string_expand {
    { my string $RETURN_TYPE };
    ( my $input_avref ) = @ARG;
    return arrayref_string_to_string_format($input_avref, 1, 0);
}

# convert from (Perl SV containing RV to (Perl AV of (Perl SVs containing PVs))) to Perl-parsable (Perl SV containing PV)
# stringify an arrayref::string
sub arrayref_string_to_string_format {
    { my string $RETURN_TYPE };
    ( my arrayref::string $input_avref, my integer $format_level, my integer $indent_level ) = @ARG;

#    Perl::diag("in PERLOPS_PERLTYPES arrayref_string_to_string_format(), top of subroutine\n");
#    Perl::diag('in PERLOPS_PERLTYPES arrayref_string_to_string_format(), received $format_level = ', $format_level, "\n");
#    Perl::diag('in PERLOPS_PERLTYPES arrayref_string_to_string_format(), received $indent_level = ', $indent_level, "\n");

#    arrayref_string_CHECK($input_avref);
    arrayref_string_CHECKTRACE( $input_avref, '$input_avref', 'arrayref_string_to_string_format()' );

    # declare local variables, av & sv mean "array value" & "scalar value" as used in Perl core
#    my @input_av;  # DEV NOTE: match CPPOPS_*TYPES code
    my integer $input_av__length;
    my integer $input_av__element;
    my string $output_sv = q{};
    my boolean $i_is_0 = 1;

    # generate indent
    my string $indent = q{    } x $indent_level;

    # compute length of (number of elements in) input array
#    @input_av        = @{$input_avref};  # DEV NOTE: match CPPOPS_*TYPES code
#    $input_av__length = scalar @input_av;  # DEV NOTE: match CPPOPS_*TYPES code
    $input_av__length = scalar @{$input_avref};

#   Perl::diag("in PERLOPS_PERLTYPES arrayref_string_to_string_format(), have \$input_av__length = $input_av__length\n");

    # pre-begin with optional indent, depending on format level
    if ($format_level >= 1) { $output_sv .= $indent; }

    # begin output string with left-square-bracket, as required for all RPerl arrays
    $output_sv .= '[';

    # loop through all valid values of $i for use as index to input array
    for my integer $i ( 0 .. ( $input_av__length - 1 ) ) {

        # retrieve input array's element at index $i
#        $input_av__element = $input_av[$i];  # DEV NOTE: match CPPOPS_*TYPES code
        $input_av__element = $input_avref->[$i];

# DEV NOTE: type-checking already done as part of arrayref_string_CHECKTRACE()
#        string_CHECK($input_av__element);
#string_CHECKTRACE( $input_av__element, "\$input_av__element at index $i", 'arrayref_string_to_string_format()' );

        # append comma to output string for all elements except index 0
        if ($i_is_0) { $i_is_0 = 0; }
        else         { $output_sv .= ','; }

        # append newline-indent-tab or space, depending on format level
        if    ($format_level >=  1) { $output_sv .= "\n" . $indent . q{    }; }
        elsif ($format_level >= -1) { $output_sv .= q{ }; }

        # stringify individual element, append to output string
        $input_av__element =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
        $input_av__element =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
        $output_sv .= "'$input_av__element'";
    }

    # append newline-indent or space, depending on format level
    if    ($format_level >=  1) { $output_sv .= "\n" . $indent; }
    elsif ($format_level >= -1) { $output_sv .= q{ }; }

    # end output string with right-square-bracket, as required for all RPerl arrays
    $output_sv .= ']';

#    Perl::diag("in PERLOPS_PERLTYPES arrayref_string_to_string_format(), after for() loop, have \$output_sv =\n$output_sv\n");
#    Perl::diag("in PERLOPS_PERLTYPES arrayref_string_to_string_format(), bottom of subroutine\n");

    # return output string, containing stringified input array
    return $output_sv;
}

# [[[ TYPE TESTING ]]]

sub arrayref_string_typetest0 {
    { my string $RETURN_TYPE };
    ( my arrayref::string $people) = @ARG;

    #    arrayref_string_CHECK($people);
    arrayref_string_CHECKTRACE( $people, '$people', 'arrayref_string_typetest0()' );

#    my integer $how_crowded = scalar @{$people};
#    for my integer $i ( 0 .. ( $how_crowded - 1 ) ) {
#        my $person = $people->[$i];
#        Perl::diag("in PERLOPS_PERLTYPES arrayref_string_typetest0(), have person $i/" . ( $how_crowded - 1 ) . ' = ' . $people->[$i] . ", BARBAR\n");
#    }
#    Perl::diag("in PERLOPS_PERLTYPES arrayref_string_typetest0(), bottom of subroutine\n");
    return ( arrayref_string_to_string($people) . 'PERLOPS_PERLTYPES' );
}

sub arrayref_string_typetest1 {
    { my arrayref::string $RETURN_TYPE };
    ( my integer $my_size) = @ARG;

    #    integer_CHECK($my_size);
    integer_CHECKTRACE( $my_size, '$my_size', 'arrayref_string_typetest1()' );
    my arrayref::string $new_array = [];
    for my integer $i ( 0 .. ( $my_size - 1 ) ) {
        $new_array->[$i] = "Jeffy Ten! $i/" . ( $my_size - 1 ) . ' PERLOPS_PERLTYPES';

#        Perl::diag("in PERLOPS_PERLTYPES arrayref_string_typetest1(), bottom of for() loop, have i = $i, just set another Jeffy, BARBAR\n");
    }
    return ($new_array);
}

=block_comment
THIS IS AN EXAMPLE BLOCK COMMENT
it's purpose is to keep from triggering the UselessNoCritic rule,
so we can keep the no critic sections at the top of the file for reference
=cut

# [[[ ARRAY REF SCALAR ]]]
# [[[ ARRAY REF SCALAR ]]]
# [[[ ARRAY REF SCALAR ]]]

# (ref to array) of scalartypes
package arrayref::scalartype;
use strict;
use warnings;
use parent -norequire, qw(arrayref);

1;  # end of package
