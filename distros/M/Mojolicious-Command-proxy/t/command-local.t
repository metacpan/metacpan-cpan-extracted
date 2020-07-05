use Mojolicious::Command::proxy;
use Mojolicious::Lite;
use Test::Mojo;
use Test::More;

get '/subdir/:id' => sub {
  my ($c) = @_;
  $c->render(text => 'ID: '. $c->stash('id'). ' x='. ($c->param('x')||''));
};

my $t = Test::Mojo->new;

Mojolicious::Command::proxy->proxy(app, '/proxy', '/subdir');
Mojolicious::Command::proxy->proxy(app, '', '/subdir'); # more specific first

$t->get_ok('/proxy/2')->content_like(qr/ID: 2/);
$t->get_ok('/2')->content_like(qr/ID: 2/);
$t->get_ok('/2?x=hello')->content_like(qr/x=hello/);
$t->get_ok('/%253A')->content_like(qr/ID: %3A/);

done_testing;
