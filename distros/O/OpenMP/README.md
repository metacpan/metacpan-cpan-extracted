This is a metapackage for using OpenMP and Perl.

```perl
#!/usr/bin/env perl
use strict;
use warnings;
   
use OpenMP;
   
use Inline (
    C    => 'DATA',
    with => qw/OpenMP::Simple/,
);
   
my $omp = OpenMP->new;
   
for my $want_num_threads ( 1 .. 8 ) {
    $omp->env->omp_num_threads($want_num_threads);
 
    $omp->env->assert_omp_environment; # (optional) validates %ENV
 
    # call parallelized C function
    my $got_num_threads = _check_num_threads();
 
    printf "%0d threads spawned in ".
            "the OpenMP runtime, expecting %0d\n",
              $got_num_threads, $want_num_threads;
}
   
__DATA__
__C__
 
/* C function parallelized with OpenMP */
int _check_num_threads() {
  int ret = 0;
 
  PerlOMP_UPDATE_WITH_ENV__NUM_THREADS /* <~ MACRO x OpenMP::Simple */
 
  #pragma omp parallel
  {
    #pragma omp single
    ret = omp_get_num_threads();
  }
 
  return ret;
}

__END__
```
