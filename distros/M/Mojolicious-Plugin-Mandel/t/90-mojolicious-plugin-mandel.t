use Modern::Perl;
use Test::More;
use Test::Mojo;

use Mojolicious::Lite;
use lib "t/lib";

plugin 'Mandel' => { mine => { "MyMandel" => "mongodb://localhost/test" } };

any '/' => sub {
  my $c = shift;
  my @docs = $c->mandel_documents;
  $c->render(json => { documents => \@docs });
};

any '/:mandel' => sub {
  my $c = shift;
  my $m = $c->param("mandel");
  my $o = $c->mandel($m);
  $c->render(json => { mandel => $m});
};
my $t = Test::Mojo->new;

$t->get_ok("/")->status_is(200)->json_has("/documents")->json_is({documents => ['mine.my_document']});
$t->get_ok("/my_document")->status_is(200);
$t->get_ok("/other")->status_is(500);

done_testing;

