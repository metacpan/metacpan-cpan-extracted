use strict;
use warnings;

use Test::More;
use Test::Mojo;

use Mojolicious::Lite;

get '/' => sub { shift->render( template => 'test', 'mojox.no-minify' => 1 ) };

my $t = Test::Mojo->new;

plugin 'Text::Minify';

$t->get_ok('/')
  ->content_like( qr/\n\s+/ );

done_testing;

__DATA__

@@test.html.ep

<html>

  <head>
    <title>Test</title>
  </head>

  <body>

   <h1>Test</h1>

   <p>
     This is a sample test document,
     with a lot of whitespace.
   </p>

  </body>
</html>
