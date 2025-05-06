# [[[ PREPROCESSOR ]]]
# <<< TYPE_CHECKING: ON >>>

# the following subroutines are automatically called when 1 or more of the subroutines in this file are called:

# integer_CHECK()
# number_CHECK()
# string_CHECK()

# arrayref_CHECK()
# arrayref_integer_CHECK()
# arrayref_number_CHECK()
# arrayref_string_CHECK()

# hashref_CHECK()
# hashentry_CHECK()  [NOT A DATA TYPE]
# integer_hashref_CHECK()
# number_hashref_CHECK()
# string_hashref_CHECK()

# [[[ HEADER ]]]
use Perl::Types;
package Perl::Types::Test::TypeCheckingOn::AllTypes;
use strict;
use warnings;
our $VERSION = 0.005_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Types::Test);
use Perl::Types::Test;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitAutomaticExportation)  # SYSTEM SPECIAL 14: allow global exports from Config.pm & elsewhere

# [[[ EXPORTS ]]]
use Exporter qw(import);
our @EXPORT = qw(check_integer check_number check_string check_arrayref check_integer_arrayref check_number_arrayref check_number_arrayrefs check_string_arrayref check_hashref check_integer_hashref check_number_hashref check_number_hashrefs check_string_hashref check__mixed_00 check__mixed_01 check__mixed_02 check__mixed_03);

# [[[ OO PROPERTIES ]]]
our hashref $properties = {};

# [[[ OO METHODS ]]]

sub check_class {
    { my void::method $RETURN_TYPE };
    ( my Perl::Types::Test::TypeCheckingOn::AllTypes $self ) = @ARG;

#    Perl::Types::diag('in check_class(), received $self =', "\n", Dumper($self), "\n");
    return;
}

sub check_class_integer {
    { my void::method $RETURN_TYPE };
    ( my Perl::Types::Test::TypeCheckingOn::AllTypes $self, my integer $input_1 ) = @ARG;

#    Perl::Types::diag('in check_class_integer(), received $self =', "\n", Dumper($self), "\n");
#    Perl::Types::diag('in check_class_integer(), received $input_1 = ', $input_1, "\n");
    return;
}

# [[[ SUBROUTINES ]]]

# [[ SCALARS ]]

sub check_integer {
    { my void $RETURN_TYPE };
    ( my integer $input_1) = @ARG;

#    Perl::Types::diag("in check_integer(), received \$input_1\n" . Dumper($input_1) . "\n");
    return;
}

sub check_number {
    { my void $RETURN_TYPE };
    ( my number $input_1) = @ARG;

#    Perl::Types::diag("in check_number(), received \$input_1\n" . Dumper($input_1) . "\n");
    return;
}

sub check_string {
    { my void $RETURN_TYPE };
    ( my string $input_1) = @ARG;

#    Perl::Types::diag("in check_string(), received \$input_1\n" . Dumper($input_1) . "\n");
    return;
}

# [[ ARRAY REFS ]]

sub check_arrayref {
    { my void $RETURN_TYPE };
    ( my arrayref $input_1) = @ARG;

#    Perl::Types::diag("in check_arrayref(), received \$input_1\n" . Dumper($input_1) . "\n");
    return;
}

sub check_integer_arrayref {
    { my void $RETURN_TYPE };
    ( my arrayref::integer $input_1) = @ARG;

#    Perl::Types::diag("in check_integer_arrayref(), received \$input_1\n" . Dumper($input_1) . "\n");
    return;
}

sub check_number_arrayref {
    { my void $RETURN_TYPE };
    ( my arrayref::number $input_1) = @ARG;

#    Perl::Types::diag("in check_number_arrayref(), received \$input_1\n" . Dumper($input_1) . "\n");
    return;
}

sub check_number_arrayrefs {
    { my void $RETURN_TYPE };
    (   my arrayref::number $input_1,
        my arrayref::number $input_2,
        my arrayref::number $input_3)
        = @ARG;

#    Perl::Types::diag("in check_number_arrayrefs(), received \$input_1\n" . Dumper($input_1) . "\n");
#    Perl::Types::diag("in check_number_arrayrefs(), received \$input_2\n" . Dumper($input_2) . "\n");
#    Perl::Types::diag("in check_number_arrayrefs(), received \$input_3\n" . Dumper($input_3) . "\n");

# DEPRECATED: type checking automated via <<< TYPE_CHECKING: CHECK(TRACE) >>> preprocessor directive
#    ::arrayref_number_CHECK($input_1);
#    ::arrayref_number_CHECK($input_2);
#    ::arrayref_number_CHECK($input_3);
    return;
}

sub check_string_arrayref {
    { my void $RETURN_TYPE };
    ( my arrayref::string $input_1) = @ARG;

#    Perl::Types::diag("in check_string_arrayref(), received \$input_1\n" . Dumper($input_1) . "\n");
    return;
}

# [[ HASH REFS ]]

sub check_hashref {
    { my void $RETURN_TYPE };
    ( my hashref $input_1) = @ARG;

#    Perl::Types::diag("in check_hashref(), received \$input_1\n" . Dumper($input_1) . "\n");
    return;
}

sub check_integer_hashref {
    { my void $RETURN_TYPE };
    ( my hashref::integer $input_1) = @ARG;

#    Perl::Types::diag("in check_integer_hashref(), received \$input_1\n" . Dumper($input_1) . "\n");
    return;
}

sub check_number_hashref {
    { my void $RETURN_TYPE };
    ( my hashref::number $input_1) = @ARG;

#    Perl::Types::diag("in check_number_hashref(), received \$input_1\n" . Dumper($input_1) . "\n");
    return;
}

sub check_number_hashrefs {
    { my void $RETURN_TYPE };
    (   my hashref::number $input_1,
        my hashref::number $input_2,
        my hashref::number $input_3)
        = @ARG;

#    Perl::Types::diag("in check_number_hashrefs(), received \$input_1\n" . Dumper($input_1) . "\n");
#    Perl::Types::diag("in check_number_hashrefs(), received \$input_2\n" . Dumper($input_2) . "\n");
#    Perl::Types::diag("in check_number_hashrefs(), received \$input_3\n" . Dumper($input_3) . "\n");
    return;
}

sub check_string_hashref {
    { my void $RETURN_TYPE };
    ( my hashref::string $input_1) = @ARG;

#    Perl::Types::diag("in check_string_hashref(), received \$input_1\n" . Dumper($input_1) . "\n");
    return;
}

# [[ MIXED TYPES ]]

sub check__mixed_00 {
    { my void $RETURN_TYPE };
    ( my integer $input_1, my number $input_2, my string $input_3) = @ARG;

#    Perl::Types::diag("in check__mixed_00(), received \$input_1\n" . Dumper($input_1) . "\n");
#    Perl::Types::diag("in check__mixed_00(), received \$input_2\n" . Dumper($input_2) . "\n");
#    Perl::Types::diag("in check__mixed_00(), received \$input_3\n" . Dumper($input_3) . "\n");
    return;
}

sub check__mixed_01 {
    { my void $RETURN_TYPE };
    (   my arrayref $input_1,
        my arrayref::integer $input_2,
        my arrayref::number $input_3,
        my arrayref::string $input_4)
        = @ARG;

#    Perl::Types::diag("in check__mixed_01(), received \$input_1\n" . Dumper($input_1) . "\n");
#    Perl::Types::diag("in check__mixed_01(), received \$input_2\n" . Dumper($input_2) . "\n");
#    Perl::Types::diag("in check__mixed_01(), received \$input_3\n" . Dumper($input_3) . "\n");
#    Perl::Types::diag("in check__mixed_01(), received \$input_4\n" . Dumper($input_4) . "\n");
    return;
}

sub check__mixed_02 {
    { my void $RETURN_TYPE };
    (   my hashref $input_1,
        my hashref::integer $input_2,
        my hashref::number $input_3,
        my hashref::string $input_4)
        = @ARG;

#    Perl::Types::diag("in check__mixed_02(), received \$input_1\n" . Dumper($input_1) . "\n");
#    Perl::Types::diag("in check__mixed_02(), received \$input_2\n" . Dumper($input_2) . "\n");
#    Perl::Types::diag("in check__mixed_02(), received \$input_3\n" . Dumper($input_3) . "\n");
#    Perl::Types::diag("in check__mixed_02(), received \$input_4\n" . Dumper($input_4) . "\n");
    return;
}

sub check__mixed_03 {
    { my void $RETURN_TYPE };
    (   my integer $input_1,
        my number $input_2,
        my string $input_3,
        my arrayref $input_4,
        my arrayref::integer $input_5,
        my arrayref::number $input_6,
        my arrayref::string $input_7,
        my hashref $input_8,
        my hashref::integer $input_9,
        my hashref::number $input_10,
        my hashref::string $input_11
    ) = @ARG;

#    Perl::Types::diag("in check__mixed_03(), received \$input_1\n" . Dumper($input_1) . "\n");
#    Perl::Types::diag("in check__mixed_03(), received \$input_2\n" . Dumper($input_2) . "\n");
#    Perl::Types::diag("in check__mixed_03(), received \$input_3\n" . Dumper($input_3) . "\n");
#    Perl::Types::diag("in check__mixed_03(), received \$input_4\n" . Dumper($input_4) . "\n");
#    Perl::Types::diag("in check__mixed_03(), received \$input_5\n" . Dumper($input_5) . "\n");
#    Perl::Types::diag("in check__mixed_03(), received \$input_6\n" . Dumper($input_6) . "\n");
#    Perl::Types::diag("in check__mixed_03(), received \$input_7\n" . Dumper($input_7) . "\n");
#    Perl::Types::diag("in check__mixed_03(), received \$input_8\n" . Dumper($input_8) . "\n");
#    Perl::Types::diag("in check__mixed_03(), received \$input_9\n" . Dumper($input_9) . "\n");
#    Perl::Types::diag("in check__mixed_03(), received \$input_10\n" . Dumper($input_10) . "\n");
#    Perl::Types::diag("in check__mixed_03(), received \$input_11\n" . Dumper($input_11) . "\n");
    return;
}

1;    # end of class
