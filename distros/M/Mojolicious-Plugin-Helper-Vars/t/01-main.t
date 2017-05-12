use strict;
use warnings;
use utf8;

use Test::More;
 
use_ok('Test::Mojo');

my $t = Test::Mojo->new(MyApp->new());
 
$t->get_ok('/stash1/stash2?bar=param1&bar=param2')->status_is(200)
  ->content_like(qr'stash2')
  ->content_like(qr'param2')
  ->content_like(qr'param1')
  ->content_unlike(qr'stash1')
  ;

done_testing();

package MyApp;

use Mojo::Base 'Mojolicious';

sub startup {# 
  my $app = shift;
  $app->plugin('Helper::Vars', helper=>'myvars');
  $app->routes->any('/:bar/:bar'=>sub{my $c = shift; $c->render(format=>'txt', text=>$c->dumper([$c->myvars('bar')]))});
}
