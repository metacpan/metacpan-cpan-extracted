# [[[ HEADER ]]]
package Perl::Type::FileHandle;
use strict;
use warnings;
use Perl::Config;  # don't use Perl::Types inside itself, in order to avoid circular includes
our $VERSION = 0.006_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case package names

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Type);
use Perl::Type;

# [[[ SUB-TYPES BEFORE SETUP ]]]

# "If FILEHANDLE -- the first argument in a call to open -- is an undefined scalar variable
# (or array or hash element), a new filehandle is autovivified, meaning that the variable is assigned
# a reference to a newly allocated anonymous filehandle."
# https://perldoc.perl.org/functions/open#Direct-versus-by-reference-assignment-of-filehandles

package filehandleref;
use strict;
use warnings;
use parent -norequire, qw(ref);

# "Otherwise if FILEHANDLE is an expression, its value is the real filehandle.
# (This is considered a symbolic reference, so use strict "refs" should not be in effect.)"
# https://perldoc.perl.org/functions/open#Direct-versus-by-reference-assignment-of-filehandles

package filehandle;
use strict;
use warnings;
use parent qw(Perl::Type::FileHandle);

# [[[ SWITCH CONTEXT BACK TO PRIMARY PACKAGE ]]]
package Perl::Type::FileHandle;
use strict;
use warnings;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Type);
use Perl::Type;

# NEED FIX: is a filehandleref really an integer?!?

# [[[ TYPE-CHECKING ]]]
sub filehandleref_CHECK {
    { my void $RETURN_TYPE };
    ( my $possible_filehandleref ) = @ARG;
    if ( not( defined $possible_filehandleref ) ) {
#        croak( "\nERROR EFH00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nfilehandleref value expected but undefined/null value found,\ncroaking" );
        die( "\nERROR EFH00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nfilehandleref value expected but undefined/null value found,\ndying\n" );
    }
    if ( not( main::PerlTypes_SvIOKp($possible_filehandleref) ) ) {
#        croak( "\nERROR EFH01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nfilehandleref value expected but non-filehandleref value found,\ncroaking" );
        die( "\nERROR EFH01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nfilehandleref value expected but non-filehandleref value found,\ndying\n" );
    }
    return;
}

sub filehandleref_CHECKTRACE {
    { my void $RETURN_TYPE };
    ( my $possible_filehandleref, my $variable_name, my $subroutine_name ) = @ARG;
    if ( not( defined $possible_filehandleref ) ) {
#        croak( "\nERROR EFH00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nfilehandleref value expected but undefined/null value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        die( "\nERROR EFH00, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nfilehandleref value expected but undefined/null value found,\nin variable $variable_name from subroutine $subroutine_name,\ndying\n" );
    }
    if ( not( main::PerlTypes_SvIOKp($possible_filehandleref) ) ) {
#        croak( "\nERROR EFH01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nfilehandleref value expected but non-filehandleref value found,\nin variable $variable_name from subroutine $subroutine_name,\ncroaking" );
        die( "\nERROR EFH01, TYPE-CHECKING MISMATCH, PERLOPS_PERLTYPES:\nfilehandleref value expected but non-filehandleref value found,\nin variable $variable_name from subroutine $subroutine_name,\ndying\n" );
    }
    return;
}

# DEV NOTE, CORRELATION #rp018: Perl::Type::*.pm files do not 'use RPerl;' and thus do not trigger the pseudo-source-filter contained in
# RPerl::CompileUnit::Module::Class::create_symtab_entries_and_accessors_mutators(),
# so *__MODE_ID() subroutines are hard-coded here instead of auto-generated there
package main;
use strict;
use warnings;
sub Perl__Type__FileHandle__MODE_ID { return 0; }

1;  # end of class
