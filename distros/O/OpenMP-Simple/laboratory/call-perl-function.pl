use strict;
use warnings;

use strict;
use warnings;

use OpenMP::Simple;
use OpenMP::Environment;

use Inline (
    C                 => 'DATA',
    with              => qw/OpenMP::Simple/,
);

my $env = OpenMP::Environment->new();
$env->omp_num_threads(1);

# Example Perl subroutine
sub perl_subroutine {
    return "Hello from Perl!";
}

# Call the C function with the Perl subroutine reference
call_perl_sub(\&perl_subroutine);

__END__
__C__
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

// C function to call a Perl subroutine
void call_perl_sub(SV* sub_ref) {
    // Check if the passed SV is a reference to a subroutine
    if (!SvROK(sub_ref) || SvTYPE(SvRV(sub_ref)) != SVt_PVCV) {
        croak("Argument is not a reference to a subroutine");
    }

    // Prepare for calling the Perl subroutine
    dTHX;
    dSP;
    PUSHMARK(SP); // Push the stack marker

    // Push the subroutine reference onto the stack
    XPUSHs(sub_ref);

    // Call the subroutine
    PUTBACK;
    call_sv(sub_ref, G_SCALAR);

    // Get the return value
    SPAGAIN;
    SV* retval = POPs;

    // Print the return value
    printf("Return value from Perl subroutine: %s\n", SvPV_nolen(retval));
}
