BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::EV' }
use Mojo::Base -strict;
use Mojo::IOLoop::ReadWriteFork;
use Test::Mojo;
use Test::More;

plan skip_all => 'EV need to be installed to run this test'
  unless eval { Mojo::IOLoop->singleton->reactor->isa('Mojo::Reactor::EV') };

use Mojolicious::Lite;
my @pids;

get '/' => sub {
  my $c    = shift->render_later;
  my $fork = Mojo::IOLoop::ReadWriteFork->new;
  my $out  = '';

  $c->stash(fork => $fork);

  $fork->on(
    close => sub {
      my ($fork, $exit_value, $signal) = @_;
      push @pids, $fork->pid;
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

for (1 .. 5) {
  $t->get_ok('/')->status_is(200)->json_has('/exit_value');
}

ok !kill(0, $_), "dead child $_" for @pids;

done_testing;
