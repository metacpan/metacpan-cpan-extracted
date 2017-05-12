use Mojo::Base -strict;
 
use Test::More;
 
use Mojolicious::Lite;
use Test::Mojo;
 
plugin 'HandlebarsJSRenderer';
 
get '/' => sub {
  my $self = shift;
  $self->render(text => 'Hello Mojo!');
};
 
get '/hbs_test_1' => sub {
  my $self = shift;
  $self->stash(message1 => 'Handlebars Test 1');
  $self->render(handler => 'hbs');
};
 
get '/hbs_test_2' => sub {
  my $self = shift;
  $self->stash(message2 => 'Handlebars Test 2');
  $self->render(inline => 'inline {{message2}}', handler => 'hbs');
};
 
get '/hbs_test_3' => sub {
  my $self = shift;
  $self->stash(bool => 1);
  $self->render(handler => 'hbs');
};
 
my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');
$t->get_ok('/hbs_test_1')->status_is(200)->content_like(qr/data Handlebars Test 1/);
$t->get_ok('/hbs_test_2')->status_is(200)->content_like(qr/inline Handlebars Test 2/);
$t->get_ok('/hbs_test_3')->status_is(200)->content_like(qr/bool is true/);
 
done_testing();

