use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
plan tests => 5;

my $config = plugin 'ConfigHashMerge' => {
  default => {watch_dirs => {downloads => '/a/b/c/downloads'}},
  file    => 'my_app.conf'
};


get '/' => sub {
  my $self = shift;
  my $dirs = $self->config('watch_dirs');
  $self->render(json => $dirs);
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)
  ->json_is('/downloads', '/a/b/c/downloads',
  'ConfigHashMerge does not overwrite defaults')
  ->json_is('/music',  '/foo/bar/baz/music')
  ->json_is('/ebooks', '/foo/bar/baz/ebooks');

