use v5.26;
use warnings;

use Test::Mock::Time;
use Test2::V0;
use Test::Mojo;
use Mojolicious::Lite;
use File::Path qw(rmtree);
use File::Spec;

# clear job locks so tests can be re-run statelessly
rmtree($_) foreach (glob(File::Spec->tmpdir . "/mojo_cron_*"));

push(@INC, "t/lib");

plugin 'Cron::Scheduler' => {
  namespaces => [qw(Cron::Test)],
  schedules  => {
    job1 => [
      {
        schedule => {
          hour   => 12,
          minute => 6,
        }
      }
    ]
  },
};

get '/' => {text => 'Hello, world'};
my $t = Test::Mojo->new;
# needed to kickstart event loop, for some reason
$t->get_ok('/')->status_is(200);

is(warning {ff(24 * 60 * 60)}, "Job1 was run\n", 'test namespace task implementation');

done_testing;
