BEGIN {
  use Time::HiRes;
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::EV';
  *Minion::Command::minion::worker::sleep = sub { Time::HiRes::usleep(10e3) };
}
use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use File::Spec::Functions 'catfile';
use File::Temp 'tempdir';
use Test::Mojo;
use Test::More;
use version;

plan skip_all => 'Minion::Backend::SQLite >=4.001 need to be installed to run this test'
  unless eval
  'require Minion::Backend::SQLite; version->parse(Minion::Backend::SQLite->VERSION) >= version->parse(4.001)';
plan skip_all => 'EV need to be installed to run this test'
  unless eval { Mojo::IOLoop->singleton->reactor->isa('Mojo::Reactor::EV') };

my $tmpdir = tempdir CLEANUP => 1;
my $file   = catfile $tmpdir, 'minion.db';
my $pid    = $$;

use Mojolicious::Lite;
plugin Minion => {SQLite => "sqlite:$file"};
app->minion->add_task(
  rwf => sub {
    my $job       = shift;
    my $fork      = Mojo::IOLoop::ReadWriteFork->new;
    my $exit_code = 0;

    $fork->on(finish => sub { $exit_code = $_[1]; Mojo::IOLoop->stop; });
    $fork->run(sub { print "I am $$.\n"; $! = 42; });
    Mojo::IOLoop->start;
    $job->finish($exit_code);
  }
);

# Make $worker->run() return after job is done
app->minion->on(
  worker => sub {
    pop->on(
      dequeue => sub {
        pop->on(
          finished => sub {
            diag 'Job finished';
            kill TERM => $pid;
          }
        );
      }
    );
  }
);

require Minion::Command::minion::worker;
my $worker = Minion::Command::minion::worker->new(app => app);
my $id     = $worker->app->minion->enqueue('rwf');
my $job    = $worker->app->minion->job($id) || {};

ok $job, 'got rwf job';
is $job->info->{state}, 'inactive', 'inactive job';

$worker->run;
is $job->info->{state},  'finished', 'finished job';
is $job->info->{result}, 42,         'exit_code from child';

done_testing;
