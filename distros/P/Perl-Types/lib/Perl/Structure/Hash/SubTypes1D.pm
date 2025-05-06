## no critic qw(ProhibitUselessNoCritic PodSpelling ProhibitExcessMainComplexity)  # DEVELOPER DEFAULT 1a: allow unreachable & POD-commented code; SYSTEM SPECIAL 4: allow complex code outside subroutines, must be on line 1
package Perl::Structure::Hash::SubTypes1D;
use strict;
use warnings;
use Perl::Types;
our $VERSION = 0.018_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(ProhibitUnreachableCode RequirePodSections RequirePodAtEnd)  # DEVELOPER DEFAULT 1b: allow unreachable & POD-commented code, must be after line 1
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names

# [[[ EXPORTS ]]]
# DEV NOTE, CORRELATION #rp051: hard-coded list of RPerl data types and data structures
use Exporter 'import';
our @EXPORT = qw(
    hashref_integer_CHECK
    hashref_integer_CHECKTRACE
    hashref_number_CHECK
    hashref_number_CHECKTRACE
    hashref_string_CHECK
    hashref_string_CHECKTRACE
    hashref_integer_to_string_compact
    hashref_integer_to_string
    hashref_integer_to_string_pretty
    hashref_integer_to_string_expand
    hashref_integer_to_string_format
    hashref_number_to_string_compact
    hashref_number_to_string
    hashref_number_to_string_pretty
    hashref_number_to_string_expand
    hashref_number_to_string_format
    hashref_string_to_string_compact
    hashref_string_to_string
    hashref_string_to_string_pretty
    hashref_string_to_string_expand
    hashref_string_to_string_format
);
our @EXPORT_OK = qw(
    hashref_integer_typetest0
    hashref_integer_typetest1
    hashref_number_typetest0
    hashref_number_typetest1
    hashref_string_typetest0
    hashref_string_typetest1
);

# [[[ INCLUDES ]]]
use Perl::Type::Integer;  # for integer_CHECKTRACE(), used in hashref_TYPE_typetest1()

# [[[ HASH REF INTEGER ]]]
# [[[ HASH REF INTEGER ]]]
# [[[ HASH REF INTEGER ]]]

# (ref to hash) of integers
package hashref::integer;
use strict;
use warnings;
use parent -norequire, qw(hashref);
use Carp;

# [[[ SWITCH CONTEXT BACK TO PRIMARY PACKAGE FOR EXPORT TO WORK ]]]
package Perl::Structure::Hash::SubTypes1D;
use strict;
use warnings;

# [[[ TYPE-CHECKING ]]]

sub hashref_integer_CHECK {
    { my void $RETURN_TYPE };
    ( my $possible_hashref_integer ) = @ARG;

# DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() subroutine, but with integer-specific error codes
    if ( not( defined $possible_hashref_integer ) ) {
        croak( "\nERROR EHVRVIV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nhashref::integer value expected but undefined/null value found,\ncroaking" );
    }

    if ( not( main::PerlTypes_SvHROKp($possible_hashref_integer) ) ) {
        croak( "\nERROR EHVRVIV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nhashref::integer value expected but non-hashref value found,\ncroaking" );
    }

    my integer $possible_integer;
    foreach my string $key ( sort keys %{$possible_hashref_integer} ) {
        $possible_integer = $possible_hashref_integer->{$key};

# DEV NOTE: the following two if() statements are functionally equivalent to the integer_CHECK() subroutine, but with hash-specific error codes
        if ( not( defined $possible_integer ) ) {
            $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
            $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
            croak( "\nERROR EHVRVIV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\ninteger value expected but undefined/null value found at key '$key',\ncroaking" );
        }
        if ( not( main::PerlTypes_SvIOKp($possible_integer) ) ) {
            $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
            $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
            croak( "\nERROR EHVRVIV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\ninteger value expected but non-integer value found at key '$key',\ncroaking" );
        }
    }
    return;
}

sub hashref_integer_CHECKTRACE {
    { my void $RETURN_TYPE };
    ( my $possible_hashref_integer, my $variable_name, my $subroutine_name )
        = @ARG;

# DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECKTRACE() subroutine, but with integer-specific error codes
    if ( not( defined $possible_hashref_integer ) ) {
        croak( "\nERROR EHVRVIV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nhashref::integer value expected but undefined/null value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
    }

    if ( not( main::PerlTypes_SvHROKp($possible_hashref_integer) ) ) {
        croak(
            "\nERROR EHVRVIV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nhashref::integer value expected but non-hashref value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" ); }

    my integer $possible_integer;
    foreach my string $key ( sort keys %{$possible_hashref_integer} ) {
        $possible_integer = $possible_hashref_integer->{$key};

# DEV NOTE: the following two if() statements are functionally equivalent to the integer_CHECKTRACE() subroutine, but with hash-specific error codes
        if ( not( defined $possible_integer ) ) {
            $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
            $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
            croak( "\nERROR EHVRVIV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\ninteger value expected but undefined/null value found at key '$key',\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        }
        if ( not( main::PerlTypes_SvIOKp($possible_integer) ) ) {
            $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
            $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
            croak( "\nERROR EHVRVIV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\ninteger value expected but non-integer value found at key '$key',\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        }
    }
    return;
}

# [[[ STRINGIFY ]]]

# DEV NOTE: 1-D format levels are 1 less than 2-D format levels

# call actual stringify routine, format level -2 (compact), indent level 0
sub hashref_integer_to_string_compact {
    { my string $RETURN_TYPE };
    ( my $input_hvref ) = @ARG;
    return hashref_integer_to_string_format($input_hvref, -2, 0);
}

# call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
sub hashref_integer_to_string {
    { my string $RETURN_TYPE };
    ( my $input_hvref ) = @ARG;
    return hashref_integer_to_string_format($input_hvref, -1, 0);
}

# call actual stringify routine, format level 0 (pretty), indent level 0
sub hashref_integer_to_string_pretty {
    { my string $RETURN_TYPE };
    ( my $input_hvref ) = @ARG;
    return hashref_integer_to_string_format($input_hvref, 0, 0);
}

# call actual stringify routine, format level 1 (expand), indent level 0
sub hashref_integer_to_string_expand {
    { my string $RETURN_TYPE };
    ( my $input_hvref ) = @ARG;
    return hashref_integer_to_string_format($input_hvref, 1, 0);
}

# convert from (Perl SV containing RV to (Perl HV of (Perl SVs containing IVs))) to Perl-parsable (Perl SV containing PV)
sub hashref_integer_to_string_format {
    { my string $RETURN_TYPE };
    ( my $input_hvref, my integer $format_level, my integer $indent_level ) = @ARG;

#    Perl::diag("in PERLOPS_PERLTYPES hashref_integer_to_string_format(), top of subroutine\n");

#    hashref_integer_CHECK($input_hvref);
    hashref_integer_CHECKTRACE( $input_hvref, '$input_hvref', 'hashref_integer_to_string()' );

    # declare local variables, av & sv mean "array value" & "scalar value" as used in Perl core
    my %input_hv;
    #	my integer $input_hv__length;
    my integer $input_hv__entry_value;
    my string $output_sv = q{};
    my boolean $i_is_0 = 1;

    # dereference input hash reference
    %input_hv = %{$input_hvref};

    # generate indent
    my string $indent = q{    } x $indent_level;

    # compute length of (number of keys in) input hash
#    $input_hv__length = scalar keys %input_hv;
#    Perl::diag("in PERLOPS_PERLTYPES hashref_integer_to_string_format(), have \$input_hv__length = $input_hv__length\n");

    # pre-begin with optional indent, depending on format level
    if ($format_level >= 1) { $output_sv .= $indent; }

    # begin output string with left-curly-brace, as required for all RPerl hashes
    $output_sv .= '{';

    # loop through all hash keys
    foreach my string $key ( sort keys %input_hv ) {
        # retrieve input hash's entry value at key
        $input_hv__entry_value = $input_hv{$key};

# DEV NOTE: integer type-checking already done as part of hashref_integer_CHECKTRACE()
#        integer_CHECK($input_hv__entry_value);
#        integer_CHECKTRACE( $input_hv__entry_value, "\$input_hv__entry_value at key '$key'", 'hashref_integer_to_string()' );

        # append comma to output string for all elements except index 0
        if ($i_is_0) { $i_is_0 = 0; }
        else         { $output_sv .= ','; }

        # append newline-indent-tab or space, depending on format level
        if    ($format_level >=  1) { $output_sv .= "\n" . $indent . q{    }; }
        elsif ($format_level >= -1) { $output_sv .= q{ }; }

        $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
        $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character

        # DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
        $output_sv .= q{'} . $key. q{'};

        # append spaces before and after fat arrow AKA fat comma, depending on format level
        if ($format_level >= -1) { $output_sv .= ' => '; }
        else                     { $output_sv .= '=>'; }

#        $output_sv .= $input_hv__entry_value;  # NO UNDERSCORES
        $output_sv .= ::integer_to_string($input_hv__entry_value);  # YES UNDERSCORES
    }

    # append newline-indent or space, depending on format level
    if    ($format_level >=  1) { $output_sv .= "\n" . $indent; }
    elsif ($format_level >= -1) { $output_sv .= q{ }; }

    # end output string with right-curly-brace, as required for all RPerl hashes
    $output_sv .= '}';

#    Perl::diag("in PERLOPS_PERLTYPES hashref_integer_to_string_format(), after for() loop, have \$output_sv =\n$output_sv\n");
#    Perl::diag("in PERLOPS_PERLTYPES hashref_integer_to_string_format(), bottom of subroutine\n");
    return ($output_sv);
}

# [[[ TYPE TESTING ]]]

sub hashref_integer_typetest0 {
    { my string $RETURN_TYPE };
    ( my hashref::integer $lucky_integers) = @ARG;

    #    hashref_integer_CHECK($lucky_integers);
    hashref_integer_CHECKTRACE( $lucky_integers, '$lucky_integers',
        'hashref_integer_typetest0()' );

#    foreach my string $key ( sort keys %{$lucky_integers} ) {
#        my $lucky_integer = $lucky_integers->{$key};
#        $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
#        $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
#
#        Perl::diag("in PERLOPS_PERLTYPES hashref_integer_typetest0(), have lucky integer '$key' => " . $lucky_integer . ", BARSTOOL\n");
#    }
#    Perl::diag("in PERLOPS_PERLTYPES hashref_integer_typetest0(), bottom of subroutine\n");
    return (
        hashref_integer_to_string($lucky_integers) . 'PERLOPS_PERLTYPES' );
}

sub hashref_integer_typetest1 {
    { my hashref::integer $RETURN_TYPE };
    ( my integer $my_size) = @ARG;

    #    integer_CHECK($my_size);
    integer_CHECKTRACE( $my_size, '$my_size',
        'hashref_integer_typetest1()' );
    my hashref::integer $new_hash = {};
    my string $temp_key;
    for my integer $i ( 0 .. ( $my_size - 1 ) ) {
        $temp_key = 'PERLOPS_PERLTYPES_funkey' . $i;
        $new_hash->{$temp_key} = $i * 5;

#        Perl::diag("in PERLOPS_PERLTYPES hashref_integer_typetest1(), setting entry '$temp_key' => " . $new_hash->{$temp_key} . ", BARSTOOL\n");
    }
    return ($new_hash);
}

# [[[ HASH REF NUMBER ]]]
# [[[ HASH REF NUMBER ]]]
# [[[ HASH REF NUMBER ]]]

# (ref to hash) of numbers
package hashref::number;
use strict;
use warnings;
use parent -norequire, qw(hashref);
use Carp;

# [[[ SWITCH CONTEXT BACK TO PRIMARY PACKAGE FOR EXPORT TO WORK ]]]
package Perl::Structure::Hash::SubTypes1D;
use strict;
use warnings;

# [[[ TYPE-CHECKING ]]]

sub hashref_number_CHECK {
    { my void $RETURN_TYPE };
    ( my $possible_hashref_number ) = @ARG;

# DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() subroutine, but with number-specific error codes
    if ( not( defined $possible_hashref_number ) ) {
        croak( "\nERROR EHVRVNV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nhashref::number value expected but undefined/null value found,\ncroaking" );
    }

    if ( not( main::PerlTypes_SvHROKp($possible_hashref_number) ) ) {
        croak( "\nERROR EHVRVNV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nhashref::number value expected but non-hashref value found,\ncroaking" );
    }

    my number $possible_number;
    foreach my string $key ( sort keys %{$possible_hashref_number} ) {
        $possible_number = $possible_hashref_number->{$key};

# DEV NOTE: the following two if() statements are functionally equivalent to the number_CHECK() subroutine, but with hash-specific error codes
        if ( not( defined $possible_number ) ) {
            $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
            $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
            croak( "\nERROR EHVRVNV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nnumber value expected but undefined/null value found at key '$key',\ncroaking" );
        }
        if (not(   main::PerlTypes_SvNOKp($possible_number)
                || main::PerlTypes_SvIOKp($possible_number) )
            )
        {
            $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
            $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
            croak( "\nERROR EHVRVNV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nnumber value expected but non-number value found at key '$key',\ncroaking" );
        }
    }
    return;
}

sub hashref_number_CHECKTRACE {
    { my void $RETURN_TYPE };
    ( my $possible_hashref_number, my $variable_name, my $subroutine_name )
        = @ARG;

# DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECKTRACE() subroutine, but with number-specific error codes
    if ( not( defined $possible_hashref_number ) ) {
        croak( "\nERROR EHVRVNV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nhashref::number value expected but undefined/null value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
    }

    if ( not( main::PerlTypes_SvHROKp($possible_hashref_number) ) ) {
        croak( "\nERROR EHVRVNV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nhashref::number value expected but non-hashref value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
    }

    my number $possible_number;
    foreach my string $key ( sort keys %{$possible_hashref_number} ) {
        $possible_number = $possible_hashref_number->{$key};

# DEV NOTE: the following two if() statements are functionally equivalent to the number_CHECKTRACE() subroutine, but with hash-specific error codes
        if ( not( defined $possible_number ) ) {
            $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
            $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
            croak( "\nERROR EHVRVNV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nnumber value expected but undefined/null value found at key '$key',\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        }
        if (not(   main::PerlTypes_SvNOKp($possible_number)
                || main::PerlTypes_SvIOKp($possible_number) )
            )
        {
            $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
            $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
            croak( "\nERROR EHVRVNV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nnumber value expected but non-number value found at key '$key',\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        }
    }
    return;
}

# [[[ STRINGIFY ]]]

# DEV NOTE: 1-D format levels are 1 less than 2-D format levels

# call actual stringify routine, format level -2 (compact), indent level 0
sub hashref_number_to_string_compact {
    { my string $RETURN_TYPE };
    ( my $input_hvref ) = @ARG;
    return hashref_number_to_string_format($input_hvref, -2, 0);
}

# call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
sub hashref_number_to_string {
    { my string $RETURN_TYPE };
    ( my $input_hvref ) = @ARG;
    return hashref_number_to_string_format($input_hvref, -1, 0);
}

# call actual stringify routine, format level 0 (pretty), indent level 0
sub hashref_number_to_string_pretty {
    { my string $RETURN_TYPE };
    ( my $input_hvref ) = @ARG;
    return hashref_number_to_string_format($input_hvref, 0, 0);
}

# call actual stringify routine, format level 1 (expand), indent level 0
sub hashref_number_to_string_expand {
    { my string $RETURN_TYPE };
    ( my $input_hvref ) = @ARG;
    return hashref_number_to_string_format($input_hvref, 1, 0);
}

# convert from (Perl SV containing RV to (Perl HV of (Perl SVs containing NVs))) to Perl-parsable (Perl SV containing PV)
sub hashref_number_to_string_format {
    { my string $RETURN_TYPE };
    ( my $input_hvref, my integer $format_level, my integer $indent_level ) = @ARG;

#    Perl::diag("in PERLOPS_PERLTYPES hashref_number_to_string_format(), top of subroutine\n");

#    hashref_number_CHECK($input_hvref);
    hashref_number_CHECKTRACE( $input_hvref, '$input_hvref', 'hashref_number_to_string()' );

    # declare local variables, av & sv mean "array value" & "scalar value" as used in Perl core
    my %input_hv;
#    my integer $input_hv__length;
    my number $input_hv__entry_value;
    my string $output_sv = q{};
    my boolean $i_is_0 = 1;

    # dereference input hash reference
    %input_hv = %{$input_hvref};

    # generate indent
    my string $indent = q{    } x $indent_level;

    # compute length of (number of keys in) input hash
#    $input_hv__length = scalar keys %input_hv;
#    Perl::diag("in PERLOPS_PERLTYPES hashref_number_to_string_format(), have \$input_hv__length = $input_hv__length\n");

    # pre-begin with optional indent, depending on format level
    if ($format_level >= 1) { $output_sv .= $indent; }

    # begin output string with left-curly-brace, as required for all RPerl hashes
    $output_sv .= '{';

    # loop through all hash keys
    foreach my string $key ( sort keys %input_hv ) {
        # retrieve input hash's entry value at key
        $input_hv__entry_value = $input_hv{$key};

# DEV NOTE: number type-checking already done as part of hashref_number_CHECKTRACE()
#        number_CHECK($input_hv__entry_value);
#        number_CHECKTRACE( $input_hv__entry_value, "\$input_hv__entry_value at key '$key'", 'hashref_number_to_string()' );

        # append comma to output string for all elements except index 0
        if ($i_is_0) { $i_is_0 = 0; }
        else         { $output_sv .= ','; }

        # append newline-indent-tab or space, depending on format level
        if    ($format_level >=  1) { $output_sv .= "\n" . $indent . q{    }; }
        elsif ($format_level >= -1) { $output_sv .= q{ }; }

        $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
        $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character

        # DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
        $output_sv .= q{'} . $key. q{'};

        # append spaces before and after fat arrow AKA fat comma, depending on format level
        if ($format_level >= -1) { $output_sv .= ' => '; }
        else                     { $output_sv .= '=>'; }

#        $output_sv .= $input_hv__entry_value;  # NO UNDERSCORES
        $output_sv .= Perl::Type::Number::number_to_string($input_hv__entry_value);  # YES UNDERSCORES
    }

    # append newline-indent or space, depending on format level
    if    ($format_level >=  1) { $output_sv .= "\n" . $indent; }
    elsif ($format_level >= -1) { $output_sv .= q{ }; }

    # end output string with right-curly-brace, as required for all RPerl hashes
    $output_sv .= '}';

#    Perl::diag("in PERLOPS_PERLTYPES hashref_number_to_string_format(), after for() loop, have \$output_sv =\n$output_sv\n");
#    Perl::diag("in PERLOPS_PERLTYPES hashref_number_to_string_format(), bottom of subroutine\n");
    return ($output_sv);
}

# [[[ TYPE TESTING ]]]

sub hashref_number_typetest0 {
    { my string $RETURN_TYPE };
    ( my hashref::number $lucky_numbers) = @ARG;

    #    hashref_number_CHECK($lucky_numbers);
    hashref_number_CHECKTRACE( $lucky_numbers, '$lucky_numbers',
        'hashref_number_typetest0()' );

#    foreach my string $key ( sort keys %{$lucky_numbers} ) {
#        my $lucky_number = $lucky_numbers->{$key};
#        $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
#        $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
#        Perl::diag("in PERLOPS_PERLTYPES hashref_number_typetest0(), have lucky number '$key' => " . $lucky_number . ", BARSTOOL\n");
#    }
    return (
        hashref_number_to_string($lucky_numbers) . 'PERLOPS_PERLTYPES' );
}

sub hashref_number_typetest1 {
    { my hashref::number $RETURN_TYPE };
    ( my integer $my_size) = @ARG;

    #    integer_CHECK($my_size);
    integer_CHECKTRACE( $my_size, '$my_size',
        'hashref_number_typetest1()' );
    my hashref::number $new_hash = {};
    my string $temp_key;
    for my integer $i ( 0 .. ( $my_size - 1 ) ) {
        $temp_key = 'PERLOPS_PERLTYPES_funkey' . $i;
        $new_hash->{$temp_key} = $i * 5.123456789;

#        Perl::diag("in PERLOPS_PERLTYPES hashref_number_typetest1(), setting entry '$temp_key' => " . $new_hash->{$temp_key} . ", BARSTOOL\n");
    }
    return ($new_hash);
}

# [[[ HASH REF CHARACTER ]]]
# [[[ HASH REF CHARACTER ]]]
# [[[ HASH REF CHARACTER ]]]

# (ref to hash) of chars
package hashref::character;
use strict;
use warnings;
use parent -norequire, qw(hashref);

# [[[ HASH REF STRING ]]]
# [[[ HASH REF STRING ]]]
# [[[ HASH REF STRING ]]]

# (ref to hash) of strings
package hashref::string;
use strict;
use warnings;
use parent -norequire, qw(hashref);
use Carp;

# [[[ SWITCH CONTEXT BACK TO PRIMARY PACKAGE FOR EXPORT TO WORK ]]]
package Perl::Structure::Hash::SubTypes1D;
use strict;
use warnings;

# [[[ TYPE-CHECKING ]]]

sub hashref_string_CHECK {
    { my void $RETURN_TYPE };
    ( my $possible_hashref_string ) = @ARG;

# DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() subroutine, but with string-specific error codes
    if ( not( defined $possible_hashref_string ) ) {
        croak( "\nERROR EHVRVPV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nhashref::string value expected but undefined/null value found,\ncroaking" );
    }

    if ( not( main::PerlTypes_SvHROKp($possible_hashref_string) ) ) {
        croak( "\nERROR EHVRVPV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nhashref::string value expected but non-hashref value found,\ncroaking" );
    }

    my string $possible_string;
    foreach my string $key ( sort keys %{$possible_hashref_string} ) {
        $possible_string = $possible_hashref_string->{$key};

# DEV NOTE: the following two if() statements are functionally equivalent to the string_CHECK() subroutine, but with hash-specific error codes
        if ( not( defined $possible_string ) ) {
            $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
            $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
            croak( "\nERROR EHVRVPV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nstring value expected but undefined/null value found at key '$key',\ncroaking" );
        }
        if ( not( main::PerlTypes_SvPOKp($possible_string) ) ) {
            $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
            $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
            croak( "\nERROR EHVRVPV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nstring value expected but non-string value found at key '$key',\ncroaking" );
        }
    }
    return;
}

sub hashref_string_CHECKTRACE {
    { my void $RETURN_TYPE };
    ( my $possible_hashref_string, my $variable_name, my $subroutine_name )
        = @ARG;

# DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECKTRACE() subroutine, but with string-specific error codes
    if ( not( defined $possible_hashref_string ) ) {
        croak( "\nERROR EHVRVPV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nhashref::string value expected but undefined/null value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
    }

    if ( not( main::PerlTypes_SvHROKp($possible_hashref_string) ) ) {
        croak( "\nERROR EHVRVPV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nhashref::string value expected but non-hashref value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
    }

    my string $possible_string;
    foreach my string $key ( sort keys %{$possible_hashref_string} ) {
        $possible_string = $possible_hashref_string->{$key};

# DEV NOTE: the following two if() statements are functionally equivalent to the string_CHECKTRACE() subroutine, but with hash-specific error codes
        if ( not( defined $possible_string ) ) {
            $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
            $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
            croak( "\nERROR EHVRVPV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nstring value expected but undefined/null value found at key '$key',\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        }
        if ( not( main::PerlTypes_SvPOKp($possible_string) ) ) {
            $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
            $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
            croak( "\nERROR EHVRVPV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nstring value expected but non-string value found at key '$key',\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        }
    }
    return;
}

# [[[ STRINGIFY ]]]

# DEV NOTE: 1-D format levels are 1 less than 2-D format levels

# call actual stringify routine, format level -2 (compact), indent level 0
sub hashref_string_to_string_compact {
    { my string $RETURN_TYPE };
    ( my $input_hvref ) = @ARG;
    return hashref_string_to_string_format($input_hvref, -2, 0);
}

# call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
sub hashref_string_to_string {
    { my string $RETURN_TYPE };
    ( my $input_hvref ) = @ARG;
    return hashref_string_to_string_format($input_hvref, -1, 0);
}

# call actual stringify routine, format level 0 (pretty), indent level 0
sub hashref_string_to_string_pretty {
    { my string $RETURN_TYPE };
    ( my $input_hvref ) = @ARG;
    return hashref_string_to_string_format($input_hvref, 0, 0);
}

# call actual stringify routine, format level 1 (expand), indent level 0
sub hashref_string_to_string_expand {
    { my string $RETURN_TYPE };
    ( my $input_hvref ) = @ARG;
    return hashref_string_to_string_format($input_hvref, 1, 0);
}

# convert from (Perl SV containing RV to (Perl HV of (Perl SVs containing PVs))) to Perl-parsable (Perl SV containing PV)
sub hashref_string_to_string_format {
    { my string $RETURN_TYPE };
    ( my $input_hvref, my integer $format_level, my integer $indent_level ) = @ARG;

#    Perl::diag("in PERLOPS_PERLTYPES hashref_string_to_string_format(), top of subroutine\n");

#    hashref_string_CHECK($input_hvref);
    hashref_string_CHECKTRACE( $input_hvref, '$input_hvref', 'hashref_string_to_string()' );

    # declare local variables, av & sv mean "array value" & "scalar value" as used in Perl core
    my %input_hv;
#    my integer $input_hv__length;
    my string $input_hv__entry_value;
    my string $output_sv = q{};
    my boolean $i_is_0 = 1;

    # dereference input hash reference
    %input_hv = %{$input_hvref};

    # generate indent
    my string $indent = q{    } x $indent_level;

    # compute length of (number of keys in) input hash
#    $input_hv__length = scalar keys %input_hv;
#    Perl::diag("in PERLOPS_PERLTYPES hashref_string_to_string_format(), have \$input_hv__length = $input_hv__length\n");

    # pre-begin with optional indent, depending on format level
    if ($format_level >= 1) { $output_sv .= $indent; }

    # begin output string with left-curly-brace, as required for all RPerl hashes
    $output_sv .= '{';

    # loop through all hash keys
    foreach my string $key ( sort keys %input_hv ) {
        # retrieve input hash's entry value at key
        $input_hv__entry_value = $input_hv{$key};

# DEV NOTE: string type-checking already done as part of hashref_string_CHECKTRACE()
#        string_CHECK($input_hv__entry_value);
#        string_CHECKTRACE( $input_hv__entry_value, "\$input_hv__entry_value at key '$key'", 'hashref_string_to_string()' );

        # append comma to output string for all elements except index 0
        if ($i_is_0) { $i_is_0 = 0; }
        else         { $output_sv .= ','; }

        # append newline-indent-tab or space, depending on format level
        if    ($format_level >=  1) { $output_sv .= "\n" . $indent . q{    }; }
        elsif ($format_level >= -1) { $output_sv .= q{ }; }

        $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
        $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character

        # DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
        $output_sv .= q{'} . $key. q{'};

        # append spaces before and after fat arrow AKA fat comma, depending on format level
        if ($format_level >= -1) { $output_sv .= ' => '; }
        else                     { $output_sv .= '=>'; }

        $input_hv__entry_value =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
        $input_hv__entry_value =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
        $output_sv .= q{'} . $input_hv__entry_value . q{'};
    }

    # append newline-indent or space, depending on format level
    if    ($format_level >=  1) { $output_sv .= "\n" . $indent; }
    elsif ($format_level >= -1) { $output_sv .= q{ }; }

    # end output string with right-curly-brace, as required for all RPerl hashes
    $output_sv .= '}';

#    Perl::diag("in PERLOPS_PERLTYPES hashref_string_to_string_format(), after for() loop, have \$output_sv =\n$output_sv\n");
#    Perl::diag("in PERLOPS_PERLTYPES hashref_string_to_string_format(), bottom of subroutine\n");
    return ($output_sv);
}

# [[[ TYPE TESTING ]]]

sub hashref_string_typetest0 {
    { my string $RETURN_TYPE };
    ( my hashref::string $people) = @ARG;

    #    hashref_string_CHECK($lucky_numbers);
    hashref_string_CHECKTRACE( $people, '$people',
        'hashref_string_typetest0()' );

#    foreach my string $key ( sort keys %{$people} ) {
#        my $person = $people->{$key};
#        $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
#        $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
#        Perl::diag("in PERLOPS_PERLTYPES hashref_string_typetest0(), have person '$key' => '" . $person . "', STARBOOL\n");
#    }
    return ( hashref_string_to_string($people) . 'PERLOPS_PERLTYPES' );
}

sub hashref_string_typetest1 {
    { my hashref::string $RETURN_TYPE };
    ( my integer $my_size) = @ARG;

    #    integer_CHECK($my_size);
    integer_CHECKTRACE( $my_size, '$my_size',
        'hashref_string_typetest1()' );
    my hashref::string $people = {};
    for my integer $i ( 0 .. ( $my_size - 1 ) ) {
        $people->{ 'PERLOPS_PERLTYPES_Luker_key' . $i }
            = q{Jeffy Ten! } . $i . q{/} . ( $my_size - 1 );

#        Perl::diag("in PERLOPS_PERLTYPES hashref_string_typetest1(), bottom of for() loop, have i = $i, just set another Jeffy!\n");
    }
    return ($people);
}

# [[[ HASH REF SCALAR ]]]
# [[[ HASH REF SCALAR ]]]
# [[[ HASH REF SCALAR ]]]

# (ref to hash) of scalartypes
package hashref::scalartype;
use strict;
use warnings;
use parent -norequire, qw(hashref);

1;  # end of package
