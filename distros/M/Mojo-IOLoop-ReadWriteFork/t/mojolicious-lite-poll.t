BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }
use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::Mojo;
use Test::More;

plan skip_all => 'TEST_FH=1 # http://www.cpantesters.org/cpan/report/001a7fac-85d7-11e7-a074-e1beba07c9dd'
  unless $ENV{TEST_FH};
plan skip_all => 'uptime is missing' unless grep { -x "$_/uptime" } split /:/, $ENV{PATH};

my ($expected_pty_objects, @pids) = (0);
use IO::Pty;
sub IO::Pty::DESTROY { $expected_pty_objects-- }

use Mojolicious::Lite;

get '/' => sub {
  my $c    = shift->render_later;
  my $fork = Mojo::IOLoop::ReadWriteFork->new(conduit => {type => 'pty'});

  my $output = '';
  $fork->on(read => sub { $output .= $_[1] });
  $fork->on(
    finish => sub {
      my ($fork, $exit_value, $signal) = @_;
      push @pids, $fork->pid;
      $c->render(json => {output => $output, exit_value => $exit_value});
    }
  );

  $fork->run('uptime');
};

my $t = Test::Mojo->new;

$expected_pty_objects++;
$t->get_ok('/')->status_is(200);
my $before = count_fh();

$expected_pty_objects++;
$t->get_ok('/')->status_is(200);
is count_fh(), $before, 'second run';

$expected_pty_objects++;
$t->get_ok('/')->status_is(200);
is count_fh(), $before, 'third run';

is $expected_pty_objects, 0, 'all pty objects has been destroyed';
ok !kill(0, $_), "dead child $_" for @pids;

done_testing;

sub count_fh {
  use Scalar::Util 'openhandle';
  return int grep {
    open my $fh, '<&=', $_;
    openhandle($fh);
  } 0 .. 1023;
}
