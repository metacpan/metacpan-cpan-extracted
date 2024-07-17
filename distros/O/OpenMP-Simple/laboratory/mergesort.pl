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

my @animals = (
    "elephant", "lion", "tiger", "giraffe", "zebra", "cheetah", "hippopotamus", "rhinoceros", "crocodile", "monkey",
    "gorilla", "chimpanzee", "koala", "kangaroo", "panda", "wolf", "fox", "bear", "polar bear", "grizzly bear",
    "penguin", "seal", "walrus", "dolphin", "whale", "shark", "octopus", "squid", "jellyfish", "starfish", "turtle",
    "frog", "toad", "salmon", "trout", "eel", "lobster", "crab", "shrimp", "snail", "slug", "worm", "ant", "bee",
    "wasp", "butterfly", "dragonfly", "grasshopper", "ladybug", "armadillo", "porcupine", "badger", "skunk", "otter",
    "beaver", "squirrel", "chipmunk", "rabbit", "hare", "hamster", "gerbil", "guinea pig", "mouse", "rat", "vole",
    "bat", "weasel", "ferret", "mink", "cat", "dog", "horse", "donkey", "mule", "pony", "goat", "sheep", "pig",
    "cow", "bull", "buffalo", "bison", "deer", "moose", "elk", "caribou", "gazelle", "antelope", "impala", "ibex",
    "chamois", "mountain goat", "camel", "llama", "alpaca", "vicuna", "giraffe", "elephant seal", "anteater", "tapir",
    "okapi", "bison", "buffalo", "gnu", "oryx", "yak", "zebu", "warthog", "wild boar", "peccary", "wombat", "koala",
    "kangaroo", "wallaby", "opossum", "numbat", "quokka", "bilby", "kookaburra", "platypus", "echidna", "tasmanian devil",
    "kiwi", "emu", "cassowary", "ostrich", "vulture", "condor", "eagle", "hawk", "falcon", "osprey", "kite", "harrier",
    "buzzard", "turkey", "chicken", "pheasant", "quail", "partridge", "dove", "pigeon", "seagull", "pelican", "cormorant",
    "heron", "egret", "ibis", "stork", "flamingo", "spoonbill", "duck", "goose", "swan", "crane", "rail", "coot", "moorhen",
    "gallinule", "snipe", "woodcock", "sandpiper", "curlew", "godwit", "turnstone", "avocet", "lapwing", "phalarope",
    "jacana", "skimmer", "gull", "tern", "petrel", "albatross", "penguin", "puffin", "auk", "dipper", "wren", "warbler",
    "thrush", "robin", "flycatcher", "shrike", "vireo", "finch", "bunting", "sparrow", "blackbird", "starling", "oriole",
    "grackle", "cowbird", "cuckoo", "kingfisher", "woodpecker", "nuthatch", "titmouse", "creeper", "waxwing", "jay",
    "magpie", "crow", "raven", "parrot", "cockatoo", "lorikeet", "lovebird", "macaw", "pigeon", "dodo", "quagga"
);

my $sorted_array_ref = mergesort(\@animals);

print "Sorted array: @$sorted_array_ref\n";


__DATA__
__C__

#include <stdlib.h>
#include <string.h>
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

// Function to merge two sorted arrays
void merge(char **arr, int l, int m, int r) {
    PerlOMP_UPDATE_WITH_ENV__NUM_THREADS

    int i, j, k;
    int n1 = m - l + 1;
    int n2 = r - m;

    // Create temporary arrays
    char *L[n1], *R[n2];

    // Copy data to temporary arrays L[] and R[]
    for (i = 0; i < n1; i++)
        L[i] = arr[l + i];
    for (j = 0; j < n2; j++)
        R[j] = arr[m + 1 + j];

    // Merge the temporary arrays back into arr[l..r]
    i = 0;
    j = 0;
    k = l;
    for (; i < n1 && j < n2; k++) {
        if (strcmp(L[i], R[j]) <= 0) {
            arr[k] = L[i];
            i++;
        } else {
            arr[k] = R[j];
            j++;
        }
    }

    // Copy the remaining elements of L[], if any
    for (; i < n1; i++, k++) {
        arr[k] = L[i];
    }

    // Copy the remaining elements of R[], if any
    for (; j < n2; j++, k++) {
        arr[k] = R[j];
    }
}

// Main function to implement mergesort
void merge_sort(char **arr, int l, int r) {
    if (l < r) {
        // Same as (l+r)/2, but avoids overflow for large l and r
        int m = l + (r - l) / 2;

        // Sort first and second halves
        merge_sort(arr, l, m);
        merge_sort(arr, m + 1, r);

        // Merge the sorted halves
        merge(arr, l, m, r);
    }
}

// Function to copy C array of strings to Perl array
AV* copy_to_perl_array(char **arr, int size) {
    AV* result = newAV();
    for (int i = 0; i < size; i++) {
        av_push(result, newSVpv(arr[i], 0));
    }
    return result;
}

// Perl XS subroutine to call mergesort C function and return sorted array
SV* mergesort(SV* array_ref) {
    AV* array_av = (AV*)SvRV(array_ref); // Dereference the Perl array reference
    int num_elements = av_len(array_av) + 1; // Number of elements in the array

    // Allocate memory for array of C strings
    char** array = (char**)malloc(num_elements * sizeof(char*));

    // Extract strings from Perl array and store in array of C strings
    for (int i = 0; i < num_elements; i++) {
        SV** elem_ref = av_fetch(array_av, i, 0);
        if (elem_ref && *elem_ref && SvPOK(*elem_ref)) {
            array[i] = SvPV_nolen(*elem_ref);
        }
    }

    // Call the C function to sort the array
    merge_sort(array, 0, num_elements - 1);

    // Convert sorted array of C strings back to Perl array
    AV* sorted_array_av = copy_to_perl_array(array, num_elements);

    // Free memory allocated for array of C strings
    free(array);

    // Return the sorted Perl array
    return newRV_noinc((SV*)sorted_array_av);
}
