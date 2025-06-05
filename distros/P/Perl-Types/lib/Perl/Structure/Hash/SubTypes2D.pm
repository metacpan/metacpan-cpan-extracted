## no critic qw(ProhibitUselessNoCritic PodSpelling ProhibitExcessMainComplexity)  # DEVELOPER DEFAULT 1a: allow unreachable & POD-commented code; SYSTEM SPECIAL 4: allow complex code outside subroutines, must be on line 1
package Perl::Structure::Hash::SubTypes2D;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.025_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(ProhibitUnreachableCode RequirePodSections RequirePodAtEnd)  # DEVELOPER DEFAULT 1b: allow unreachable & POD-commented code, must be after line 1
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names

# [[[ INCLUDES ]]]
# for TYPE_CHECK() used in hashref_arrayref_TYPE_typetestX()
use Perl::Type::Integer;
use Perl::Type::Number;
use Perl::Type::String;
# NEED ANSWER: is it bad to have this hash data type code dependent on the array data types?
use Perl::Structure::Array;  # arrayref::integer, arrayref::number, arrayref::string

# [[[ EXPORTS ]]]
# DEV NOTE, CORRELATION #rp051: hard-coded list of RPerl data types and data structures
use Exporter 'import';
our @EXPORT = qw(
    hashref_arrayref_integer_CHECK
    hashref_arrayref_integer_CHECKTRACE
    hashref_arrayref_integer_to_string_compact
    hashref_arrayref_integer_to_string
    hashref_arrayref_integer_to_string_pretty
    hashref_arrayref_integer_to_string_expand
    hashref_arrayref_integer_to_string_format
    hashref_arrayref_number_CHECK
    hashref_arrayref_number_CHECKTRACE
    hashref_arrayref_number_to_string_compact
    hashref_arrayref_number_to_string
    hashref_arrayref_number_to_string_pretty
    hashref_arrayref_number_to_string_expand
    hashref_arrayref_number_to_string_format
    hashref_arrayref_string_CHECK
    hashref_arrayref_string_CHECKTRACE
    hashref_arrayref_string_to_string_compact
    hashref_arrayref_string_to_string
    hashref_arrayref_string_to_string_pretty
    hashref_arrayref_string_to_string_expand
    hashref_arrayref_string_to_string_format
);
our @EXPORT_OK = qw(
    hashref_arrayref_integer_typetest0
    hashref_arrayref_integer_typetest1
    hashref_arrayref_number_typetest0
    hashref_arrayref_number_typetest1
    hashref_arrayref_string_typetest0
    hashref_arrayref_string_typetest1
);

# [[[ HASH REF ARRAY REF ]]]
# [[[ HASH REF ARRAY REF ]]]
# [[[ HASH REF ARRAY REF ]]]

# (ref to hash) of (refs to arrays)
package hashref::arrayref;
use strict;
use warnings;
use parent -norequire, qw(hashref);

# [[[ HASH REF ARRAY REF INTEGER ]]]
# [[[ HASH REF ARRAY REF INTEGER ]]]
# [[[ HASH REF ARRAY REF INTEGER ]]]

# (ref to hash) of (refs to (arrays of integers))
package hashref::arrayref::integer;
use strict;
use warnings;
use parent -norequire, qw(hashref::arrayref);

# [[[ SWITCH CONTEXT BACK TO PRIMARY PACKAGE FOR EXPORT TO WORK ]]]
package Perl::Structure::Hash::SubTypes2D;
use strict;
use warnings;

# [[[ TYPE-CHECKING ]]]

sub hashref_arrayref_integer_CHECK {
    { my void $RETURN_TYPE };
    ( my $possible_hashref_arrayref_integer ) = @ARG;

#    Perl::diag('in PERLOPS_PERLTYPES hashref_arrayref_integer_CHECK(), top of subroutine', "\n");

    # DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() subroutine, but with integer-specific error codes
    if ( not( defined $possible_hashref_arrayref_integer ) ) {
        croak( "\n" . 'ERROR EHVRVAVRVIV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' . "\n" . 'hashref::arrayref::integer value expected but undefined/null value found,' . "\n" . 'croaking' );
    }

    if ( not( main::PerlTypes_SvHROKp($possible_hashref_arrayref_integer) ) ) {
        croak( "\n" . 'ERROR EHVRVAVRVIV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' . "\n" . 'hashref::arrayref::integer value expected but non-hashref value found,' . "\n" . 'croaking' );
    }

    my arrayref::integer $possible_arrayref_integer;
    foreach my string $key ( sort keys %{$possible_hashref_arrayref_integer} ) {
        $possible_arrayref_integer = $possible_hashref_arrayref_integer->{$key};

        # DEV NOTE: the following two if() statements are functionally equivalent to the arrayref_CHECK() subroutine, but with integer-specific error codes
        if ( not( defined $possible_arrayref_integer ) ) {
            croak( "\n" . 'ERROR EHVRVAVRVIV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                    "\n" . 'arrayref::integer value expected but undefined/null value found at key ' . q{'} . $key . q{',} . "\n" . 'croaking' );
        }

        if ( not( main::PerlTypes_SvAROKp($possible_arrayref_integer) ) ) {
            croak( "\n" . 'ERROR EHVRVAVRVIV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                    "\n" . 'arrayref::integer value expected but non-arrayref value found at key ' . q{'} . $key . q{',} . "\n" . 'croaking' );
        }

        my integer $possible_integer;
        for my integer $i ( 0 .. ( ( scalar @{$possible_arrayref_integer} ) - 1 ) )
        {
            $possible_integer = $possible_arrayref_integer->[$i];

            # DEV NOTE: the following two if() statements are functionally equivalent to the integer_CHECK() subroutine, but with arrayref_hashref-specific error codes
            if ( not( defined $possible_integer ) ) {
                $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
                $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
                croak( "\n" . 'ERROR EHVRVAVRVIV04, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                        "\n" . 'integer value expected but undefined/null value found at index ' . $i . ', key ' .  q{'} . $key . q{'} . ',' . "\n" . 'croaking' );
            }
            if ( not( main::PerlTypes_SvIOKp($possible_integer) ) ) {
                $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
                $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
                croak( "\n" . 'ERROR EHVRVAVRVIV05, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                        "\n" . 'integer value expected but non-integer value found at index ' . $i . ', key ' .  q{'} . $key . q{'} . ',' . "\n" . 'croaking' );
            }
        }
    }
    return;
}

sub hashref_arrayref_integer_CHECKTRACE {
    { my void $RETURN_TYPE };
    ( my $possible_hashref_arrayref_integer, my $variable_name, my $subroutine_name ) = @ARG;

#    Perl::diag('in PERLOPS_PERLTYPES hashref_arrayref_integer_CHECKTRACE(), top of subroutine', "\n");

    # DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() subroutine, but with integer-specific error codes
    if ( not( defined $possible_hashref_arrayref_integer ) ) {
        croak( "\n" . 'ERROR EHVRVAVRVIV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' . "\n" . 'hashref::arrayref::integer value expected but undefined/null value found,' . 
                "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
    }

    if ( not( main::PerlTypes_SvHROKp($possible_hashref_arrayref_integer) ) ) {
        croak( "\n" . 'ERROR EHVRVAVRVIV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' . "\n" . 'hashref::arrayref::integer value expected but non-hashref value found,' . 
                "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
    }

    my arrayref::integer $possible_arrayref_integer;
    foreach my string $key ( sort keys %{$possible_hashref_arrayref_integer} ) {
        $possible_arrayref_integer = $possible_hashref_arrayref_integer->{$key};

        # DEV NOTE: the following two if() statements are functionally equivalent to the arrayref_CHECK() subroutine, but with integer-specific error codes
        if ( not( defined $possible_arrayref_integer ) ) {
            croak( "\n" . 'ERROR EHVRVAVRVIV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                    "\n" . 'arrayref::integer value expected but undefined/null value found at key ' . q{'} . $key . q{',} . 
                    "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
        }

        if ( not( main::PerlTypes_SvAROKp($possible_arrayref_integer) ) ) {
            croak( "\n" . 'ERROR EHVRVAVRVIV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                    "\n" . 'arrayref::integer value expected but non-arrayref value found at key ' . q{'} . $key . q{',} .
                    "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
        }

        my integer $possible_integer;
        for my integer $i ( 0 .. ( ( scalar @{$possible_arrayref_integer} ) - 1 ) )
        {
            $possible_integer = $possible_arrayref_integer->[$i];

            # DEV NOTE: the following two if() statements are functionally equivalent to the integer_CHECK() subroutine, but with arrayref_hashref-specific error codes
            if ( not( defined $possible_integer ) ) {
                $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
                $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
                croak( "\n" . 'ERROR EHVRVAVRVIV04, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                        "\n" . 'integer value expected but undefined/null value found at index ' . $i . ', key ' .  q{'} . $key . q{'} . ',' .
                        "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
            }
            if ( not( main::PerlTypes_SvIOKp($possible_integer) ) ) {
                $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
                $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
                croak( "\n" . 'ERROR EHVRVAVRVIV05, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                        "\n" . 'integer value expected but non-integer value found at index ' . $i . ', key ' .  q{'} . $key . q{'} . ',' .
                        "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
            }
        }
    }
    return;
}

# [[[ STRINGIFY ]]]

# call actual stringify routine, format level -1 (compact), indent level 0
sub hashref_arrayref_integer_to_string_compact {
    { my string $RETURN_TYPE };
    ( my $input_hvref_avref ) = @ARG;
    return hashref_arrayref_integer_to_string_format($input_hvref_avref, -1, 0);
}

# call actual stringify routine, format level 0 (normal), indent level 0, DEFAULT
sub hashref_arrayref_integer_to_string {
    { my string $RETURN_TYPE };
    ( my $input_hvref_avref ) = @ARG;
    return hashref_arrayref_integer_to_string_format($input_hvref_avref, 0, 0);
}

# call actual stringify routine, format level 1 (pretty), indent level 0
sub hashref_arrayref_integer_to_string_pretty {
    { my string $RETURN_TYPE };
    ( my $input_hvref_avref ) = @ARG;
    return hashref_arrayref_integer_to_string_format($input_hvref_avref, 1, 0);
}

# call actual stringify routine, format level 2 (expand), indent level 0
sub hashref_arrayref_integer_to_string_expand {
    { my string $RETURN_TYPE };
    ( my $input_hvref_avref ) = @ARG;
    return hashref_arrayref_integer_to_string_format($input_hvref_avref, 2, 0);
}

# convert from (Perl SV containing RV to (Perl HV of (Perl SVs containing IVs))) to Perl-parsable (Perl SV containing PV)
sub hashref_arrayref_integer_to_string_format {
    { my string $RETURN_TYPE };
    ( my $input_hvref_avref, my integer $format_level, my integer $indent_level ) = @ARG;

#    Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_integer_to_string_format(), top of subroutine\n");
#    Perl::diag('in PERLOPS_PERLTYPES hashref_arrayref_integer_to_string_format(), received $format_level = ', $format_level, "\n");
#    Perl::diag('in PERLOPS_PERLTYPES hashref_arrayref_integer_to_string_format(), received $indent_level = ', $indent_level, "\n");

#    hashref_arrayref_integer_CHECK($input_hvref_avref);
    hashref_arrayref_integer_CHECKTRACE( $input_hvref_avref, '$input_hvref_avref', 'hashref_arrayref_integer_to_string_format()' );

    # declare local variables, av & sv mean "array value" & "scalar value" as used in Perl core
    my %input_hv_avref;
#   my integer $input_hv_avref__length;
    my arrayref::integer $input_hv_avref__entry_value;
    my string $output_sv;
    my boolean $i_is_0 = 1;

    # dereference input hash reference
    %input_hv_avref = %{$input_hvref_avref};

    # generate indent
    my string $indent = q{    } x $indent_level;

    # compute length of (number of keys in) input hash
#   $input_hv_avref__length = scalar keys %input_hv_avref;
#   Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_integer_to_string_format(), have \$input_hv_avref__length = $input_hv_avref__length\n");

    # pre-begin with optional indent, depending on format level
    if ($format_level >= 1) { $output_sv .= $indent; }  # pretty

    # begin output string with left-curly-brace, as required for all RPerl hashes
    $output_sv .= '{';

    # loop through all hash keys
    foreach my string $key ( sort keys %input_hv_avref ) {
        # retrieve input hash's entry value at key
        $input_hv_avref__entry_value = $input_hv_avref{$key};

# DEV NOTE: integer type-checking already done as part of hashref_arrayref_integer_CHECKTRACE()
#        integer_CHECK($input_hv_avref__entry_value);
#        integer_CHECKTRACE( $input_hv_avref__entry_value, "\$input_hv_avref__entry_value at key '$key'", 'hashref_arrayref_integer_to_string_format()' );

        # append comma to output string for all elements except index 0
        if ($i_is_0) { $i_is_0 = 0; }
        else         { $output_sv .= ','; }

        # append newline-indent-tab or space, depending on format level
        if    ($format_level >= 1) { $output_sv .=  "\n" . $indent . q{    }; }  # pretty & expand
        elsif ($format_level >= 0) { $output_sv .= q{ }; }  # normal

        $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
        $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character

        # DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
        $output_sv .= q{'} . $key . q{'};

        # append spaces before and after fat arrow AKA fat comma, depending on format level
        if ($format_level >= 0) { $output_sv .= ' => '; }  # normal & pretty & expand
        else                    { $output_sv .= '=>'; }    # compact

        # append newline after fat arrow AKA fat comma, depending on format level
        if ($format_level >= 2) { $output_sv .= "\n"; }  # expand

        # call *_to_string_format() for data sub-structure
        $output_sv .= ::arrayref_integer_to_string_format($input_hv_avref__entry_value, ($format_level - 1), ($indent_level + 1));  # YES UNDERSCORES
    }

    # append newline-indent or space, depending on format level
    if    ($format_level >= 1) { $output_sv .= "\n" . $indent; }  # pretty & expand
    elsif ($format_level >= 0) { $output_sv .= q{ }; }  # normal

    # end output string with right-curly-brace, as required for all RPerl hashes
    $output_sv .= '}';

#    Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_integer_to_string_format(), after for() loop, have \$output_sv =\n$output_sv\n");
#    Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_integer_to_string_format(), bottom of subroutine\n");
    return ($output_sv);
}

# [[[ TYPE TESTING ]]]

sub hashref_arrayref_integer_typetest0 {
    { my string $RETURN_TYPE };
    ( my hashref::arrayref::integer $lucky_integers) = @ARG;

#    hashref_arrayref_integer_CHECK($lucky_integers);
    hashref_arrayref_integer_CHECKTRACE( $lucky_integers, '$lucky_integers', 'hashref_arrayref_integer_typetest0()' );

#    foreach my string $key ( sort keys %{$lucky_integers} ) {
#        my $lucky_integer = $lucky_integers->{$key};
#        $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
#        $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
#
#        Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_integer_typetest0(), have lucky integer '$key' => " . $lucky_integer . ", BARSTOOL\n");
#    }
#    Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_integer_typetest0(), bottom of subroutine\n");
    return ( hashref_arrayref_integer_to_string($lucky_integers) . 'PERLOPS_PERLTYPES' );
}

sub hashref_arrayref_integer_typetest1 {
    { my hashref::arrayref::integer $RETURN_TYPE };
    ( my integer $my_size) = @ARG;

#    integer_CHECK($my_size);
    integer_CHECKTRACE( $my_size, '$my_size', 'hashref_arrayref_integer_typetest1()' );

    # create a square 2-D data structure
    my hashref::arrayref::integer $new_hash = {};
    my string $temp_key;
    for my integer $i ( 0 .. ( $my_size - 1 ) ) {
        $temp_key = 'PERLOPS_PERLTYPES_funkey' . $i;
        my arrayref::integer $temp_array = [];
        for my integer $j ( 0 .. ( $my_size - 1)) {
            $temp_array->[$j] = $i * $j;
        }
        $new_hash->{$temp_key} = $temp_array;

#        Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_integer_typetest1(), setting entry '$temp_key' => " . Dumper($new_hash->{$temp_key}) . ", BARSTOOL\n");
    }
    return ($new_hash);
}

# [[[ HASH REF ARRAY REF NUMBER ]]]
# [[[ HASH REF ARRAY REF NUMBER ]]]
# [[[ HASH REF ARRAY REF NUMBER ]]]

# (ref to hash) of (refs to (arrays of numbers))
package hashref::arrayref::number;
use strict;
use warnings;
use parent -norequire, qw(hashref::arrayref);

# [[[ SWITCH CONTEXT BACK TO PRIMARY PACKAGE FOR EXPORT TO WORK ]]]
package Perl::Structure::Hash::SubTypes2D;
use strict;
use warnings;

# [[[ TYPE-CHECKING ]]]

sub hashref_arrayref_number_CHECK {
    { my void $RETURN_TYPE };
    ( my $possible_hashref_arrayref_number ) = @ARG;

#    Perl::diag('in PERLOPS_PERLTYPES hashref_arrayref_number_CHECK(), top of subroutine', "\n");

    # DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() subroutine, but with number-specific error codes
    if ( not( defined $possible_hashref_arrayref_number ) ) {
        croak( "\n" . 'ERROR EHVRVAVRVNV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' . "\n" . 'hashref::arrayref::number value expected but undefined/null value found,' . "\n" . 'croaking' );
    }

    if ( not( main::PerlTypes_SvHROKp($possible_hashref_arrayref_number) ) ) {
        croak( "\n" . 'ERROR EHVRVAVRVNV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' . "\n" . 'hashref::arrayref::number value expected but non-hashref value found,' . "\n" . 'croaking' );
    }

    my arrayref::number $possible_arrayref_number;
    foreach my string $key ( sort keys %{$possible_hashref_arrayref_number} ) {
        $possible_arrayref_number = $possible_hashref_arrayref_number->{$key};

        # DEV NOTE: the following two if() statements are functionally equivalent to the arrayref_CHECK() subroutine, but with number-specific error codes
        if ( not( defined $possible_arrayref_number ) ) {
            croak( "\n" . 'ERROR EHVRVAVRVNV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                    "\n" . 'arrayref::number value expected but undefined/null value found at key ' . q{'} . $key . q{',} . "\n" . 'croaking' );
        }

        if ( not( main::PerlTypes_SvAROKp($possible_arrayref_number) ) ) {
            croak( "\n" . 'ERROR EHVRVAVRVNV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                    "\n" . 'arrayref::number value expected but non-arrayref value found at key ' . q{'} . $key . q{',} . "\n" . 'croaking' );
        }

        my number $possible_number;
        for my integer $i ( 0 .. ( ( scalar @{$possible_arrayref_number} ) - 1 ) )
        {
            $possible_number = $possible_arrayref_number->[$i];

            # DEV NOTE: the following two if() statements are functionally equivalent to the number_CHECK() subroutine, but with arrayref_hashref-specific error codes
            if ( not( defined $possible_number ) ) {
                $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
                $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
                croak( "\n" . 'ERROR EHVRVAVRVNV04, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                        "\n" . 'number value expected but undefined/null value found at index ' . $i . ', key ' .  q{'} . $key . q{'} . ',' . "\n" . 'croaking' );
            }
            if (not(   main::PerlTypes_SvNOKp($possible_number)
                    || main::PerlTypes_SvIOKp($possible_number) ) ) {
                $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
                $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
                croak( "\n" . 'ERROR EHVRVAVRVNV05, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                        "\n" . 'number value expected but non-number value found at index ' . $i . ', key ' .  q{'} . $key . q{'} . ',' . "\n" . 'croaking' );
            }
        }
    }
    return;
}

sub hashref_arrayref_number_CHECKTRACE {
    { my void $RETURN_TYPE };
    ( my $possible_hashref_arrayref_number, my $variable_name, my $subroutine_name ) = @ARG;

#    Perl::diag('in PERLOPS_PERLTYPES hashref_arrayref_number_CHECKTRACE(), top of subroutine', "\n");

    # DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() subroutine, but with number-specific error codes
    if ( not( defined $possible_hashref_arrayref_number ) ) {
        croak( "\n" . 'ERROR EHVRVAVRVNV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' . "\n" . 'hashref::arrayref::number value expected but undefined/null value found,' . 
                "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
    }

    if ( not( main::PerlTypes_SvHROKp($possible_hashref_arrayref_number) ) ) {
        croak( "\n" . 'ERROR EHVRVAVRVNV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' . "\n" . 'hashref::arrayref::number value expected but non-hashref value found,' . 
                "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
    }

    my arrayref::number $possible_arrayref_number;
    foreach my string $key ( sort keys %{$possible_hashref_arrayref_number} ) {
        $possible_arrayref_number = $possible_hashref_arrayref_number->{$key};

#        Perl::diag('in PERLOPS_PERLTYPES hashref_arrayref_number_CHECKTRACE(), at $key = ', q{'}, $key, q{'}, ', have $possible_arrayref_number = ', Dumper($possible_arrayref_number), "\n");

        # DEV NOTE: the following two if() statements are functionally equivalent to the arrayref_CHECK() subroutine, but with number-specific error codes
        if ( not( defined $possible_arrayref_number ) ) {
            croak( "\n" . 'ERROR EHVRVAVRVNV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                    "\n" . 'arrayref::number value expected but undefined/null value found at key ' . q{'} . $key . q{',} . 
                    "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
        }

        if ( not( main::PerlTypes_SvAROKp($possible_arrayref_number) ) ) {
            croak( "\n" . 'ERROR EHVRVAVRVNV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                    "\n" . 'arrayref::number value expected but non-arrayref value found at key ' . q{'} . $key . q{',} .
                    "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
        }

        my number $possible_number;
        for my integer $i ( 0 .. ( ( scalar @{$possible_arrayref_number} ) - 1 ) )
        {
            $possible_number = $possible_arrayref_number->[$i];

#            Perl::diag('in PERLOPS_PERLTYPES hashref_arrayref_number_CHECKTRACE(), at $key = ', q{'}, $key, q{'}, ', index $i = ', $i, ', have $possible_number = ', $possible_number, "\n");

            # DEV NOTE: the following two if() statements are functionally equivalent to the number_CHECK() subroutine, but with arrayref_hashref-specific error codes
            if ( not( defined $possible_number ) ) {
                $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
                $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
                croak( "\n" . 'ERROR EHVRVAVRVNV04, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                        "\n" . 'number value expected but undefined/null value found at index ' . $i . ', key ' .  q{'} . $key . q{'} . ',' .
                        "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
            }
            if (not(   main::PerlTypes_SvNOKp($possible_number)
                    || main::PerlTypes_SvIOKp($possible_number) ) ) {
                $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
                $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
                croak( "\n" . 'ERROR EHVRVAVRVNV05, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                        "\n" . 'number value expected but non-number value found at index ' . $i . ', key ' .  q{'} . $key . q{'} . ',' .
                        "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
            }
        }
    }
    return;
}

# [[[ STRINGIFY ]]]

# call actual stringify routine, format level -1 (compact), indent level 0
sub hashref_arrayref_number_to_string_compact {
    { my string $RETURN_TYPE };
    ( my $input_hvref_avref ) = @ARG;
    return hashref_arrayref_number_to_string_format($input_hvref_avref, -1, 0);
}

# call actual stringify routine, format level 0 (normal), indent level 0, DEFAULT
sub hashref_arrayref_number_to_string {
    { my string $RETURN_TYPE };
    ( my $input_hvref_avref ) = @ARG;
    return hashref_arrayref_number_to_string_format($input_hvref_avref, 0, 0);
}

# call actual stringify routine, format level 1 (pretty), indent level 0
sub hashref_arrayref_number_to_string_pretty {
    { my string $RETURN_TYPE };
    ( my $input_hvref_avref ) = @ARG;
    return hashref_arrayref_number_to_string_format($input_hvref_avref, 1, 0);
}

# call actual stringify routine, format level 2 (expand), indent level 0
sub hashref_arrayref_number_to_string_expand {
    { my string $RETURN_TYPE };
    ( my $input_hvref_avref ) = @ARG;
    return hashref_arrayref_number_to_string_format($input_hvref_avref, 2, 0);
}

# convert from (Perl SV containing RV to (Perl HV of (Perl SVs containing NVs))) to Perl-parsable (Perl SV containing PV)
sub hashref_arrayref_number_to_string_format {
    { my string $RETURN_TYPE };
    ( my $input_hvref_avref, my integer $format_level, my integer $indent_level ) = @ARG;

#    Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_number_to_string_format(), top of subroutine\n");
#    Perl::diag('in PERLOPS_PERLTYPES hashref_arrayref_number_to_string_format(), received $format_level = ', $format_level, "\n");
#    Perl::diag('in PERLOPS_PERLTYPES hashref_arrayref_number_to_string_format(), received $indent_level = ', $indent_level, "\n");

#    hashref_arrayref_number_CHECK($input_hvref_avref);
    hashref_arrayref_number_CHECKTRACE( $input_hvref_avref, '$input_hvref_avref', 'hashref_arrayref_number_to_string_format()' );

    # declare local variables, av & sv mean "array value" & "scalar value" as used in Perl core
    my %input_hv_avref;
#   my integer $input_hv_avref__length;
    my arrayref::number $input_hv_avref__entry_value;
    my string $output_sv;
    my boolean $i_is_0 = 1;

    # dereference input hash reference
    %input_hv_avref = %{$input_hvref_avref};

    # generate indent
    my string $indent = q{    } x $indent_level;

    # compute length of (number of keys in) input hash
#   $input_hv_avref__length = scalar keys %input_hv_avref;
#   Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_number_to_string_format(), have \$input_hv_avref__length = $input_hv_avref__length\n");

    # pre-begin with optional indent, depending on format level
    if ($format_level >= 1) { $output_sv .= $indent; }  # pretty

    # begin output string with left-curly-brace, as required for all RPerl hashes
    $output_sv .= '{';

    # loop through all hash keys
    foreach my string $key ( sort keys %input_hv_avref ) {
        # retrieve input hash's entry value at key
        $input_hv_avref__entry_value = $input_hv_avref{$key};

# DEV NOTE: number type-checking already done as part of hashref_arrayref_number_CHECKTRACE()
#        number_CHECK($input_hv_avref__entry_value);
#        number_CHECKTRACE( $input_hv_avref__entry_value, "\$input_hv_avref__entry_value at key '$key'", 'hashref_arrayref_number_to_string_format()' );

        # append comma to output string for all elements except index 0
        if ($i_is_0) { $i_is_0 = 0; }
        else         { $output_sv .= ','; }

        # append newline-indent-tab or space, depending on format level
        if    ($format_level >= 1) { $output_sv .=  "\n" . $indent . q{    }; }  # pretty & expand
        elsif ($format_level >= 0) { $output_sv .= q{ }; }  # normal

        $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
        $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character

        # DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
        $output_sv .= q{'} . $key . q{'};

        # append spaces before and after fat arrow AKA fat comma, depending on format level
        if ($format_level >= 0) { $output_sv .= ' => '; }  # normal & pretty & expand
        else                    { $output_sv .= '=>'; }    # compact

        # append newline after fat arrow AKA fat comma, depending on format level
        if ($format_level >= 2) { $output_sv .= "\n"; }  # expand

        # call *_to_string_format() for data sub-structure
        $output_sv .= ::arrayref_number_to_string_format($input_hv_avref__entry_value, ($format_level - 1), ($indent_level + 1));  # YES UNDERSCORES
    }

    # append newline-indent or space, depending on format level
    if    ($format_level >= 1) { $output_sv .= "\n" . $indent; }  # pretty & expand
    elsif ($format_level >= 0) { $output_sv .= q{ }; }  # normal

    # end output string with right-curly-brace, as required for all RPerl hashes
    $output_sv .= '}';

#    Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_number_to_string_format(), after for() loop, have \$output_sv =\n$output_sv\n");
#    Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_number_to_string_format(), bottom of subroutine\n");
    return ($output_sv);
}

# [[[ TYPE TESTING ]]]

sub hashref_arrayref_number_typetest0 {
    { my string $RETURN_TYPE };
    ( my hashref::arrayref::number $lucky_numbers) = @ARG;

#    hashref_arrayref_number_CHECK($lucky_numbers);
    hashref_arrayref_number_CHECKTRACE( $lucky_numbers, '$lucky_numbers', 'hashref_arrayref_number_typetest0()' );

#    foreach my string $key ( sort keys %{$lucky_numbers} ) {
#        my $lucky_number = $lucky_numbers->{$key};
#        $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
#        $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
#
#        Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_number_typetest0(), have lucky number '$key' => " . $lucky_number . ", BARSTOOL\n");
#    }
#    Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_number_typetest0(), bottom of subroutine\n");
    return ( hashref_arrayref_number_to_string($lucky_numbers) . 'PERLOPS_PERLTYPES' );
}

sub hashref_arrayref_number_typetest1 {
    { my hashref::arrayref::number $RETURN_TYPE };
    ( my integer $my_size) = @ARG;

#    integer_CHECK($my_size);
    integer_CHECKTRACE( $my_size, '$my_size', 'hashref_arrayref_number_typetest1()' );

    # create a square 2-D data structure
    my hashref::arrayref::number $new_hash = {};
    my string $temp_key;
    for my integer $i ( 0 .. ( $my_size - 1 ) ) {
        $temp_key = 'PERLOPS_PERLTYPES_funkey' . $i;
        my arrayref::number $temp_array = [];
        for my integer $j ( 0 .. ( $my_size - 1)) {
            $temp_array->[$j] = $i * $j * 5.123456789;
        }
        $new_hash->{$temp_key} = $temp_array;

#        Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_number_typetest1(), setting entry '$temp_key' => " . Dumper($new_hash->{$temp_key}) . ", BARSTOOL\n");
    }
    return ($new_hash);
}

# [[[ HASH REF ARRAY REF STRING ]]]
# [[[ HASH REF ARRAY REF STRING ]]]
# [[[ HASH REF ARRAY REF STRING ]]]

# (ref to hash) of (refs to (arrays of strings))
package hashref::arrayref::string;
use strict;
use warnings;
use parent -norequire, qw(hashref::arrayref);

# [[[ SWITCH CONTEXT BACK TO PRIMARY PACKAGE FOR EXPORT TO WORK ]]]
package Perl::Structure::Hash::SubTypes2D;
use strict;
use warnings;

# [[[ TYPE-CHECKING ]]]

sub hashref_arrayref_string_CHECK {
    { my void $RETURN_TYPE };
    ( my $possible_hashref_arrayref_string ) = @ARG;

#    Perl::diag('in PERLOPS_PERLTYPES hashref_arrayref_string_CHECK(), top of subroutine', "\n");

    # DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() subroutine, but with string-specific error codes
    if ( not( defined $possible_hashref_arrayref_string ) ) {
        croak( "\n" . 'ERROR EHVRVAVRVPV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' . "\n" . 'hashref::arrayref::string value expected but undefined/null value found,' . "\n" . 'croaking' );
    }

    if ( not( main::PerlTypes_SvHROKp($possible_hashref_arrayref_string) ) ) {
        croak( "\n" . 'ERROR EHVRVAVRVPV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' . "\n" . 'hashref::arrayref::string value expected but non-hashref value found,' . "\n" . 'croaking' );
    }

    my arrayref::string $possible_arrayref_string;
    foreach my string $key ( sort keys %{$possible_hashref_arrayref_string} ) {
        $possible_arrayref_string = $possible_hashref_arrayref_string->{$key};

        # DEV NOTE: the following two if() statements are functionally equivalent to the arrayref_CHECK() subroutine, but with string-specific error codes
        if ( not( defined $possible_arrayref_string ) ) {
            croak( "\n" . 'ERROR EHVRVAVRVPV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                    "\n" . 'arrayref::string value expected but undefined/null value found at key ' . q{'} . $key . q{',} . "\n" . 'croaking' );
        }

        if ( not( main::PerlTypes_SvAROKp($possible_arrayref_string) ) ) {
            croak( "\n" . 'ERROR EHVRVAVRVPV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                    "\n" . 'arrayref::string value expected but non-arrayref value found at key ' . q{'} . $key . q{',} . "\n" . 'croaking' );
        }

        my string $possible_string;
        for my integer $i ( 0 .. ( ( scalar @{$possible_arrayref_string} ) - 1 ) )
        {
            $possible_string = $possible_arrayref_string->[$i];

            # DEV NOTE: the following two if() statements are functionally equivalent to the string_CHECK() subroutine, but with arrayref_hashref-specific error codes
            if ( not( defined $possible_string ) ) {
                $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
                $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
                croak( "\n" . 'ERROR EHVRVAVRVPV04, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                        "\n" . 'string value expected but undefined/null value found at index ' . $i . ', key ' .  q{'} . $key . q{'} . ',' . "\n" . 'croaking' );
            }
            if ( not( main::PerlTypes_SvPOKp($possible_string) ) ) {
                $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
                $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
                croak( "\n" . 'ERROR EHVRVAVRVPV05, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                        "\n" . 'string value expected but non-string value found at index ' . $i . ', key ' .  q{'} . $key . q{'} . ',' . "\n" . 'croaking' );
            }
        }
    }
    return;
}

sub hashref_arrayref_string_CHECKTRACE {
    { my void $RETURN_TYPE };
    ( my $possible_hashref_arrayref_string, my $variable_name, my $subroutine_name ) = @ARG;

#    Perl::diag('in PERLOPS_PERLTYPES hashref_arrayref_string_CHECKTRACE(), top of subroutine', "\n");

    # DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() subroutine, but with string-specific error codes
    if ( not( defined $possible_hashref_arrayref_string ) ) {
        croak( "\n" . 'ERROR EHVRVAVRVPV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' . "\n" . 'hashref::arrayref::string value expected but undefined/null value found,' . 
                "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
    }

    if ( not( main::PerlTypes_SvHROKp($possible_hashref_arrayref_string) ) ) {
        croak( "\n" . 'ERROR EHVRVAVRVPV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' . "\n" . 'hashref::arrayref::string value expected but non-hashref value found,' . 
                "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
    }

    my arrayref::string $possible_arrayref_string;
    foreach my string $key ( sort keys %{$possible_hashref_arrayref_string} ) {
        $possible_arrayref_string = $possible_hashref_arrayref_string->{$key};

        # DEV NOTE: the following two if() statements are functionally equivalent to the arrayref_CHECK() subroutine, but with string-specific error codes
        if ( not( defined $possible_arrayref_string ) ) {
            croak( "\n" . 'ERROR EHVRVAVRVPV02, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                    "\n" . 'arrayref::string value expected but undefined/null value found at key ' . q{'} . $key . q{',} . 
                    "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
        }

        if ( not( main::PerlTypes_SvAROKp($possible_arrayref_string) ) ) {
            croak( "\n" . 'ERROR EHVRVAVRVPV03, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                    "\n" . 'arrayref::string value expected but non-arrayref value found at key ' . q{'} . $key . q{',} .
                    "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
        }

        my string $possible_string;
        for my integer $i ( 0 .. ( ( scalar @{$possible_arrayref_string} ) - 1 ) )
        {
            $possible_string = $possible_arrayref_string->[$i];

            # DEV NOTE: the following two if() statements are functionally equivalent to the string_CHECK() subroutine, but with arrayref_hashref-specific error codes
            if ( not( defined $possible_string ) ) {
                $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
                $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
                croak( "\n" . 'ERROR EHVRVAVRVPV04, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                        "\n" . 'string value expected but undefined/null value found at index ' . $i . ', key ' .  q{'} . $key . q{'} . ',' .
                        "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
            }
            if ( not( main::PerlTypes_SvPOKp($possible_string) ) ) {
                $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
                $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
                croak( "\n" . 'ERROR EHVRVAVRVPV05, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:' .
                        "\n" . 'string value expected but non-string value found at index ' . $i . ', key ' .  q{'} . $key . q{'} . ',' .
                        "\n" . 'in variable ' . q{'} . $variable_name . q{'} . ' from subroutine ' . q{'} . $subroutine_name . q{',} . "\n" . 'croaking' );
            }
        }
    }
    return;
}

# [[[ STRINGIFY ]]]

# call actual stringify routine, format level -1 (compact), indent level 0
sub hashref_arrayref_string_to_string_compact {
    { my string $RETURN_TYPE };
    ( my $input_hvref_avref ) = @ARG;
    return hashref_arrayref_string_to_string_format($input_hvref_avref, -1, 0);
}

# call actual stringify routine, format level 0 (normal), indent level 0, DEFAULT
sub hashref_arrayref_string_to_string {
    { my string $RETURN_TYPE };
    ( my $input_hvref_avref ) = @ARG;
    return hashref_arrayref_string_to_string_format($input_hvref_avref, 0, 0);
}

# call actual stringify routine, format level 1 (pretty), indent level 0
sub hashref_arrayref_string_to_string_pretty {
    { my string $RETURN_TYPE };
    ( my $input_hvref_avref ) = @ARG;
    return hashref_arrayref_string_to_string_format($input_hvref_avref, 1, 0);
}

# call actual stringify routine, format level 2 (expand), indent level 0
sub hashref_arrayref_string_to_string_expand {
    { my string $RETURN_TYPE };
    ( my $input_hvref_avref ) = @ARG;
    return hashref_arrayref_string_to_string_format($input_hvref_avref, 2, 0);
}

# convert from (Perl SV containing RV to (Perl HV of (Perl SVs containing NVs))) to Perl-parsable (Perl SV containing PV)
sub hashref_arrayref_string_to_string_format {
    { my string $RETURN_TYPE };
    ( my $input_hvref_avref, my integer $format_level, my integer $indent_level ) = @ARG;

#    Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_string_to_string_format(), top of subroutine\n");
#    Perl::diag('in PERLOPS_PERLTYPES hashref_arrayref_string_to_string_format(), received $format_level = ', $format_level, "\n");
#    Perl::diag('in PERLOPS_PERLTYPES hashref_arrayref_string_to_string_format(), received $indent_level = ', $indent_level, "\n");

#    hashref_arrayref_string_CHECK($input_hvref_avref);
    hashref_arrayref_string_CHECKTRACE( $input_hvref_avref, '$input_hvref_avref', 'hashref_arrayref_string_to_string_format()' );

    # declare local variables, av & sv mean "array value" & "scalar value" as used in Perl core
    my %input_hv_avref;
#   my integer $input_hv_avref__length;
    my arrayref::string $input_hv_avref__entry_value;
    my string $output_sv;
    my boolean $i_is_0 = 1;

    # dereference input hash reference
    %input_hv_avref = %{$input_hvref_avref};

    # generate indent
    my string $indent = q{    } x $indent_level;

    # compute length of (number of keys in) input hash
#   $input_hv_avref__length = scalar keys %input_hv_avref;
#   Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_string_to_string_format(), have \$input_hv_avref__length = $input_hv_avref__length\n");

    # pre-begin with optional indent, depending on format level
    if ($format_level >= 1) { $output_sv .= $indent; }  # pretty

    # begin output string with left-curly-brace, as required for all RPerl hashes
    $output_sv .= '{';

    # loop through all hash keys
    foreach my string $key ( sort keys %input_hv_avref ) {
        # retrieve input hash's entry value at key
        $input_hv_avref__entry_value = $input_hv_avref{$key};

# DEV NOTE: string type-checking already done as part of hashref_arrayref_string_CHECKTRACE()
#        string_CHECK($input_hv_avref__entry_value);
#        string_CHECKTRACE( $input_hv_avref__entry_value, "\$input_hv_avref__entry_value at key '$key'", 'hashref_arrayref_string_to_string_format()' );

        # append comma to output string for all elements except index 0
        if ($i_is_0) { $i_is_0 = 0; }
        else         { $output_sv .= ','; }

        # append newline-indent-tab or space, depending on format level
        if    ($format_level >= 1) { $output_sv .=  "\n" . $indent . q{    }; }  # pretty & expand
        elsif ($format_level >= 0) { $output_sv .= q{ }; }  # normal

        $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
        $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character

        # DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
        $output_sv .= q{'} . $key . q{'};

        # append spaces before and after fat arrow AKA fat comma, depending on format level
        if ($format_level >= 0) { $output_sv .= ' => '; }  # normal & pretty & expand
        else                    { $output_sv .= '=>'; }    # compact

        # append newline after fat arrow AKA fat comma, depending on format level
        if ($format_level >= 2) { $output_sv .= "\n"; }  # expand

        # call *_to_string_format() for data sub-structure
        $output_sv .= ::arrayref_string_to_string_format($input_hv_avref__entry_value, ($format_level - 1), ($indent_level + 1));  # YES UNDERSCORES
    }

    # append newline-indent or space, depending on format level
    if    ($format_level >= 1) { $output_sv .= "\n" . $indent; }  # pretty & expand
    elsif ($format_level >= 0) { $output_sv .= q{ }; }  # normal

    # end output string with right-curly-brace, as required for all RPerl hashes
    $output_sv .= '}';

#    Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_string_to_string_format(), after for() loop, have \$output_sv =\n$output_sv\n");
#    Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_string_to_string_format(), bottom of subroutine\n");
    return ($output_sv);
}

# [[[ TYPE TESTING ]]]

sub hashref_arrayref_string_typetest0 {
    { my string $RETURN_TYPE };
    ( my hashref::arrayref::string $lucky_strings) = @ARG;

#    hashref_arrayref_string_CHECK($lucky_strings);
    hashref_arrayref_string_CHECKTRACE( $lucky_strings, '$lucky_strings', 'hashref_arrayref_string_typetest0()' );

#    foreach my string $key ( sort keys %{$lucky_strings} ) {
#        my $lucky_string = $lucky_strings->{$key};
#        $key =~ s/\\/\\\\/gxms; # escape all back-slash \ characters with another back-slash \ character
#        $key =~ s/\'/\\\'/gxms; # escape all single-quote ' characters with a back-slash \ character
#
#        Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_string_typetest0(), have lucky string '$key' => " . $lucky_string . ", BARSTOOL\n");
#    }
#    Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_string_typetest0(), bottom of subroutine\n");
    return ( hashref_arrayref_string_to_string($lucky_strings) . 'PERLOPS_PERLTYPES' );
}

sub hashref_arrayref_string_typetest1 {
    { my hashref::arrayref::string $RETURN_TYPE };
    ( my integer $my_size) = @ARG;

#    integer_CHECK($my_size);
    integer_CHECKTRACE( $my_size, '$my_size', 'hashref_arrayref_string_typetest1()' );

    # create a square 2-D data structure
    my hashref::arrayref::string $new_hash = {};
    my string $temp_key;
    for my integer $i ( 0 .. ( $my_size - 1 ) ) {
        $temp_key = 'PERLOPS_PERLTYPES_funkey' . $i;
        my arrayref::string $temp_array = [];
        for my integer $j ( 0 .. ( $my_size - 1)) {
            $temp_array->[$j] = 'Jeffy Ten! (' . integer_to_string($i) . ', ' . integer_to_string($j) . ')/' . integer_to_string($my_size - 1);
        }
        $new_hash->{$temp_key} = $temp_array;

#        Perl::diag("in PERLOPS_PERLTYPES hashref_arrayref_string_typetest1(), setting entry '$temp_key' => " . Dumper($new_hash->{$temp_key}) . ", BARSTOOL\n");
    }
    return ($new_hash);
}

# [[[ HASH REF HASH REF ]]]
# [[[ HASH REF HASH REF ]]]
# [[[ HASH REF HASH REF ]]]

# (ref to hash) of (refs to hashs)
package hashref::hashref;
use strict;
use warnings;
use parent -norequire, qw(hashref);

# (ref to hash) of (refs to (hashs of integers))
package hashref::hashref::integer;
use strict;
use warnings;
use parent -norequire, qw(hashref::hashref);

# (ref to hash) of (refs to (hashs of numbers))
package hashref::hashref::number;
use strict;
use warnings;
use parent -norequire, qw(hashref::hashref);

# (ref to hash) of (refs to (hashs of strings))
package hashref::hashref::string;
use strict;
use warnings;
use parent -norequire, qw(hashref::hashref);

# (ref to hash) of (refs to (hashs of scalars))
package hashref::hashref::scalartype;
use strict;
use warnings;
use parent -norequire, qw(hashref::hashref);

# [[[ HASH REF OBJECT (2-dimensional???) ]]]
# [[[ HASH REF OBJECT (2-dimensional???) ]]]
# [[[ HASH REF OBJECT (2-dimensional???) ]]]

# (ref to hash) of objects
package hashref::object;
use strict;
use warnings;
use parent -norequire, qw(hashref);

1;  # end of package
