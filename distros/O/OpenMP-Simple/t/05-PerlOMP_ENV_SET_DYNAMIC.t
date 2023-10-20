use strict;
use warnings;

use OpenMP::Simple;
use OpenMP::Environment;
use Test::More tests => 6;

use Inline (
    C    => 'DATA',
    with => qw/OpenMP::Simple/,
);

my $env = OpenMP::Environment->new;

note qq{Testing macro provided by OpenMP::Simple, 'PerlOMP_ENV_SET_DYNAMIC'};

$env->omp_dynamic(1);
is _get_dynamic(), 1, sprintf qq{OMP_DYNAMIC is set as 1, is 1 (on), as expected};

$env->omp_dynamic(0);
is _get_dynamic(), 0, sprintf qq{OMP_DYNAMIC is set as 0, is 0 (off), as expected};

$env->omp_dynamic('true');
is _get_dynamic(), 1, sprintf qq{OMP_DYNAMIC is set as 'true', is 1 (on), as expected};

$env->omp_dynamic('false');
is _get_dynamic(), 0, sprintf qq{OMP_DYNAMIC is set as 'false', is 0 (off), as expected};

$env->omp_dynamic('TRUE');
is _get_dynamic(), 1, sprintf qq{OMP_DYNAMIC is set as 'TRUE', is 1 (on), as expected};

$env->omp_dynamic('FALSE');
is _get_dynamic(), 0, sprintf qq{OMP_DYNAMIC is set as 'FALSE', is 0 (off), as expected};

__DATA__
__C__
int _get_dynamic() {
  PerlOMP_ENV_SET_DYNAMIC
  int ret = 0;
  #pragma omp parallel
  {
    #pragma omp single
    {
      ret = (omp_get_dynamic()) ? 1 : 0;
    }
  }
  return ret;
}

__END__
