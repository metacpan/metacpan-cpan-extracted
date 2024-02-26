use strict;
use warnings;

use OpenMP::Simple;
use OpenMP::Environment;
use Util::H2O::More qw/ddd h2o/;
use Test::More;

use Inline (
    C                 => 'DATA',
    with              => qw/OpenMP::Simple/,
);

my $env = OpenMP::Environment->new;

note qq{Testing macro provided by OpenMP::Simple, 'PerlOMP_UPDATE_WITH_ENV__NUM_THREADS'};

# generate schedule value look up
my $schedules = {};
foreach my $sched (qw/static dynamic guided auto/) {
  $schedules->{$sched} = _omp_sched_t_to_int($sched);
}
h2o $schedules;

foreach my $sched (qw/static dynamic guided auto/) {
  foreach my $chunk (qw/1 10 100 1000 10000/) {
    my $current_value = $env->omp_schedule(qq{$sched,$chunk});
    note $current_value;
    _set_schedule_with_macro();
    my $set_schedule = _get_schedule();
    is $set_schedule, $schedules->$sched, sprintf qq{Schedule '%s' set in the OpenMP runtime, as expected.}, $sched;
    my $set_chunk = _get_chunk(); 
    is $chunk, $set_chunk, sprintf qq{Chunk size '% 5d' set in the OpenMP runtime, as expected.}, $set_chunk;
  }
}

done_testing;

__DATA__
__C__
void _set_schedule_with_macro() {
  PerlOMP_UPDATE_WITH_ENV__SCHEDULE
}

int _get_schedule() {
  omp_sched_t *sched;
  int *chunk;
  #pragma omp parallel
  {
    #pragma omp single
    omp_get_schedule(&sched, &chunk);
  }
  return sched;
}

int _get_chunk() {
  omp_sched_t *sched;
  int *chunk;
  #pragma omp parallel
  {
    #pragma omp single
    omp_get_schedule(&sched, &chunk);
  }
  return chunk;
}

int _omp_sched_t_to_int(char *schedule) {
  int ret = -1;
  #pragma omp parallel
  {
    #pragma omp single
      if (strcmp(schedule,"static")) {
        ret = omp_sched_static;
      }
      else if (strcmp(schedule,"dynamic")) {
        ret = omp_sched_dynamic;
      }
      else if (strcmp(schedule,"guided")) {
        ret = omp_sched_guided;
      }
      else if (strcmp(schedule,"auto")) {
        ret = omp_sched_auto;
      }
  }
  return ret;
}

__END__
