# [[[ HEADER ]]]
## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names
package perltypes;  # creating the first useful Perl pragmas in decades, you're welcome!
use strict;
use warnings;
use Perl::Config;
our $VERSION = 0.020_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitExcessComplexity)  # SYSTEM SPECIAL 5: allow complex code inside subroutines, must be after line 1
## no critic qw(ProhibitPostfixControls)  # SYSTEM SPECIAL 6: PERL CRITIC FILED ISSUE #639, not postfix foreach or if
## no critic qw(ProhibitDeepNests)  # SYSTEM SPECIAL 7: allow deeply-nested code
## no critic qw(RequireBriefOpen)  # SYSTEM SPECIAL 10: allow complex processing with open filehandle
## no critic qw(ProhibitCascadingIfElse)  # SYSTEM SPECIAL 12: allow complex conditional logic

# [[[ INCLUDES, NON-PERL-TYPES MODULES ]]]
use Scalar::Util qw(blessed);

# [[[ INCLUDES, DATA TYPE SIZES ]]]
use perltypessizes;

# DEV NOTE, CORRELATION #rp012: type system includes, hard-copies in perltypes.pm & perltypesconv.pm & Class.pm
# DEV NOTE: all the following type lists are sorted from lowest-to-highest level

# [[[ INCLUDES, DATA TYPES ]]]
use Perl::Type::Void;
use Perl::Type::Boolean;
use Perl::Type::NonsignedInteger;
use Perl::Type::Integer;
use Perl::Type::Number;
use Perl::Type::Character;
use Perl::Type::String;
use Perl::Type::Scalar;
use Perl::Type::Unknown;
use Perl::Type::FileHandle;

# [[[ INCLUDES, DATA STRUCTURES ]]]
use Perl::Structure::Array;
use Perl::Structure::Array::SubTypes;
use Perl::Structure::Array::SubTypes1D;
use Perl::Structure::Array::SubTypes2D;
use Perl::Structure::Array::SubTypes3D;
use Perl::Structure::Array::Reference;
use Perl::Structure::Hash;
use Perl::Structure::Hash::SubTypes;
use Perl::Structure::Hash::SubTypes1D;
use Perl::Structure::Hash::SubTypes2D;
use Perl::Structure::Hash::SubTypes3D;
use Perl::Structure::Hash::Reference;

#use Perl::Structure::LinkedList;
#use Perl::Structure::LinkedList::Node;
#use Perl::Structure::Graph;
#use Perl::Structure::Graph::Tree;
#use Perl::Structure::Graph::Tree::Binary;
#use Perl::Structure::Graph::Tree::Binary::Node;

# DEV NOTE, CORRELATION #rp008: use Perl::Exporter here instead of perltypesconv.pm

# [[[ EXPORTS ]]]
use Exporter 'import';
our @EXPORT = (
    @Perl::Config::EXPORT,  # export all symbols imported from essential modules; includes Data::Dumper, English, Carp, and POSIX
    @Perl::Type::Void::EXPORT,
    @Perl::Type::Boolean::EXPORT,
    @Perl::Type::NonsignedInteger::EXPORT,
    @Perl::Type::Integer::EXPORT,
    @Perl::Type::Number::EXPORT,
    @Perl::Type::Character::EXPORT,
    @Perl::Type::String::EXPORT,
    @Perl::Type::Scalar::EXPORT,
    @Perl::Type::Unknown::EXPORT,
    @Perl::Structure::Array::SubTypes::EXPORT,
    @Perl::Structure::Array::SubTypes1D::EXPORT,
    @Perl::Structure::Array::SubTypes2D::EXPORT,
    @Perl::Structure::Array::SubTypes3D::EXPORT,
    @Perl::Structure::Hash::SubTypes::EXPORT,
    @Perl::Structure::Hash::SubTypes1D::EXPORT,
    @Perl::Structure::Hash::SubTypes2D::EXPORT,
    @Perl::Structure::Hash::SubTypes3D::EXPORT
);
our @EXPORT_OK = (
    @Perl::Config::EXPORT_OK,  # export all symbols imported from essential modules; includes Data::Dumper, English, Carp, and POSIX
    @Perl::Type::Void::EXPORT_OK,
    @Perl::Type::Boolean::EXPORT_OK,
    @Perl::Type::NonsignedInteger::EXPORT_OK,
    @Perl::Type::Integer::EXPORT_OK,
    @Perl::Type::Number::EXPORT_OK,
    @Perl::Type::Character::EXPORT_OK,
    @Perl::Type::String::EXPORT_OK,
    @Perl::Type::Scalar::EXPORT_OK,
    @Perl::Type::Unknown::EXPORT_OK,
    @Perl::Structure::Array::SubTypes::EXPORT_OK,
    @Perl::Structure::Array::SubTypes1D::EXPORT_OK,
    @Perl::Structure::Array::SubTypes2D::EXPORT_OK,
    @Perl::Structure::Array::SubTypes3D::EXPORT_OK,
    @Perl::Structure::Hash::SubTypes::EXPORT_OK,
    @Perl::Structure::Hash::SubTypes1D::EXPORT_OK,
    @Perl::Structure::Hash::SubTypes2D::EXPORT_OK,
    @Perl::Structure::Hash::SubTypes3D::EXPORT_OK
);

# [[[ INCLUDES, OBJECT-ORIENTED ]]]
use Perl::Object;

# DEV NOTE, CORRELATION #rp051: hard-coded list of Perl data types and data structures
# these types are currently implemented for the 2 primary Perl modes: PERLOPS_PERLTYPES, CPPOPS_CPPTYPES
# MISSING: boolean, nonsigned_integer, character, *_arrayref, *_hashref
our arrayref::string $SUPPORTED = [
    qw(
        void
        integer
        number
        string
        arrayref
        arrayref::integer
        arrayref::number
        arrayref::string
        hashref
        hashref::integer
        hashref::number
        hashref::string
        hashref::arrayref::integer
        hashref::arrayref::number
        hashref::arrayref::string
        hashref::hashref::arrayref::integer
        hashref::hashref::arrayref::number
        hashref::hashref::arrayref::string
    )
];
our arrayref::string $SUPPORTED_SPECIAL = [
    qw(
        sse_number_pair
        gmp_integer
        gsl_matrix
    )
];

# DEV NOTE, CORRELATION #rp008: export to_string(), class(), type() and types() to main:: namespace;
# can't achieve via Exporter due to circular dependency issue caused by Exporter in Config.pm and solved by 'require perltypes;' in Perl.pm
package main;
use Perl::Config;
use Scalar::Util qw(blessed);

# for type-checking via SvIOKp(), SvNOKp(), and SvPOKp(); inside INIT to delay until after 'use MyConfig'
#INIT { Perl::diag("in perltypes.pm, loading C++ helper functions for type-checking...\n"); }
INIT {
    use Perl::HelperFunctions_cpp;
    Perl::HelperFunctions_cpp::cpp_load();
}

# [[[ GENERIC OVERLOADED TYPE CONVERSION ]]]
# [[[ GENERIC OVERLOADED TYPE CONVERSION ]]]
# [[[ GENERIC OVERLOADED TYPE CONVERSION ]]]

sub to_number {
    { my number $RETURN_TYPE };
    ( my unknown $variable) = @ARG;
    if ( not defined $variable ) { return 0; }
    my string $type = type($variable);
    if    ( $type eq 'unknown' ) { return ($variable + 0); }
    elsif ( $type eq 'boolean' )    { return boolean_to_number($variable); }
#    elsif ( $type eq 'nonsigned_integer' ) { return nonsigned_integer_to_number($variable); }  # DEV NOTE: causes auto-vivification of empty nonsigned_integer_to_number() if not already properly bound
#    elsif ( $type eq 'gmp_integer' ) { return gmp_integer_to_number($variable); }  # NEED IMPLEMENT 
    elsif ( $type eq 'integer' ) { return integer_to_number($variable); }
#    elsif ( $type eq 'number' )  { return number_to_number($variable); }  # NEED ANSWER: is this totally unneeded, and should it be deleted?
    elsif ( $type eq 'character' )    { return character_to_number($variable); }
    elsif ( $type eq 'string' )  { return string_to_number($variable); }
    else {
        croak q{ERROR ERPTY01: Invalid data type '} . $type . q{' specified, croaking};
    }
    return;
}

# NEED UPGRADE: don't fall back to Perl qq{} string interpolation or Dumper() for stringification;
# Dumper will fail to call *_to_string() until stringification overloading is implemented
sub to_string {
    { my string $RETURN_TYPE };
    ( my unknown $variable) = @ARG;
#    Perl::diag('in perltypes::to_string(), received $variable = ' . $variable . "\n");
    if ( not defined $variable ) { return 'undef'; }
    my string $type = type($variable);
#    Perl::diag('in perltypes::to_string(), have $type = ' . $type . "\n");

    if    ( $type eq 'unknown' ) { return qq{$variable}; }
    elsif ( $type eq 'boolean' )    { return boolean_to_string($variable); }
#    elsif ( $type eq 'nonsigned_integer' ) { return nonsigned_integer_to_string($variable); }  # DEV NOTE: causes auto-vivification of empty nonsigned_integer_to_string() if not already properly bound
#    elsif ( $type eq 'gmp_integer' ) { return gmp_integer_to_string($variable); }  # NEED IMPLEMENT 
    elsif ( $type eq 'integer' ) { return integer_to_string($variable); }
    elsif ( $type eq 'number' )  { return number_to_string($variable); }
    elsif ( $type eq 'character' )    { return character_to_string($variable); }
    elsif ( $type eq 'string' )  { return string_to_string($variable); }
    else {
        my $retval = Dumper($variable);
        $retval =~ s/\$VAR1\ =\ //gxms;
        chomp $retval;
        chop $retval;
        return $retval;
    }
    return;
}

# DEV NOTE: class() is a wrapper around blessed() from Scalar::Util, class() is preferred for readability, 
# blessed() and class() both generate as classname() in C++ to avoid conflict with 'class' C++ reserved word
sub class {
    { my string $RETURN_TYPE };
    ( my unknown $object ) = @ARG;
    return blessed($object);
}

# DEV NOTE: type() and types() are more powerful replacements for ref(), and ref() is not supported in RPerl
sub type {
    { my string $RETURN_TYPE };
    ( my unknown $variable, my integer $recurse_level ) = @ARG;
    if ( not defined $variable ) { return 'unknown'; }
    if ( not defined $recurse_level ) { $recurse_level = 10; }    # default to limited recursion
    my hashref::integer $is_type = build_is_type($variable);
#    Perl::diag('in perltypes::type(), have $is_type = ' . Dumper($is_type) . "\n");
    # DEV NOTE, CORRELATION #rp025: only report core types integer, number, string, arrayref, hashref, object;
    # do NOT report non-core types boolean, nonsigned_integer, char, etc.
    # DEV NOTE: Perl's implicit casting can cause 1 constant or variable to report multiple types, 
    # always report number before integer to avoid incorrect to_string() formatting
    if ( $is_type->{number} )  { return 'number'; }
    elsif ( $is_type->{integer} ) { return 'integer'; }
    elsif ( $is_type->{string} )  { return 'string'; }
    else {    # arrayref, hashref, or blessed object
        my arrayref $types = types_recurse( $variable, $recurse_level, $is_type );
        return $types->[0];    # only return flat type string, discard nested type hashref
    }
    return;
}

sub types {
    { my hashref::string $RETURN_TYPE };
    ( my unknown $variable, my integer $recurse_level ) = @ARG;
    if ( not defined $variable ) { return 'unknown'; }
    if ( not defined $recurse_level ) { $recurse_level = 10; }    # default to limited recursion
    my hashref::integer $is_type = build_is_type($variable);
    # DEV NOTE, CORRELATION #rp025: only report core types integer, number, string, arrayref, hashref, object;
    # do NOT report non-core types boolean, nonsigned_integer, char, etc.
    if ( $is_type->{integer} ) { return { 'integer' => undef }; }
    elsif ( $is_type->{number} )  { return { 'number'  => undef }; }
    elsif ( $is_type->{string} )  { return { 'string'  => undef }; }
    else {    # arrayref, hash, or blessed object
        my arrayref $types = types_recurse( $variable, $recurse_level, $is_type );
        return $types->[1];    # only return nested type hashref, discard flat type string
    }
    return;
}

sub build_is_type {
    { my hashref::integer $RETURN_TYPE };
    ( my unknown $variable ) = @ARG;

    my hashref::integer $is_type = {
        boolean   => main::PerlTypes_SvBOKp($variable),
        nonsigned_integer  => main::PerlTypes_SvUIOKp($variable),

# START HERE: figure out why SvIOKp() below is returning true for floating-point number Pi()
# START HERE: figure out why SvIOKp() below is returning true for floating-point number Pi()
# START HERE: figure out why SvIOKp() below is returning true for floating-point number Pi()

        integer   => main::PerlTypes_SvIOKp($variable),
        number    => main::PerlTypes_SvNOKp($variable),
        character => main::PerlTypes_SvCOKp($variable),
        string    => main::PerlTypes_SvPOKp($variable),
        arrayref  => main::PerlTypes_SvAROKp($variable),
        hashref   => main::PerlTypes_SvHROKp($variable),
        blessed   => 0,
        class     => blessed $variable
    };
    if ( defined $is_type->{class} ) { $is_type->{blessed} = 1; }

    #    Perl::diag('in perltypes::build_is_type(), have $is_type =' . "\n" . Dumper($is_type) . "\n");
    return $is_type;
}

sub types_recurse {
    { my hashref::string $RETURN_TYPE };
    ( my unknown $variable, my integer $recurse_level, my hashref::integer $is_type ) = @ARG;

    #    Perl::diag('in perltypes::types_recurse(), received $variable =' . "\n" . Dumper($variable) . "\n");

    if ( not defined $recurse_level ) { $recurse_level = 999; }                        # default to full recursion
    if ( not defined $is_type )       { $is_type       = build_is_type($variable); }

    #    Perl::diag('in perltypes::types_recurse(), have $recurse_level = ' . $recurse_level . "\n");

    #    Perl::diag('in perltypes::types_recurse(), have $is_type =' . "\n" . Dumper($is_type) . "\n");

    my string $type          = undef;
    my hashref::string $types = undef;

    # DEV NOTE, CORRELATION #rp025: only report core types integer, number, string, arrayref, hashref, object;
    # do NOT report non-core types boolean, nonsigned_integer, character, etc.
    if    ( not defined $variable ) { $type = 'unknown'; }
    elsif ( $is_type->{integer} )   { $type = 'integer'; }
    elsif ( $is_type->{number} )    { $type = 'number'; }
    elsif ( $is_type->{string} )    { $type = 'string'; }

    if ( defined $type ) {

        #        Perl::diag('in perltypes::types_recurse(), about to return undef or scalar $type = ' . $type . "\n");
        return [ $type, $types ];
    }
    elsif ( $recurse_level <= 0 ) {

        # blessed class must be tested first, because it also matches on hashref
        if ( $is_type->{blessed} ) {
            $type = 'object';
            $types = { $type => { '__CLASS' => $is_type->{class} } };
        }
        elsif ( $is_type->{arrayref} ) { $type = 'arrayref'; }
        elsif ( $is_type->{hashref} )  { $type = 'hashref'; }
        else                           { $type = '__UNRECOGNIZED_TYPE'; }

        #        Perl::diag('in perltypes::types_recurse(), max recurse reached, about to return unrecognized or non-scalar $type = ' . $type . "\n");
        return [ $type, $types ];
    }
    else {
        $recurse_level--;

        # blessed class must be tested first, because it also matches on hashref
        # DEV NOTE: objects don't inherit subtypes of their $properties hash entries, even if homogeneous;
        # no such thing as integer_object even if all $properties are integers, etc.
        if ( $is_type->{blessed} ) {
            $type  = 'object';
            $types = {};
            $types->{$type} = { '__CLASS' => $is_type->{class} };

            #            Perl::diag('in perltypes::types_recurse(), top of blessed class...' . "\n");

            foreach my $hash_key ( sort keys %{$variable} ) {
                my hashref $subtypes = types_recurse( $variable->{$hash_key}, $recurse_level );
                if ( not defined $subtypes->[1] ) {

                    # for scalar subtypes or non-scalar subtypes w/ max recurse reached, discard undef nested type hashref
                    $types->{$type}->{$hash_key} = $subtypes->[0];
                }
                else {
                    # for non-scalar subtypes w/out max recurse reached, append nested subtype hashref to list of types for this arrayref
                    $types->{$type}->{$hash_key} = $subtypes->[1];
                }
                Perl::diag('in perltypes::types_recurse(), inside blessed class, have $types = ' . "\n" . Dumper($types) . "\n");
                Perl::diag('in perltypes::types_recurse(), inside blessed class, have $subtypes = ' . "\n" . Dumper($subtypes) . "\n");

            }

            #            Perl::diag('in perltypes::types_recurse(), bottom of blessed class, have $type = ' . $type . "\n");
        }
        elsif ( $is_type->{arrayref} ) {
            $type           = 'arrayref';
            $types          = {};
            $types->{$type} = [];
            my string $subtype          = undef;
            my string $subtype_class    = undef;
            my integer $object_mismatch = 0;
            my integer $is_homogeneous  = 1;

            #            Perl::diag('in perltypes::types_recurse(), top of arrayref...' . "\n");

            foreach my $array_element ( @{$variable} ) {
                my hashref $subtypes = types_recurse( $array_element, $recurse_level );
                if ( not defined $subtypes->[1] ) {

                    # for scalar subtypes or non-scalar subtypes w/ max recurse reached, discard undef nested type hashref
                    push @{ $types->{$type} }, $subtypes->[0];
                }
                else {
                    # for non-scalar subtypes w/out max recurse reached, append nested subtype hashref to list of types for this arrayref
                    push @{ $types->{$type} }, $subtypes->[1];
                }

                #                Perl::diag('in perltypes::types_recurse(), inside arrayref, have $types = ' . "\n" . Dumper($types) . "\n");
                #                Perl::diag('in perltypes::types_recurse(), inside arrayref, have $subtypes = ' . "\n" . Dumper($subtypes) . "\n");

                # use first element's type as test for remaining element types
                if ( not defined $subtype ) {
                    $subtype = $subtypes->[0];
                    if ( $subtype eq 'object' ) {
                        $subtype_class = $subtypes->[1]->{object}->{__CLASS};
                    }
                }
                elsif ($is_homogeneous) {

                    #                    Perl::diag('in perltypes::types_recurse(), inside arrayref, have $subtype = ' . $subtype . "\n");
                    #                    Perl::diag('in perltypes::types_recurse(), inside arrayref, have $subtypes->[0] = ' . $subtypes->[0] . "\n");

#                    Perl::diag('in perltypes::types_recurse(), inside arrayref, have $subtype_class = ' . $subtype_class . "\n");
#                    Perl::diag('in perltypes::types_recurse(), inside arrayref, have $subtypes->[1]->{object}->{__CLASS} = ' . $subtypes->[1]->{object}->{__CLASS} . "\n");
# object classes must match for homogeneity
                    if ( ( $subtype eq 'object' ) and ( $subtypes->[0] eq 'object' ) and ( $subtype_class ne $subtypes->[1]->{object}->{__CLASS} ) ) {

                    #                        Perl::diag('in perltypes::types_recurse(), inside arrayref, MISMATCH OF OBJECT CLASSES' . "\n");
                    #                        Perl::diag('in perltypes::types_recurse(), inside arrayref, have $types = ' . "\n" . Dumper($types) . "\n");
                    #                        Perl::diag('in perltypes::types_recurse(), inside arrayref, have $subtypes = ' . "\n" . Dumper($subtypes) . "\n");
                        $object_mismatch = 1;
                    }
                    else { $object_mismatch = 0; }

                    if ( $object_mismatch or ( $subtype ne $subtypes->[0] ) ) {
                        my arrayref::string $reverse_split_subtype    = [ reverse split /_/xms, $subtype ];
                        my arrayref::string $reverse_split_subtypes_0 = [ reverse split /_/xms, $subtypes->[0] ];

#                        Perl::diag('in perltypes::types_recurse(), inside arrayref, have $reverse_split_subtype = ' . "\n" . Dumper($reverse_split_subtype) . "\n");
#                        Perl::diag('in perltypes::types_recurse(), inside arrayref, have $reverse_split_subtypes_0 = ' . "\n" . Dumper($reverse_split_subtypes_0) . "\n");
# discard non-matching 'object' subtype
                        if ($object_mismatch) {
                            pop @{$reverse_split_subtype};
                            pop @{$reverse_split_subtypes_0};
                            $object_mismatch = 0;
                        }
                        my string $new_subtype           = q{};
                        my integer $shorter_split_length = scalar @{$reverse_split_subtype};
                        if ( scalar @{$reverse_split_subtypes_0} < $shorter_split_length ) {
                            $shorter_split_length = scalar @{$reverse_split_subtypes_0};
                        }
                        for my integer $i ( 0 .. ( $shorter_split_length - 1 ) ) {

#                            Perl::diag('in perltypes::types_recurse(), inside arrayref, have $reverse_split_subtype->[' . $i . '] = ' . $reverse_split_subtype->[$i] . "\n");
#                            Perl::diag('in perltypes::types_recurse(), inside arrayref, have $reverse_split_subtypes_0->[' . $i . '] = ' . $reverse_split_subtypes_0->[$i] . "\n");
                            if ( $reverse_split_subtype->[$i] eq $reverse_split_subtypes_0->[$i] ) {
                                if ( $new_subtype eq q{} ) {
                                    $new_subtype = $reverse_split_subtype->[$i];
                                }
                                else {
                                    $new_subtype = $reverse_split_subtype->[$i] . '_' . $new_subtype;
                                }
                            }
                        }
                        if ( $new_subtype ne q{} ) {
                            $subtype = $new_subtype;
                        }
                        else {
                            $is_homogeneous = 0;
                        }
                    }
                }

                #                Perl::diag('in perltypes::types_recurse(), inside arrayref, have $subtype = ' . $subtype . "\n");
            }
            if ($is_homogeneous) {

                # DEV NOTE: flatten unknown_hashref to hashref
                if ( ( not defined $subtype ) or ( $subtype eq 'unknown' ) ) { $subtype = q{} }
                if ( $subtype ne q{} ) {
                    my string $type_old = $type;
                    $type = $subtype . '_' . $type;
                    $types->{$type} = $types->{$type_old};
                    delete $types->{$type_old};
                }
            }

            #            Perl::diag('in perltypes::types_recurse(), bottom of arrayref, have $type = ' . $type . "\n");
        }
        elsif ( $is_type->{hashref} ) {
            $type           = 'hashref';
            $types          = {};
            $types->{$type} = {};
            my string $subtype          = undef;
            my string $subtype_class    = undef;
            my integer $object_mismatch = 0;
            my integer $is_homogeneous  = 1;

            #            Perl::diag('in perltypes::types_recurse(), top of hashref...' . "\n");

            foreach my $hash_key ( sort keys %{$variable} ) {
                my hashref $subtypes = types_recurse( $variable->{$hash_key}, $recurse_level );
                if ( not defined $subtypes->[1] ) {

                    # for scalar subtypes or non-scalar subtypes w/ max recurse reached, discard undef nested type hashref
                    $types->{$type}->{$hash_key} = $subtypes->[0];
                }
                else {
                    # for non-scalar subtypes w/out max recurse reached, append nested subtype hashref to list of types for this hashref
                    $types->{$type}->{$hash_key} = $subtypes->[1];
                }

                #                Perl::diag('in perltypes::types_recurse(), inside hashref, have $types = ' . "\n" . Dumper($types) . "\n");
                #                Perl::diag('in perltypes::types_recurse(), inside hashref, have $subtypes = ' . "\n" . Dumper($subtypes) . "\n");

                # use first element's type as test for remaining element types
                if ( not defined $subtype ) {
                    $subtype = $subtypes->[0];
                    if ( $subtype eq 'object' ) {
                        $subtype_class = $subtypes->[1]->{object}->{__CLASS};
                    }
                }
                elsif ($is_homogeneous) {

                    #                    Perl::diag('in perltypes::types_recurse(), inside hashref, have $subtype = ' . $subtype . "\n");
                    #                    Perl::diag('in perltypes::types_recurse(), inside hashref, have $subtypes->[0] = ' . $subtypes->[0] . "\n");

#                    Perl::diag('in perltypes::types_recurse(), inside hashref, have $subtype_class = ' . $subtype_class . "\n");
#                    Perl::diag('in perltypes::types_recurse(), inside hashref, have $subtypes->[1]->{object}->{__CLASS} = ' . $subtypes->[1]->{object}->{__CLASS} . "\n");
# object classes must match for homogeneity
                    if ( ( $subtype eq 'object' ) and ( $subtypes->[0] eq 'object' ) and ( $subtype_class ne $subtypes->[1]->{object}->{__CLASS} ) ) {

                     #                        Perl::diag('in perltypes::types_recurse(), inside hashref, MISMATCH OF OBJECT CLASSES' . "\n");
                     #                        Perl::diag('in perltypes::types_recurse(), inside hashref, have $types = ' . "\n" . Dumper($types) . "\n");
                     #                        Perl::diag('in perltypes::types_recurse(), inside hashref, have $subtypes = ' . "\n" . Dumper($subtypes) . "\n");
                        $object_mismatch = 1;
                    }
                    else { $object_mismatch = 0; }

                    if ( $object_mismatch or ( $subtype ne $subtypes->[0] ) ) {
                        my arrayref::string $reverse_split_subtype    = [ reverse split /_/xms, $subtype ];
                        my arrayref::string $reverse_split_subtypes_0 = [ reverse split /_/xms, $subtypes->[0] ];

#                        Perl::diag('in perltypes::types_recurse(), inside hashref, have $reverse_split_subtype = ' . "\n" . Dumper($reverse_split_subtype) . "\n");
#                        Perl::diag('in perltypes::types_recurse(), inside hashref, have $reverse_split_subtypes_0 = ' . "\n" . Dumper($reverse_split_subtypes_0) . "\n");
# discard non-matching 'object' subtype
                        if ($object_mismatch) {
                            pop @{$reverse_split_subtype};
                            pop @{$reverse_split_subtypes_0};
                            $object_mismatch = 0;
                        }
                        my string $new_subtype           = q{};
                        my integer $shorter_split_length = scalar @{$reverse_split_subtype};
                        if ( scalar @{$reverse_split_subtypes_0} < $shorter_split_length ) {
                            $shorter_split_length = scalar @{$reverse_split_subtypes_0};
                        }
                        for my integer $i ( 0 .. ( $shorter_split_length - 1 ) ) {

#                            Perl::diag('in perltypes::types_recurse(), inside hashref, have $reverse_split_subtype->[' . $i . '] = ' . $reverse_split_subtype->[$i] . "\n");
#                            Perl::diag('in perltypes::types_recurse(), inside hashref, have $reverse_split_subtypes_0->[' . $i . '] = ' . $reverse_split_subtypes_0->[$i] . "\n");
                            if ( $reverse_split_subtype->[$i] eq $reverse_split_subtypes_0->[$i] ) {
                                if ( $new_subtype eq q{} ) {
                                    $new_subtype = $reverse_split_subtype->[$i];
                                }
                                else {
                                    $new_subtype = $reverse_split_subtype->[$i] . '_' . $new_subtype;
                                }
                            }
                        }
                        if ( $new_subtype ne q{} ) {
                            $subtype = $new_subtype;
                        }
                        else {
                            $is_homogeneous = 0;
                        }
                    }
                }

                #                Perl::diag('in perltypes::types_recurse(), inside hashref, have $subtype = ' . $subtype . "\n");
            }
            if ($is_homogeneous) {

                # DEV NOTE: flatten unknown_arrayref to arrayref
                if ( ( not defined $subtype ) or ( $subtype eq 'unknown' ) ) { $subtype = q{} }
                if ( $subtype ne q{} ) {
                    my string $type_old = $type;
                    $type = $subtype . '_' . $type;
                    $types->{$type} = $types->{$type_old};
                    delete $types->{$type_old};
                }
            }

            #            Perl::diag('in perltypes::types_recurse(), bottom of hashref, have $type = ' . $type . "\n");
        }
        else {
            $type = '__UNRECOGNIZED_TYPE';
        }
        return [ $type, $types ];
    }
    return;
}
1;


# [[[ C++ TYPE CONTROL ]]]
package    # hide from PAUSE indexing
    Perl;
if ( not defined $Perl::INCLUDE_PATH ) {
    our $INCLUDE_PATH = '/FAILURE/BECAUSE/PERL/INCLUDE/PATH/NOT/YET/SET';
}
1;    # suppress warnings about typo in types_enable() below

package perltypes;

sub types_enable {
    { my void $RETURN_TYPE };
    ( my $types_input ) = @ARG;

#    Perl::diag('in perltypes::types_enable(), received $types_input = ' . $types_input . "\n");

    if (($types_input ne 'PERL') and ($types_input ne 'CPP')) {
        croak q{ERROR ERPTY00: Invalid Perl types '} . $types_input . q{' specified where PERL or CPP expected, croaking};
    }

    $Perl::TYPES_CCFLAG = ' -D__' . $types_input . '__TYPES';

#    Perl::diag('in perltypes::types_enable(), set $Perl::TYPES_CCFLAG = ' . $Perl::TYPES_CCFLAG . "\n");
    return;
}

1;  # end of package

