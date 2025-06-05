## no critic qw(ProhibitUselessNoCritic PodSpelling ProhibitExcessMainComplexity)  # DEVELOPER DEFAULT 1a: allow unreachable & POD-commented code; SYSTEM SPECIAL 4: allow complex code outside subroutines, must be on line 1
package Perl::Structure::Array::SubTypes;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.017_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(ProhibitUnreachableCode RequirePodSections RequirePodAtEnd)  # DEVELOPER DEFAULT 1b: allow unreachable & POD-commented code, must be after line 1
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names

# [[[ EXPORTS ]]]
# DEV NOTE, CORRELATION #rp051: hard-coded list of RPerl data types and data structures
use Exporter 'import';
our @EXPORT = qw(
    arrayref_CHECK
    arrayref_CHECKTRACE
);
our @EXPORT_OK = qw();

# [[[ ARRAY ]]]
# [[[ ARRAY ]]]
# [[[ ARRAY ]]]

# an array is a 1-dimensional list/vector/sequence/set of data types;
# we never use this type directly, instead we always use the arrayref type,
# per LMPC #27: Thou Shalt Not Use Direct Access To Arrays & Hashes Stored In @ Or % Non-Scalar Variables
package array;
use strict;
use warnings;
use parent qw(Perl::Structure::Array);

# [[[ ARRAY REF ]]]
# [[[ ARRAY REF ]]]
# [[[ ARRAY REF ]]]

# ref to array
package arrayref;
use strict;
use warnings;
#use parent -norequire, qw(ref);  # NEED REMOVE: properly replaced by line below?
use parent -norequire, qw(Perl::Structure::Array::Reference);
use Carp;

# [[[ SWITCH CONTEXT BACK TO PRIMARY PACKAGE FOR EXPORT TO WORK ]]]
package Perl::Structure::Array::SubTypes;
use strict;
use warnings;

# [[[ TYPE-CHECKING ]]]

sub arrayref_CHECK {
    { my void $RETURN_TYPE };
    ( my $possible_arrayref ) = @ARG;
    if ( not( defined $possible_arrayref ) ) {
        croak( "\nERROR EAVRV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\narrayref value expected but undefined/null value found,\ncroaking" );
    }

#    if ( UNIVERSAL::isa( $possible_arrayref, 'ARRAY' ) ) {  # DEV NOTE: I believe these 2 lines are equivalent?
    if ( not( main::PerlTypes_SvAROKp($possible_arrayref) ) ) {
        croak( "\nERROR EAVRV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\narrayref value expected but non-arrayref value found,\ncroaking" );
    }
    return;
}

sub arrayref_CHECKTRACE {
    { my void $RETURN_TYPE };
    ( my $possible_arrayref, my $variable_name, my $subroutine_name ) = @ARG;
    if ( not( defined $possible_arrayref ) ) {
        croak( "\nERROR EAVRV00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\narrayref value expected but undefined/null value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
    }
    if ( not( main::PerlTypes_SvAROKp($possible_arrayref) ) ) {
        croak( "\nERROR EAVRV01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\narrayref value expected but non-arrayref value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
    }
    return;
}

1;  # end of package
