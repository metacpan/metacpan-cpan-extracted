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
  my $c   = shift->render_later;
  my $rwf = Mojo::IOLoop::ReadWriteFork->new;

  my $output = '';
  $rwf->on(read => sub { $output .= $_[1] });
  $rwf->on(
    finish => sub {
      my ($rwf, $exit_value, $signal) = @_;
      push @pids, $rwf->pid;
      $c->render(json => {output => $output, exit_value => $exit_value});
    }
  );

  $rwf->run('uptime');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->json_has('/exit_value') for 1 .. 5;
ok !kill(0, $_), "dead child $_" for @pids;

done_testing;
