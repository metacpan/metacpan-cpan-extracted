use Mojo::Base 'Mojolicious';
use Test::More;
use Test::Mojo;

sub startup {
  shift->routes->route('/man')
    ->to('install#manual', namespace=>'Mojolicious::Plugin::RoutesAuthDBI');
}

my $t = Test::Mojo->new(__PACKAGE__);

$t->get_ok('/man')->status_is(200)
  ->content_like(qr/system ready!/);

done_testing();