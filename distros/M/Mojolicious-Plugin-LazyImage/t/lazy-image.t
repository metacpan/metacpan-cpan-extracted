use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

use Mojolicious::Lite;
plugin 'LazyImage';
get '/' => 'index';

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)->text_like('script', qr{initLazyImages})
  ->element_exists('noscript.js-lazy-image')
  ->element_exists('noscript.js-lazy-image img[src^="data:image/png;base64,"]');

$t->get_ok('/js/lazy-image.js')->status_is(200)
  ->content_is(Mojolicious::Plugin::LazyImage->javascript);

done_testing;

$t->app->start if $ENV{DEMO};

__DATA__
@@ index.html.ep
<html>
  <head>
    <title>Lazy load images</title>
    <style>
      body { margin: 3rem; padding: 0; }
      .box { padding: 100px 0; }
      .lazy-image { opacity: 1; transition: opacity 0.3s; }
      .lazy-image[data-src] { opacity: 0; }
    </style>
  </head>
  <body>
    <h1>Lazy image demo</h1>
    % for (0 .. 10) {
      <div class="box">
        %= lazy_image 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACgAAAAoCAYAAACM/rhtAAAAOElEQVR42u3OQREAAAQAMFLpH4cUUrjz2BIsu2risRQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFLyx2BVaUfkYZXUAAAAASUVORK5CYII='
      </div>
    % }
    <script>
      %== Mojolicious::Plugin::LazyImage->javascript;
      initLazyImages.DEBUG = true;
    </script>
  </body>
</html>
