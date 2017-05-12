# Perl
#
# Example of Scalar::Validation, named access by npar
#
# Ralf Peine, Sat Jul 12 12:49:47 2014

$| = 1;

use strict;
use warnings;

use Scalar::Validation qw (:all);

sub named {
    my $trouble_level = p_start;

    # --- safe creation of hash from arguments ---------------------
    my %parameters = convert_to_named_params \@_;

    # --- scan parameters ------------------------------
    my $p_int   = npar -p_int   => Int   => \%parameters;
    my $p_float = npar -p_float => Float => \%parameters;

    # --- something left in parameters ? ---
    p_end \%parameters;

    # --- stop if still running and some validations have failed ---
    return undef if validation_trouble $trouble_level; 

    # --- run sub -------------------------------------------------
    print  "named (-p_int => $p_int , -p_float => $p_float)\n";
}

print "\n# --- calls with valid args ---\n\n";

named (-p_int => 1, -p_float => 1);
named (-p_int => 3, -p_float => 3.14159);

print "\n# --- calls with invalid args enclosed by eval { } ---\n\n";

eval { named         }; print $@;
eval { named ()      }; print $@;
eval { named -p_int => 1                    }; print $@;
eval { named -p_int => 1.2, -p_float => 5   }; print $@;
eval { named -p_int => 1,   -p_float => 'a' }; print $@;

eval { named -p_int => 1,   -p_float => 1, -p_3 => 2 }; print $@;

print "\n# --- Ready. ---\n";
