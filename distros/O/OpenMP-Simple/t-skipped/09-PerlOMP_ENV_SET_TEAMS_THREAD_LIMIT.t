use strict;
use warnings;

use OpenMP::Simple;
use OpenMP::Environment;
use Config;
use Test::More tests => 8;

use Inline (
    C    => 'DATA',
    with => qw/OpenMP::Simple/,
);

my $env = OpenMP::Environment->new;

$Config{gccversion} =~ m/(\d+\.\d+)/;
my $gccversion = $1 // 0.00;

SKIP: {
    skip qq{GCC compiler version $gccversion doesn't support 'omp_set_teams_thread_limit'.}, 8 unless $gccversion lt q{12.31};
    note qq{Testing macro provided by OpenMP::Simple, 'PerlOMP_ENV_SET_TEAMS_THREAD_LIMIT'};
    for my $teams_thread_limit( 1 .. 8 ) {
        my $current_value = $env->omp_teams_thread_limit($teams_thread_limit);
        is _get_teams_thread_limit(), $teams_thread_limit, sprintf qq{The number of threads (%0d) spawned in the OpenMP runtime via OMP_NUM_TEAMS, as expected}, $teams_thread_limit;
    }
}

__DATA__
__C__
int _get_teams_thread_limit() {
  PerlOMP_ENV_SET_TEAMS_THREAD_LIMIT
  int ret = 0;
  #pragma omp parallel
  {
    #pragma omp single
    ret = omp_get_teams_thread_limit(); 
  }
  return ret;
}

__END__
