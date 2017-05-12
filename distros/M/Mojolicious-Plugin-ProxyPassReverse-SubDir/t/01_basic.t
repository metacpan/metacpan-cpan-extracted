use strict;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'ProxyPassReverse::SubDir';

under '/' => sub {
  my $c = shift;
  my $url = $c->req->url;
  $c->render( json => { base => $c->url_for('/'), req => "$url" } );
};

get '/' => sub { shift->rendered(200) };
get '*' => sub { shift->rendered(200) };

my $prefix = '/subdir';

my $t = Test::Mojo->new;
$t->get_ok($prefix)
    ->status_is(200)
    ->json_is('/base' => '/')
    ->json_is('/req'  => $prefix);

$t->get_ok($prefix => { 'X-Forwarded-Host' => 'On' })
    ->status_is(200)
    ->json_is('/base' => $prefix)
    ->json_is('/req'  => '/');

done_testing();
