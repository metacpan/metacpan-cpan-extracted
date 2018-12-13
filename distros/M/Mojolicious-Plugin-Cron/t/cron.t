BEGIN {
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}
use Test::Mock::Time;
use Test2::V0;
use Test::Mojo;
use Algorithm::Cron;
use Mojolicious::Lite;

$ENV{MOJO_MODE} = 'test';
my %global_tstamps;

plugin Cron => (
  sched1 => {
    base    => 'utc',
    crontab => '*/10 15 * * *',
    code    => sub {
      $global_tstamps{fmt_time(gmtime)}{sched1}++;
      Mojo::IOLoop->stop;
    }
  },
  sched2 => {
    base    => 'utc',
    crontab => '*/15 15 * * *',
    code    => sub {
      $global_tstamps{fmt_time(gmtime)}{sched2}++;
      Mojo::IOLoop->stop;
    }
  },

# next 2 cron lines to simultate same line (sched3) in two different
# pids. Like in prefork or hypnotoad servers
  sched3 => {
    base    => 'utc',
    crontab => '58,59 15 * * *',    # 58 will allow to unlock the crontab once
    code    => sub {
      $global_tstamps{fmt_time(gmtime)}{sched3}++;
      Mojo::IOLoop->stop;
    },
  },

  # following cron line is the same, with __test_key field to simulate
  # two siumultaneous processes
  # only one of sched3_pid1 / sched3_pid2 should be in stamps
  sched3_other_pid => {
    base    => 'utc',
    crontab => '59 15 * * *',
    code    => sub {
      $global_tstamps{fmt_time(gmtime)}{sched3}++;
      Mojo::IOLoop->stop;
    },
    __test_key => 'sched3',
  },

# next 2 cron lines also simultate same line (sched4) in two different
# pids. Like in prefork or hypnotoad servers
  sched4 => {
    base    => 'utc',
    crontab => '59 15 * * *',
    code    => sub {
      $global_tstamps{fmt_time(gmtime)}{sched4}++;
      Mojo::IOLoop->stop;
    },
    all_proc => 1,
  },

  # following cron line is the same, with __test_key field to simulate
  # two siumultaneous processes
  # both sched4_pid1 / sched4_pid2 should be in stamps, due to
  # all_proc flag
  sched4_other_pid => {
    base    => 'utc',
    crontab => '59 15 * * *',
    code    => sub {
      $global_tstamps{fmt_time(gmtime)}{sched4}++;
      Mojo::IOLoop->stop;
    },
    all_proc   => 1,
    __test_key => 'sched4',
  },
);

get '/' => {text => 'Hello, world'};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200);

ff(Algorithm::Cron->new(base => 'utc', crontab => '0 15 * * *')->next_time(time)
    - time);

undef %global_tstamps;
my @utc_at13pm = gmtime;
my $gday = substr fmt_time(@utc_at13pm), 0, 10;

ff(3610);    # 1 h 30 secs from 3PM

is \%global_tstamps, {
  "$gday 15:10" => {sched1 => 1},
  "$gday 15:15" => {sched2 => 1},
  "$gday 15:20" => {sched1 => 1},
  "$gday 15:30" => {sched1 => 1, sched2 => 1},    # same time ok
  "$gday 15:40" => {sched1 => 1},
  "$gday 15:45" => {sched2 => 1},
  "$gday 15:50" => {sched1 => 1},
  "$gday 15:58" => {sched3 => 1},
  "$gday 15:59" => {
    sched3 => 1,                                  # means locking works
    sched4 => 2                                   # means all_proc flag works
  },    # no more because hour is always 15 utc
  },
  'exact tstamps';

done_testing;

sub fmt_time {
  my @lt = reverse(@_[1 .. 5]);    # no seconds on tests
  $lt[0] += 1900;
  $lt[1]++;
  return sprintf("%04d-%02d-%02d %02d:%02d", @lt);
}
