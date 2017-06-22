use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'Text::Caml';

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

get '/inline' => sub {
  my $c = shift;
  $c->render(
      handler => 'caml',
      inline  => 'Hello, {{message}}!',
      message => 'Mustache',
  );
};

get '/data' => sub {
  my $c = shift;
  $c->render(
      handler => 'caml',
      message => 'Mustache',
  );
};

get '/file' => sub {
  my $c = shift;
  $c->render(
      'mustache',
      handler => 'caml',
      message => 'Mustache',
  );
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');
$t->get_ok('/inline')->status_is(200)->content_is('Hello, Mustache!');
$t->get_ok('/data')->status_is(200)->content_is('Hello, Mustache!');

done_testing();

__DATA__

@@ data.html.caml
Hello, {{message}}!