use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

{
  my $plugin = plugin 'Humane' => auto => 0;
  ok( -e $plugin->static_path, 'static_path exists' );

  my $theme = $plugin->theme;
  my $found = grep { $_ eq $theme } $plugin->all_themes;
  ok $found, "Found default theme ($theme)";
}

get '/' => sub {
  my $self = shift;
  $self->render('simple');
};

get '/stash' => sub {
  my $self = shift;
  $self->humane_stash( 'World' );
  $self->render('simple');
};

get '/flash' => sub {
  my $self = shift;
  $self->humane_flash( 'Hello' );
  $self->redirect_to('/');
};

my $t = Test::Mojo->new;
$t->ua->max_redirects(2);

$t->get_ok('/')
  ->status_is(200)
  ->element_exists('script')
  ->element_exists('link');

$t->get_ok('/flash')
  ->status_is(200)
  ->element_exists('script')
  ->element_exists('link')
  ->content_like(qr[ humane\.log \( \s* "Hello" \s* \) ]x);

$t->get_ok('/stash')
  ->status_is(200)
  ->element_exists('script')
  ->element_exists('link')
  ->content_like(qr[ humane\.log \( \s* "World" \s* \) ]x);

done_testing;

__DATA__

@@ simple.html.ep
<!DOCTYPE html>
<html>
  <head>
    %= humane_include
  </head>
  <body>
    Testing humane.js plugin for Mojolicious
  </body>
</html>

