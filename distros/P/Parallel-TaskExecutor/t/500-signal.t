use strict;
use warnings;
use utf8;

use Parallel::TaskExecutor;
use Test2::IPC;
use Test2::V0;

sub new {
  return Parallel::TaskExecutor->new(@_);
}

{
  my $t = new()->run(sub {
    sleep 1 while 1;
  }, catch_error => 1);
  $t->kill();
  ok(!$t->wait());
}

{
  my $t = new()->run(sub {
    sleep 1 while 1;
  }, catch_error => 1,
  SIG => {HUP => sub { exit 0 }});
  $t->signal('HUP');
  ok($t->wait());
  is($t->data(), undef);
}

{
  my $e = new();
  # One non-zombie task and one zombie one.
  my $t = $e->run(sub {
    sleep 1 while 1;
  }, catch_error => 1);
  $e->run(sub {
    sleep 1 while 1;
  }, catch_error => 1);
  $e->kill_all();
  $t->wait();
  pass();
}

done_testing;
