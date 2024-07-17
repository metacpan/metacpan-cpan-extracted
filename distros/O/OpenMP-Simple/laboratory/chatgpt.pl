use Inline C => <<'END_C';

void access_perl_array(SV* perl_array_ref) {
    AV* array = (AV*)SvRV(perl_array_ref); // Convert the reference to an array
    int size = av_len(array) + 1; // Get the size of the array
    
    // Accessing elements of the array
    for (int i = 0; i < size; i++) {
        SV** elem = av_fetch(array, i, 0);
        if (elem != NULL) {
            SV* value = *elem;
            printf("Element %d: %s\n", i, SvPV_nolen(value));
        }
    }
}

END_C

# Example usage
my @perl_array = ("apple", "banana", "cherry");
access_perl_array(\@perl_array);

use Inline C => <<'END_C';

void iterate_perl_hash(HV* perl_hash) {
    printf("Iterating Perl Hash:\n");

    // Get the hash's key-value pairs
    I32 hv_iter = hv_iterinit(perl_hash);
    HE* entry;
    while ((entry = hv_iternext(perl_hash))) {
        SV* key_sv = hv_iterkeysv(entry);
        SV* value_sv = hv_iterval(perl_hash, entry);

        // Convert Perl SVs to C strings for printing
        const char* key = SvPV_nolen(key_sv);
        const char* value = SvPV_nolen(value_sv);

        printf("Key: %s, Value: %s\n", key, value);
    }
}

END_C

# Example usage
my %perl_hash = (
    'name' => 'John Doe',
    'age' => 30,
    'is_student' => 1
);
iterate_perl_hash(\%perl_hash);

use Inline C => <<'END_C';
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

void iterate_perl_hash(HV* perl_hash);

void iterate_perl_hash_rec(SV* key_sv, SV* value_sv) {
  if (SvTYPE(value_sv) == SVt_PVHV) { // Check if value is a hash reference
    HV* nested_hash = (HV*)SvRV(value_sv);
    iterate_perl_hash(nested_hash);
  }
  else {
    const char* key = SvPV_nolen(key_sv);
    const char* value = SvPV_nolen(value_sv);
    printf("Key: %s, Value: %s\n", key, value);
  }
}

void iterate_perl_hash(HV* perl_hash) {
  printf("Iterating Perl Hash:\n");
  // Get the hash's key-value pairs
  I32 hv_iter = hv_iterinit(perl_hash);
  HE* entry;
  while ((entry = hv_iternext(perl_hash))) {
    SV* key_sv = hv_iterkeysv(entry);
    SV* value_sv = hv_iterval(perl_hash, entry);
    iterate_perl_hash_rec(key_sv, value_sv);
  }
}
END_C

# Example usage
my %nested_hash = (
    'name' => 'John Doe',
    'details' => {
        age        => 30,
        occupation => 'Engineer',
        foo        => 1,
    },
    'address' => '123 Main St'
);
iterate_perl_hash(\%nested_hash);
