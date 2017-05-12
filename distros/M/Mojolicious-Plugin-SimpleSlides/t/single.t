use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

plugin 'SimpleSlides';

my $t = Test::Mojo->new;

$t->get_ok('/1')
  ->status_is(200)
  ->text_like( '#main' => qr/Hello World/ )
  ->text_is( title => 'Title test' )
  ->text_is( h1 => 'Title test' );

my $dom = $t->tx->res->dom;
my @nav = $dom->find('.nav a')->map(sub{$_->{href}})->each;
is $nav[0], '/', 'prev is /';
is $nav[1], '/', 'next is /';

$t->get_ok('/0')
  ->status_is(404);

$t->get_ok('/2')
  ->status_is(404);

done_testing;

__DATA__

@@ 1.html.ep

% title 'Title test';

Hello World
