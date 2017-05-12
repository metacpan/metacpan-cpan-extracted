use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Test::More tests => 7;

plugin 'proxy';

get '/foo' => sub { shift->render(text => 'bar'); } => 'foo';
get '/bar' => sub { my $self=shift;$self->proxy_to($self->url_for('foo')->to_abs) };
get '/baz' => sub { die "ARGH" } => 'baz';
get '/fob' => sub { my $self=shift;$self->proxy_to($self->url_for('baz')->to_abs) };

my $t=Test::Mojo->new;

$t->get_ok('/bar')->status_is(200)->content_like(qr/bar/);
$t->get_ok('/fob')
  ->status_is(500)
  ->content_is(qq/Failed to fetch data from backend/)
  ->header_is('X-Remote-Status','500: Internal Server Error');
