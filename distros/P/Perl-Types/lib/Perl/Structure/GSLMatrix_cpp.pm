# [[[ HEADER ]]]
package Perl::Structure::GSLMatrix_cpp;
use strict;
use warnings;
use Perl::Types;
our $VERSION = 0.002_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitStringyEval)  # SYSTEM DEFAULT 1: allow eval()

# [[[ INCLUDES ]]]
use Perl::Inline;

# [[[ SUBROUTINES ]]]
sub cpp_load {
    { my void::method $RETURN_TYPE };
    my $need_load_cpp = 0;
    if (    ( exists $main::{'Perl__Structure__GSLMatrix__MODE_ID'} )
        and ( defined &{ $main::{'Perl__Structure__GSLMatrix__MODE_ID'} } ) )
    {
#        Perl::diag("in GSLMatrix_cpp::cpp_load, Perl__Structure__GSLMatrix__MODE_ID() exists & defined\n");
#        Perl::diag(q{in GSLMatrix_cpp::cpp_load, have Perl__Structure__GSLMatrix__MODE_ID() retval = '} . main::Perl__Structure__GSLMatrix__MODE_ID() . "'\n");
        if ( $Perl::MODES->{main::Perl__Structure__GSLMatrix__MODE_ID()}->{ops} ne 'CPP' ) {
            $need_load_cpp = 1;
        }
    }
    else {
#        Perl::diag("in GSLMatrix_cpp::cpp_load, Perl__Structure__GSLMatrix__MODE_ID() does not exist or undefined\n");
        $need_load_cpp = 1;
    }

    if ($need_load_cpp) {

        #        Perl::diag("in GSLMatrix_cpp::cpp_load, need load CPP code\n");

        my $eval_string = <<"EOF";
package main;
use Perl::Inline;
BEGIN { Perl::diag("[[[ BEGIN 'use Inline' STAGE for 'Perl/Structure/GSLMatrix.cpp' ]]]\n" x 1); }
use Inline (CPP => '$Perl::INCLUDE_PATH' . '/Perl/Structure/GSLMatrix.cpp', \%Perl::Inline::ARGS);
Perl::diag("[[[ END   'use Inline' STAGE for 'Perl/Structure/GSLMatrix.cpp' ]]]\n" x 1);
1;
EOF

        $Perl::Inline::ARGS{ccflagsex} = $Perl::Inline::CCFLAGSEX . $Perl::TYPES_CCFLAG . perltypessizes::type_integer_native_ccflag() . perltypessizes::type_number_native_ccflag();
        $Perl::Inline::ARGS{cppflags} = $Perl::TYPES_CCFLAG . perltypessizes::type_integer_native_ccflag() . perltypessizes::type_number_native_ccflag();
        $Perl::Inline::ARGS{libs}         = '-lgsl';                                                                   # enable GSL support
        $Perl::Inline::ARGS{inc}         .= ' -I' . $Perl::Inline::gsl_include_dir;                                   # enable GSL support
        $Perl::Inline::ARGS{auto_include} = [ @{ $Perl::Inline::ARGS{auto_include} }, '#include <gsl_matrix.h>' ];    # enable GSL support
        
#        Perl::diag("in GSLMatrix_cpp::cpp_load(), CPP not yet loaded, about to call eval() on \$eval_string =\n<<< BEGIN EVAL STRING>>>\n" . $eval_string . "<<< END EVAL STRING >>>\n");
#        Perl::diag("in GSLMatrix_cpp::cpp_load(), CPP not yet loaded, have \%Perl::Inline::ARGS =\n" . Dumper(\%Perl::Inline::ARGS) . "\n");
#        Perl::diag("in GSLMatrix_cpp::cpp_load(), CPP not yet loaded, have \$Perl::TYPES_CCFLAG = '" . $Perl::TYPES_CCFLAG . "'\n");

        eval $eval_string or croak( $OS_ERROR . "\n" . $EVAL_ERROR );
        if ($EVAL_ERROR) { croak($EVAL_ERROR); }
    }

#    else { Perl::diag("in GSLMatrix_cpp::cpp_load(), CPP already loaded, DOING NOTHING\n"); }
    return;
}

1;  # end of package
