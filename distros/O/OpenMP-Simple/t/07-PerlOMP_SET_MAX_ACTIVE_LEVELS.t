use strict;
use warnings;

use OpenMP::Simple;
use OpenMP::Environment;
use Test::More tests => 8;

use Inline (
    C    => 'DATA',
    with => qw/OpenMP::Simple/,
);

my $env = OpenMP::Environment->new;

note qq{Testing macro provided by OpenMP::Simple, 'PerlOMP_ENV_SET_MAX_ACTIVE_LEVELS'};
for my $max_active_levels ( 1 .. 8 ) {
    my $current_value = $env->omp_max_active_levels($max_active_levels);
    is _get_max_active_levels(), $max_active_levels, sprintf qq{The number of threads (%0d) spawned in the OpenMP runtime via OMP_MAX_ACTIVE_LEVELS, as expected}, $max_active_levels;
}

__DATA__
__C__
int _get_max_active_levels() {
  PerlOMP_ENV_SET_MAX_ACTIVE_LEVELS
  int ret = 0;
  #pragma omp parallel
  {
    #pragma omp single
    ret = omp_get_max_active_levels(); 
  }
  return ret;
}

__END__
