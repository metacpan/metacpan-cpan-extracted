# [[[ HEADER ]]]
package Perl::HelperFunctions_cpp;
use strict;
use warnings;
use Perl::Config; # get Carp, English, $Perl::INCLUDE_PATH without 'use RPerl;'

#use RPerl;  # DEV NOTE: need to use HelperFunctions in Perl::Structure::Array for type checking SvIOKp() etc; remove dependency on RPerl void::method type so HelperFunctions can be loaded by RPerl type system
our $VERSION = 0.007_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitStringyEval)  # SYSTEM DEFAULT 1: allow eval()

# [[[ INCLUDES ]]]
use Perl::Inline;
use perltypessizes;  # get type_integer_native_ccflag() & type_number_native_ccflag() w/out loading the entire Perl type system via 'use perltypes;'

# [[[ SUBROUTINES ]]]
sub cpp_load {
#    { my void::method $RETURN_TYPE };
    my $need_load_cpp = 0;

    if (    ( exists $main::{'Perl__HelperFunctions__MODE_ID'} )
        and ( defined &{ $main::{'Perl__HelperFunctions__MODE_ID'} } ) )
    {
#        Perl::diag("in HelperFunctions_cpp::cpp_load, Perl__HelperFunctions__MODE_ID() exists & defined\n");
#        Perl::diag(q{in HelperFunctions_cpp::cpp_load, have Perl__HelperFunctions__MODE_ID() retval = '} . main::Perl__HelperFunctions__MODE_ID() . "'\n");
        if ( $Perl::MODES->{ main::Perl__HelperFunctions__MODE_ID() }->{ops} ne 'CPP' )
        {
            $need_load_cpp = 1;
        }
    }
    else {
#        Perl::diag("in HelperFunctions_cpp::cpp_load, Perl__HelperFunctions__MODE_ID() does not exist or undefined\n");
        $need_load_cpp = 1;
    }

    # DEV NOTE, CORRELATION #rp040: fix recursive dependencies of String.pm & HelperFunctions_cpp.pm, as triggered by ingy's Inline::create_config_file() system() call
    if ((exists $ARGV[0]) and (defined $ARGV[0]) and ((substr $ARGV[0], -7, 7) eq '_Inline')) {
#        Perl::diag("in HelperFunctions_cpp::cpp_load, Inline recursion detected, SKIPPING\n");
        1;
    }
    elsif ($need_load_cpp) {
#        Perl::diag("in HelperFunctions_cpp::cpp_load, need load CPP code\n");

#BEGIN { Perl::diag("[[[ BEGIN 'use Inline' STAGE for 'Perl/HelperFunctions.cpp' ]]]\n" x 1); }
        my $eval_string = <<"EOF";
package main;
use Perl::Inline;
BEGIN { Perl::diag("[[[ BEGIN 'use Inline' STAGE for 'Perl/HelperFunctions.cpp' ]]]\n" x 1); }
# DEV NOTE, CORRELATION #rp040: fix recursive dependencies of String.pm & HelperFunctions_cpp.pm, as triggered by ingy's Inline::create_config_file() system() call
#BEGIN { \$DB::single = 1; }
use Inline (CPP => '$Perl::INCLUDE_PATH' . '/Perl/HelperFunctions.cpp', \%Perl::Inline::ARGS);
Perl::diag("[[[ END   'use Inline' STAGE for 'Perl/HelperFunctions.cpp' ]]]\n" x 1);
1;
EOF

        $Perl::Inline::ARGS{ccflagsex} = $Perl::Inline::CCFLAGSEX . $Perl::TYPES_CCFLAG . perltypessizes::type_integer_native_ccflag() . perltypessizes::type_number_native_ccflag();
        $Perl::Inline::ARGS{cppflags} = $Perl::TYPES_CCFLAG . perltypessizes::type_integer_native_ccflag() . perltypessizes::type_number_native_ccflag();

#        Perl::diag("in HelperFunctions_cpp::cpp_load(), CPP not yet loaded, have \%Perl::Inline::ARGS =\n" . Dumper(\%Perl::Inline::ARGS) . "\n");
#        Perl::diag("in HelperFunctions_cpp::cpp_load(), CPP not yet loaded, about to call eval() on \$eval_string =\n<<< BEGIN EVAL STRING>>>\n" . $eval_string . "<<< END EVAL STRING >>>\n");

        eval $eval_string or croak( $OS_ERROR . "\n" . $EVAL_ERROR );
        if ($EVAL_ERROR) { croak($EVAL_ERROR); }

#Perl::diag("[[[ END   'use Inline' STAGE for 'Perl/HelperFunctions.cpp' ]]]\n" x 1);
        $Perl::HelperFunctions_cpp::LOADING = 0;
    }

#	else { Perl::diag("in HelperFunctions_cpp::cpp_load(), CPP already loaded, DOING NOTHING\n"); }
}

1;
