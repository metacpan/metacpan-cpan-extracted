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

note qq{Testing macro provided by OpenMP::Simple, 'PerlOMP_ENV_SET_NESTED'};

$env->omp_nested(1);
is _get_nested(), 1, sprintf qq{OMP_NESTED is set as 1, is 1 (on), as expected};

$env->omp_nested(0);
is _get_nested(), 0, sprintf qq{OMP_NESTED is set as 0, is 0 (off), as expected};

$env->omp_nested('true');
is _get_nested(), 1, sprintf qq{OMP_NESTED is set as 'true', is 1 (on), as expected};

$env->omp_nested('false');
is _get_nested(), 0, sprintf qq{OMP_NESTED is set as 'false', is 0 (off), as expected};

$env->omp_nested('TRUE');
is _get_nested(), 1, sprintf qq{OMP_NESTED is set as 'TRUE', is 1 (on), as expected};

$env->omp_nested('FALSE');
is _get_nested(), 0, sprintf qq{OMP_NESTED is set as 'FALSE', is 0 (off), as expected};

__DATA__
__C__
int _get_nested() {
  PerlOMP_ENV_SET_NESTED
  int ret = 0;
  #pragma omp parallel
  {
    #pragma omp single
    {
      ret = (omp_get_nested()) ? 1 : 0;
    }
  }
  return ret;
}

__END__
