BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }
use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::Mojo;
use Test::More;

plan skip_all => 'http://www.cpantesters.org/cpan/report/001a7fac-85d7-11e7-a074-e1beba07c9dd' unless $ENV{TEST_FH};
plan skip_all => 'uptime is missing' unless grep { -x "$_/uptime" } split /:/, $ENV{PATH};

my $expected_pty_objects = 0;
use IO::Pty;
sub IO::Pty::DESTROY { $expected_pty_objects-- }

use Mojolicious::Lite;

get '/' => sub {
  my $c    = shift->render_later;
  my $fork = Mojo::IOLoop::ReadWriteFork->new(conduit => {type => 'pty'});
  my $out  = '';

  $c->stash(fork => $fork);

  $fork->on(
    close => sub {
      my ($fork, $exit_value, $signal) = @_;
      $c->render(json => {output => $out, exit_value => $exit_value});
      delete $c->stash->{fork};    # <--- prevent leaks
    }
  );

  $fork->on(
    read => sub {
      my ($fork, $buffer) = @_;
      $out .= $buffer;
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

done_testing;

sub count_fh {
  use Scalar::Util 'openhandle';
  return int grep {
    open my $fh, '<&=', $_;
    openhandle($fh);
  } 0 .. 1023;
}
