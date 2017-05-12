use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'RenderSteps';

get(
  '/' => sub {
    my $self = shift;
    $self->render_steps(
      sub {
        shift->pass;
      },
      sub {
        my $delay = shift;
        $self->stash(set => 1);
      }
    );
  }
)->name('index');
get '/error' => sub {
  my $self = shift;
  $self->render_steps(
    sub {
      shift->pass;
    },
    sub { die "failure is not an option"; }
  );
};


my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is("Hello Mojo!\n");
$t->get_ok('/error')->status_is(500)->content_like(qr/option/);


done_testing();

__DATA__
@@  index.html.ep
Hello Mojo!
