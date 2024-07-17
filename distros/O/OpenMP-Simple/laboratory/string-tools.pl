use strict;
use warnings;
use Inline C => <<'END_C_CODE';

#include <stdlib.h>
#include <string.h>
#include <perl.h>

// Function to convert Perl array of strings to C array
char** array_to_c(SV* array_ref, int* size) {
    AV* array_av = (AV*)SvRV(array_ref);
    I32 num_elements = av_len(array_av) + 1;
    *size = num_elements;
    
    // Allocate memory for C array of char pointers
    char** c_array = (char**)malloc(num_elements * sizeof(char*));
    if (!c_array) {
        croak("Memory allocation failed");
    }
    
    // Copy strings from Perl AV to C array
    for (int i = 0; i < num_elements; i++) {
        SV** elem_ref = av_fetch(array_av, i, 0);
        if (!elem_ref || !SvPOK(*elem_ref)) {
            croak("Invalid array element");
        }
        c_array[i] = SvPV_nolen(*elem_ref);
    }
    
    return c_array;
}

END_C_CODE

# Example Perl array of strings
my @perl_array = ("apple", "banana", "orange", "grape");

# Convert Perl array to C array
my $c_array_ref = array_to_c(\@perl_array);
my $c_array_size = scalar(@perl_array);

# Print the C array
print "C Array:\n";
for (my $i = 0; $i < $c_array_size; $i++) {
    print "$c_array_ref->[$i]\n";
}

# Free the memory allocated for C array
#foreach my $i (0..$c_array_size-1) {
#    free($c_array_ref->[$i]);
#}
#free($c_array_ref);
