use strict;
use warnings;

# OMP_CANCELLATION must be set in the BEGIN block before the shared library created
# by Inline::C with OpenMP::Simple is loaded, because the OpenMP specification doesn't
# mention a runtime method for setting this value. As a result, no compiler will implement
# it. Note, this will work as expected if the OpenMP code has been compiled into a separate
# executable that is called from a Perl script via C<system(...)> or the like; provided
# %ENV{OMP_CANCELLATION} is set as desired (which is what OpenMP::Environment is for).
BEGIN {
  use OpenMP::Environment;
  my $env = OpenMP::Environment->new;
  my $current_value = $env->omp_cancellation(q{TRUE});
}

use Test::More tests => 2;
use OpenMP::Simple;

use Inline (
    C                 => 'DATA',
    with              => qw/OpenMP::Simple/,
);

my $env = OpenMP::Environment->new;
note qq{Testing OMP_CANCELLATION is readable in an Inline::C'd subroutine.};
is _get_cancellation(), 1, sprintf qq{The cancellation policy gotten by the runtime function omp_get_cancellation() is 1 (ON) as expected};
is $env->omp_cancellation(), q{TRUE}, sprintf qq{The cancellation policy gotten by OpenMP::Environemnt is "TRUE" (ON) as expected};

__DATA__
__C__
int _get_cancellation() {
  int ret = 0;
  #pragma omp parallel
  {
    #pragma omp single
    ret = omp_get_cancellation();
  }
  return ret;
}

__END__
