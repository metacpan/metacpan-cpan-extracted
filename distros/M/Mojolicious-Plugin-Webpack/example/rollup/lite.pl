#!/usr/bin/env perl
use Mojolicious::Lite;
use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/../../lib" }

plugin Webpack => {engine => 'Mojo::Alien::rollup', process => [qw(svelte css js)]};
get '/'        => 'index';
app->start;

__DATA__
@@ index.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title>Mojolicious ♥ Webpack</title>
    %= asset 'rollup-example.css'
  </head>
  <body>
    <h1>Mojolicious ♥ Rollup</h1>
    <p>
      This is a demo for using <a href="https://rollupjs.org/">Rollup</a>
      together with <a href="https://mojolicious.org/">Mojolicious</a>.
    </p>

    <pre># Create a rollup config file
# See https://github.com/jhthorsen/mojolicious-plugin-webpack/tree/master/example/rollup
# for example config file.
$ $EDITOR rollup.config.js

# Replace default webpack with rollup instead by loading a config file containing "rollup".
$ perl lite.pl webpack -c ./rollup.config.js</pre>

    <h2>The generated application</h2>
    %= asset 'rollup-example.js'
  </body>
</html>
