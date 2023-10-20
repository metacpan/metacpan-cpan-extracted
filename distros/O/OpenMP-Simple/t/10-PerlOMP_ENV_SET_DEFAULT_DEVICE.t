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

note qq{Testing macro provided by OpenMP::Simple, 'PerlOMP_ENV_SET_DEFAULT_DEVICE'};
for my $default_device ( 1 .. 8 ) {
    my $current_value = $env->omp_default_device($default_device);
    is _get_default_device(), $default_device, sprintf qq{The number of threads (%0d) spawned in the OpenMP runtime via OMP_DEFAULT_DEVICE, as expected}, $default_device;
}

__DATA__
__C__
int _get_default_device() {
  PerlOMP_ENV_SET_DEFAULT_DEVICE
  int ret = 0;
  #pragma omp parallel
  {
    #pragma omp single
    ret = omp_get_default_device();
  }
  return ret;
}

__END__
