use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Mojolicious::Lite;
use Mojo::File 'path';
use lib;

my $site = path(__FILE__)->sibling('site')->to_string;
lib->import($site);
push @{ app->renderer->paths }, $site;

plugin 'AutoRoutePm',
  {
    route   => [ app->routes ],
    top_dir => 'site',
  };

my $t = Test::Mojo->new;

$t->get_ok('/welcome/subfolder/index')->status_is(200)
  ->content_is( "This is a subfolder page\n", 'A subfolder page' );

done_testing();
