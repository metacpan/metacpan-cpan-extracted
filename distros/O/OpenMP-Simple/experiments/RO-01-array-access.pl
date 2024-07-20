use strict;
use warnings;

use OpenMP::Simple;
use OpenMP::Environment;

my $env = OpenMP::Environment->new;

$env->omp_num_threads(shift @ARGV // 16);

use Inline (
    C    => 'DATA',
    with => 'OpenMP::Simple',
);

# Example Perl array
my @array = (1 .. 128);
my $sum = _access_array_element(\@array);

print "sum: $sum\n";

# Inline C code section
__DATA__
__C__

/* Function to access array element by index with OpenMP parallelization */
int _access_array_element(SV* array_ref) {
  PerlOMP_UPDATE_WITH_ENV__NUM_THREADS      // ... create a start bundle, "PerlOMP_Init"

  AV* array_av  = (AV*)SvRV(array_ref);
  int last_idx  = av_len(array_av);
  int value, sum;

  // OpenMP parallel for loop to access array elements

  #pragma omp parallel for shared(array_av) private(value) reduction(+:sum)
  for (int i = 0; i <= last_idx; i++) {
    SV** elem_ref = av_fetch(array_av, i, 0);
    if (elem_ref && *elem_ref) {
      value = SvIV(*elem_ref);     // Convert SV to integer value
      sum += value;
      //printf("(tid %02d): %d\n", omp_get_thread_num(), value);
    }
  }

  return sum;
}
