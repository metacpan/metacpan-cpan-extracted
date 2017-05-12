use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

{
  my $plugin = plugin 'Humane';
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

get '/both' => sub {
  my $self = shift;
  $self->humane_flash( 'Hello' );
  $self->redirect_to('/stash');
};

my $t = Test::Mojo->new;
$t->ua->max_redirects(2);

$t->get_ok('/')
  ->status_is(200)
  ->element_exists_not('script')
  ->element_exists_not('link');

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

$t->get_ok('/both')
  ->status_is(200)
  ->element_exists('script')
  ->element_exists('link')
  ->content_like(qr[ humane\.log \( \s* "Hello" \s* \) .*? humane\.log \( \s* "World" \s* \) ]sx);

done_testing;

__DATA__

@@ simple.html.ep
<!DOCTYPE html>
<html>
  <head></head>
  <body>
    Testing humane.js plugin for Mojolicious
  </body>
</html>

