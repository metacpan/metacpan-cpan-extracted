use Mojo::Base -strict;

use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'HTMLTemplateRenderer';

get '/' => sub {
  my $self = shift;
  $self->render(text => 'Hello Mojo!');
};

get '/ht_test_1' => sub {
  my $self = shift;
  $self->stash(message1 => 'HTML::Template Test 1');
  $self->render(handler => 'tmpl');
};

get '/ht_test_2' => sub {
  my $self = shift;
  $self->stash(message2 => 'HTML::Template Test 2');
  $self->render(inline => '<p><TMPL_VAR NAME="MESSAGE2"></p>', handler => 'tmpl');
};

get '/ht_test_3' => sub {
  my $self = shift;
  $self->stash(loop3 => [{ M => 'A' }, { M => 'B' }, { M => 'C' }]);
  $self->render(handler => 'tmpl');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');
$t->get_ok('/ht_test_1')->status_is(200)->content_like(qr/HTML::Template Test 1/);
$t->get_ok('/ht_test_2')->status_is(200)->content_like(qr/HTML::Template Test 2/);
$t->get_ok('/ht_test_3')->status_is(200)->content_like(qr/<li>A<\/li>/);

done_testing();
