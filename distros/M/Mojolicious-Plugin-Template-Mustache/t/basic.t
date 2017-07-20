use Mojo::Base -strict;

use lib('lib');

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'Template::Mustache';

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

get '/inline' => sub {
  my $c = shift;
  $c->render(
      handler => 'mustache',
      inline  => 'Inline hello, {{message}}!',
      message => 'Mustache',
  );
};

get '/data' => sub {
  my $c = shift;
  $c->render(
      handler => 'mustache',
      message => 'Mustache',
  );
};

get '/file' => sub {
  my $c = shift;
  $c->render(
      'test',
      handler => 'mustache',
      message => 'Mustache',
  );
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');
$t->get_ok('/inline')->status_is(200)->content_is('Inline hello, Mustache!');
$t->get_ok('/data')->status_is(200)->content_is('Hello from data, Mustache!');
$t->get_ok('/file')->status_is(200)->content_is('Hello from template, Mustache!');

done_testing();

__DATA__

@@ data.html.mustache
Hello from data, {{message}}!