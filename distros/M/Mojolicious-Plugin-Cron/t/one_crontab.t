BEGIN {
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}
use Test::Mock::Time;
use Test2::V0;
use Test::Mojo;
use Algorithm::Cron;
use Mojolicious::Lite;

$ENV{MOJO_MODE} = 'test';
my %local_tstamps;

plugin Cron => (
  '*/10 15 * * *' => sub {
    $local_tstamps{fmt_time(localtime)}++;
    Mojo::IOLoop->stop;
  }
);

get '/' => {text => 'Hello, world'};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200);

# goto the future, next 15 hs local time (today or tomorrow)
ff(Algorithm::Cron->new(base => 'local', crontab => '0 15 * * *')
    ->next_time(time) - time);
undef %local_tstamps;
my @local_at13pm = localtime;
my $lday = substr fmt_time(@local_at13pm), 0, 10;
ff(3630);    # 1 h 30 secs from 3PM, local time
is \%local_tstamps,
  {
  "$lday 15:10" => 1,
  "$lday 15:20" => 1,
  "$lday 15:30" => 1,
  "$lday 15:40" => 1,
  "$lday 15:50" => 1,
  },         # no more because hour is always 15 local
  'exact tstamps';
done_testing;

sub fmt_time {
  my @lt = reverse(@_[1 .. 5]);    # no seconds on tests
  $lt[0] += 1900;
  $lt[1]++;
  return sprintf("%04d-%02d-%02d %02d:%02d", @lt);
}
