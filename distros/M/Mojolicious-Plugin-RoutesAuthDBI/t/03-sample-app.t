use Mojo::Base 'Mojolicious';
use Test::More;
use Test::Mojo;

sub startup {
  shift->routes->route('/app')
    ->to('install#sampl_app', namespace=>'Mojolicious::Plugin::RoutesAuthDBI');
}

my $t = Test::Mojo->new(__PACKAGE__);

$t->get_ok('/app')
  ->status_is(200)
  ->content_like(qr/__PACKAGE__->new->start/i)
  ;

#~ warn $t->tx->res->text;

done_testing();