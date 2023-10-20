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
    skip qq{GCC compiler version $gccversion doesn't support 'omp_set_num_teams'.}, 8 unless $gccversion lt q{12.31};
    note qq{Testing macro provided by OpenMP::Simple, 'PerlOMP_ENV_SET_NUM_TEAMS'};
    for my $num_teams ( 1 .. 8 ) {
        my $current_value = $env->omp_num_teams($num_teams);
        is _get_num_teams(), $num_teams, sprintf qq{The number of threads (%0d) spawned in the OpenMP runtime via OMP_NUM_TEAMS, as expected}, $num_teams;
    }
}

__DATA__
__C__
int _get_num_teams() {
  PerlOMP_ENV_SET_NUM_TEAMS
  int ret = 0;
  #pragma omp parallel
  {
    #pragma omp single
    ret = omp_get_num_teams(); 
  }
  return ret;
}

__END__
