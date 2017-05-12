package MyApp;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;

  $self->plugin('ErrorsAndWarnings');

  # Router
  my $r = $self->routes;
  $r->get('/')->to(cb => sub {
    my $c = shift;
    $c->add_error('first_error');
    $c->add_error('second_error', more => 'detail');

    # {"errors":[{"code":"first_error"},{"code":"second_error","more":"detail"}]}
    $c->render(json => { errors => $c->errors });
  });
}

1;

package main;
use Mojo::Base -strict;

use Test::Mojo;
use Test::More;

my $t = Test::Mojo->new('MyApp');

$t->get_ok('/.json')->status_is(200)
  ->json_is('/errors/0/code' => 'first_error')
  ->json_is('/errors/1/code' => 'second_error')
  ->json_is('/errors/1/more' => 'detail');

done_testing();
